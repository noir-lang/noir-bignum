use crate::utils::split_bits;

use crate::constants::{TWO_POW_120, TWO_POW_126, TWO_POW_246};

use crate::fns::constrained_ops::{validate_in_range, validate_quotient_in_range};
use crate::fns::unconstrained_helpers::__barrett_reduction;
use crate::fns::unconstrained_ops::__is_zero;

use crate::params::BigNumParams;

// ------------------------------ UNCONSTRAINED EXPRESSIONS ------------------------------

/// Compute the result of a linear combination of (possibly negative) `BigNum` values (unconstrained)
///
/// ## Note
/// `modulus2` is structured such that all limbs will be greater than `0`, even when subtracting.
/// To do this, when computing `p - x`, we ensure that each limb in `p` is greater than each limb in `x`.
/// We know that, for a valid bignum element, the limbs in `x` will be < 2^{120}
/// Therefore each of the limbs in `p` (except the most significant) will borrow 2^{120} from the more significant limb.
/// Finally, to ensure we do not underflow in the most significant limb, we use `2p` instead of `p`
///
/// Returns the `Field` values that are not normalized to be 120-bit
unconstrained fn __add_linear_expression<let N: u32, let MOD_BITS: u32, let M: u32>(
    params: BigNumParams<N, MOD_BITS>,
    vals: [[u128; N]; M],
    flags: [bool; M],
) -> ([Field; N]) {
    let mut sum: [Field; N] = [0; N];
    let modulus2: [u128; N] = params.double_modulus;
    for i in 0..M {
        if (flags[i]) {
            for j in 0..N {
                sum[j] = sum[j] + (modulus2[j] as Field) - (vals[i][j] as Field);
            }
        } else {
            for j in 0..N {
                sum[j] = sum[j] + (vals[i][j] as Field);
            }
        }
    }
    sum
}

/// Compute the limb products of a quadratic expression (unconstrained)
///
/// See `__compute_quadratic_expression_with_borrow_flags` for full description
///
/// ## Note
/// Returns the `Field` values that are not normalized to be 120-bit
unconstrained fn __compute_quadratic_expression_product<let N: u32, let MOD_BITS: u32, let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs_terms: [[[u128; N]; LHS_N]; NUM_PRODUCTS],
    lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
    rhs_terms: [[[u128; N]; RHS_N]; NUM_PRODUCTS],
    rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
    linear_terms: [[u128; N]; ADD_N],
    linear_flags: [bool; ADD_N],
) -> [Field; 2 * N] {
    let mut lhs: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
    let mut rhs: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];

    for i in 0..NUM_PRODUCTS {
        lhs[i] = __add_linear_expression(params, lhs_terms[i], lhs_flags[i]);
        rhs[i] = __add_linear_expression(params, rhs_terms[i], rhs_flags[i]);
    }
    let add: [Field; N] = __add_linear_expression(params, linear_terms, linear_flags);

    let mut mulout: [Field; 2 * N] = [0; 2 * N];
    for i in 0..N {
        for j in 0..N {
            for k in 0..NUM_PRODUCTS {
                mulout[i + j] += lhs[k][i] * rhs[k][j];
            }
        }
        mulout[i] += add[i];
    }
    mulout
}

/// Given a degree-2 `BigNum` expression that is equal to `0` mod p, compute the quotient and the borrow flags (unconstrained)
///
/// The expression is of the form:
///     \sum_{i=0}^{NUM_PRODUCTS - 1} ((\sum_{j=0}^{LHS_N-1}lhs[i][j]) * (\sum_{j=0}^{RHS_N-1}rhs[i][j]))
///     + \sum_{i=0}^{ADD_N - 1}linear_terms[i]
///     = quotient * modulus
///
/// The intent is to capture an arbitrary degree-2 `BigNum` relation within the limitations of Noir
/// (no efficient dynamically-sized vectors)
///
/// When performing `BigNum` arithmetic, we want to represent desired `BigNum` operations in a way that minimizes
/// the number of modular reductions that are required. This can be achieved by minimizing the number of degree-2
/// relations required.
///
/// The borrow flags describe whether individual `Field` limbs will underflow when evaluating the above relation.
/// For example, when constraining
///      a * b - q * p = 0
///
/// it is possible that:
///      1. a[0]*b[0] - p[0]*q[0] = -2^{120}
///      2. a[0]*b[1] + a[1]*b[0] - p[0]*q[1] - p[1]*q[0] = 1
///
/// In this example, the two 120-bit limbs together still represent zero, despite each limb being nonzero.
/// To constrain this correctly, we conceptually "borrow" (at least) 2^{120} from the next limb:
/// add 2^{120} to the first limb and subtract 1 from the second
///
/// In the circuit, we do not literally add 2^{120}. Instead, we encode borrows using a larger constant 2^{246}.
/// This keeps all intermediate values non-negative in the field and, after scaling by 2^{-120}, produces a clean
/// 2^{126} contribution into the next limb. The extra 6 limbs reflect the maximum allowed overflow per limb.
/// See `evaluate_quadratic_expression` and `validate_quotient_in_range` for details
///
/// Basically what we are doing is the following:
///     1. compute `mulout_p` as
///          \sum_{i=0}^{NUM_PRODUCTS - 1} ((\sum_{j=0}^{LHS_N-1}lhs[i][j]) * (\sum_{j=0}^{RHS_N-1}rhs[i][j]))
///          + \sum_{i=0}^{ADD_N - 1}linear_terms[i]
///        It is not normalized so each limb may exceed 120 bits
///     2. Normalize `mulout_p` into 2N 120-bit limbs and compute
///             quotient = floor(mulout_p / modulus) using Barrett reduction
///             also compute the remainder and validate that it is zero
///     3. Reconstruct `mulout_n = quotient * modulus` as a limb array
///     4. Compute the limb-by-limb difference `mulout_p - mulout_n`, using borrow flags to
///        model true integer borrows while keeping each intermediate difference within a
///        126-bit bound (needed for the borrow simulation to remain well-defined).
unconstrained fn __compute_quadratic_expression_with_borrow_flags<let N: u32, let MOD_BITS: u32, let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs_terms: [[[u128; N]; LHS_N]; NUM_PRODUCTS],
    lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
    rhs_terms: [[[u128; N]; RHS_N]; NUM_PRODUCTS],
    rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
    linear_terms: [[u128; N]; ADD_N],
    linear_flags: [bool; ADD_N],
) -> ([u128; N], [bool; 2 * N - 2]) {
    let mut mulout_p: [Field; 2 * N] = __compute_quadratic_expression_product(
        params,
        lhs_terms,
        lhs_flags,
        rhs_terms,
        rhs_flags,
        linear_terms,
        linear_flags,
    );

    // `__normalize_limbs` will validate that we do not overflow 2N, normally we should not overflow 2N-1
    let mut relation_result: [u128; 2 * N] = split_bits::__normalize_limbs(mulout_p);
    let (quotient, remainder): ([u128; N], [u128; N]) =
        __barrett_reduction(relation_result, params.redc_param, MOD_BITS, params.modulus);

    // This is verified later by the range checks but left for debugging purposes
    assert(__is_zero(remainder));

    // We do not normalize `mulout_n` so we won't fill the `2 * N - 1`
    let mut mulout_n: [Field; 2 * N - 1] = [0; 2 * N - 1];
    for i in 0..N {
        for j in 0..N {
            mulout_n[i + j] += (quotient[i] as Field) * (params.modulus[j] as Field);
        }
    }

    // compute borrow flags from mulout_p and mulout_n
    let mut borrow_flags: [bool; 2 * N - 2] = [false; 2 * N - 2];
    let borrow_shift: Field = TWO_POW_246; // 2^{246}
    let borrow_carry: Field = TWO_POW_126; // 2^{126} = 2^{246 - 120}
    let downshift_120: Field = 1 / (TWO_POW_120 as Field);

    // determine whether we need to borrow from more significant limbs.
    // initial limb is "simple" comparison operation
    borrow_flags[0] = mulout_p[0].lt(mulout_n[0]);

    // we have 2N - 2 borrow flags. The number of limbs from our product computation is 2N - 1
    // and there is nothing to borrow against for the final limb.
    let mut hi_bits: Field =
        (mulout_p[0] - mulout_n[0] + ((borrow_flags[0] as Field) * borrow_shift)) * downshift_120;

    for i in 1..(N + N - 2) {
        // compute the contribution from limb `i-1` that gets added into limb `i`, and add into limb `i`
        mulout_p[i] += hi_bits;

        let subtrahend: Field = mulout_n[i] + (borrow_flags[i - 1] as Field) * borrow_carry;

        // determine whether negative limb values are greater than positive limb values
        borrow_flags[i] = mulout_p[i].lt(subtrahend);
        let minuend: Field = mulout_p[i] + (borrow_flags[i] as Field) * borrow_shift;

        hi_bits = (minuend - subtrahend) * downshift_120;
    }
    (quotient, borrow_flags)
}

/// Computes the quotient/remainder of a quadratic expression (unconstrained)
///
/// See `__compute_quadratic_expression_with_borrow_flags` for full description
pub(crate) unconstrained fn __compute_quadratic_expression<let N: u32, let MOD_BITS: u32, let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs_terms: [[[u128; N]; LHS_N]; NUM_PRODUCTS],
    lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
    rhs_terms: [[[u128; N]; RHS_N]; NUM_PRODUCTS],
    rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
    linear_terms: [[u128; N]; ADD_N],
    linear_flags: [bool; ADD_N],
) -> ([u128; N], [u128; N]) {
    let mulout: [Field; 2 * N] = __compute_quadratic_expression_product(
        params,
        lhs_terms,
        lhs_flags,
        rhs_terms,
        rhs_flags,
        linear_terms,
        linear_flags,
    );
    // __normalize_limbs will validate that we do not overflow 2N, normally we should not overflow 2N-1
    let mut relation_result: [u128; 2 * N] = split_bits::__normalize_limbs(mulout);

    let (quotient, remainder): ([u128; N], [u128; N]) =
        __barrett_reduction(relation_result, params.redc_param, MOD_BITS, params.modulus);

    (quotient, remainder)
}

// ------------------------------ CONSTRAINED EXPRESSIONS ------------------------------

/// Constrained version of `__add_linear_expression`
///
/// Computes all the linear parts of an expression in-circuit
///
/// ## Note
/// Negative terms are implemented by adding `double_modulus`
/// `double_modulus` is chosen so that all limbs except the top one
/// are > 2^{120}, which prevents underflows in intermediate computations.
///
/// For the most significant limb we slightly reduce the padding (to keep the
/// overall value equal to `2 * MOD`), so in principle there is a narrow edge
/// case where that limb could underflow if enough negative contributions are
/// accumulated and the top limb of `MOD` is very small. In practice, the
/// global `BigNum` range and operand-count assumptions in
/// `evaluate_quadratic_expression` rule out such patterns.
fn compute_linear_expressions<let N: u32, let MOD_BITS: u32, let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs_terms: [[[u128; N]; LHS_N]; NUM_PRODUCTS],
    lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
    rhs_terms: [[[u128; N]; RHS_N]; NUM_PRODUCTS],
    rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
    linear_terms: [[u128; N]; ADD_N],
    linear_flags: [bool; ADD_N],
) -> ([[Field; N]; NUM_PRODUCTS], [[Field; N]; NUM_PRODUCTS], [Field; N]) {
    // lhs linear terms
    let mut lhs_linear: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
    // rhs linear terms
    let mut rhs_linear: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
    // linear terms
    let mut lin_expr: [Field; N] = [0; N];

    for k in 0..NUM_PRODUCTS {
        for i in 0..N {
            for j in 0..LHS_N {
                // Note: if lhs_flags[k][j] - `is_negative` is not known at comptime this is very expensive
                if (lhs_flags[k][j]) {
                    lhs_linear[k][i] -= lhs_terms[k][j][i] as Field;
                    lhs_linear[k][i] += params.double_modulus[i] as Field;
                } else {
                    lhs_linear[k][i] += lhs_terms[k][j][i] as Field;
                }
            }
            for j in 0..RHS_N {
                // Note: if rhs_flags[k][j] - `is_negative` is not known at comptime this is very expensive
                if (rhs_flags[k][j]) {
                    rhs_linear[k][i] -= rhs_terms[k][j][i] as Field;
                    rhs_linear[k][i] += params.double_modulus[i] as Field;
                } else {
                    rhs_linear[k][i] += rhs_terms[k][j][i] as Field;
                }
            }
        }
    }

    for i in 0..N {
        for j in 0..ADD_N {
            // Note: if linear_flags[j] - `is_negative` is not known at comptime this is very expensive
            if (linear_flags[j]) {
                lin_expr[i] -= linear_terms[j][i] as Field;
                lin_expr[i] += params.double_modulus[i] as Field;
            } else {
                lin_expr[i] += linear_terms[j][i] as Field;
            }
        }
    }

    (lhs_linear, rhs_linear, lin_expr)
}

/// Constrained version of `__compute_quadratic_expression_product`
///
/// Computes the following expression in-circuit:
///     \sum (L_i * R_i) + \sum (A_i) - QUOTIENT * MOD
///
/// Because of the subtraction of `QUOTIENT * MODULUS`, the resulting limbs may
/// underflow and represent *negative* values. To account for this, we allow the
/// prover to choose a sequence of borrow flags and interpret the limbs with
/// additional terms:
///
///   - for each limb `i` we may add `2^{246}` (via a flag at position `i`);
///   - for each limb `i` we may subtract `2^{126 = 246 - 120}` (via the flag
///     at position `i - 1`).
///
/// This corresponds to borrowing `2^{126}` from limb `i + 1` and adding
/// `2^{246}` into limb `i`. After this adjustment, an honest prover can ensure
/// that every limb lies in `[0, 2^{246})` and that the adjusted limbs encode
/// the correct integer value.
///
/// Additionally, we constrain the quotient limbs via `validate_quotient_in_range`:
///   - limbs `0..N-2` of `quotient` are < 2^{120};
///   - the top limb is < 2^{TOP_LIMB_BITS + 6}.
/// Which validates `quotient < 2^{MOD_BITS + 6}`
///
/// ## TODO
/// Apply static or runtime checks in this method to validate that the effective
/// `twiddle_factor` does not exceed 6 under the chosen parameters.
fn compute_quadratic_expression_with_modulus<let N: u32, let MOD_BITS: u32, let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs_terms: [[[u128; N]; LHS_N]; NUM_PRODUCTS],
    lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
    rhs_terms: [[[u128; N]; RHS_N]; NUM_PRODUCTS],
    rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
    linear_terms: [[u128; N]; ADD_N],
    linear_flags: [bool; ADD_N],
) -> [Field; 2 * N - 1] {
    // Safety: use an unconstrained function to compute the value of the quotient and borrow_flags out-of-circuit
    let (quotient, borrow_flags): ([u128; N], [bool; 2 * N - 2]) = unsafe {
        __compute_quadratic_expression_with_borrow_flags::<N, MOD_BITS, LHS_N, RHS_N, NUM_PRODUCTS, ADD_N>(
            params,
            lhs_terms,
            lhs_flags,
            rhs_terms,
            rhs_flags,
            linear_terms,
            linear_flags,
        )
    };

    // Constrain the `quotient < 2^{MOD_BITS + 6}`
    // By constraining limbs(0..N-2) to be < 2^120 and the the top limb < 2^{TOP_LIMB_BITS + 6}
    validate_quotient_in_range::<N, MOD_BITS>(quotient);

    // Compute the linear sums that represent L_i, R_i, A
    let (lhs_linear, rhs_linear, lin_expr): ([[Field; N]; NUM_PRODUCTS], [[Field; N]; NUM_PRODUCTS], [Field; N]) = compute_linear_expressions::<N, MOD_BITS, LHS_N, RHS_N, NUM_PRODUCTS, ADD_N>(
        params,
        lhs_terms,
        lhs_flags,
        rhs_terms,
        rhs_flags,
        linear_terms,
        linear_flags,
    );

    // We want to evaluate that L * R + A - Quotient * MOD = 0, evaluated over the integers
    // For this we need to be able to borrow values from more-significant limbs into less-significant limbs,
    // so that we can ensure that no limbs will underflow
    let mut product_limbs: [Field; 2 * N - 1] = [0; 2 * N - 1];

    // Compute the product t0 * t1 + t4 - Quotient * MOD
    // TODO: this is super nasty as it requires a multiplication
    for i in 0..N {
        for j in 0..N {
            for k in 0..NUM_PRODUCTS {
                if k == 0 {
                    let new_term: Field = lhs_linear[k][i] * rhs_linear[k][j]
                        - (quotient[i] as Field) * (params.modulus[j] as Field);
                    // width-4 optimization
                    std::as_witness(new_term);
                    product_limbs[i + j] += new_term;
                } else {
                    product_limbs[i + j] += lhs_linear[k][i] * rhs_linear[k][j];
                }
            }
            // This is the fallback for pure linear expression
            if (NUM_PRODUCTS == 0) {
                product_limbs[i + j] -= (quotient[i] as Field) * (params.modulus[j] as Field);
            }
        }
        product_limbs[i] += lin_expr[i];
    }

    // Each limb product represents the sum of 120-bit products.
    // by setting the borrow value to 2^246 we are restricting this method's completeness to expressions
    // where no more than 64 limb products are summed together.
    // TODO: define trade-offs regarding the value of borrow_shift
    // (the larger the value, the greater the range check that is required on product_limbs)
    // (126-bit range check is a sweet spot for the barretenberg backend as it decomposes into 9 14-bit range checks)
    // (the barretenberg backend can evaluate these in 5.25 gates. 127 bits costs 6.5 gates)
    let borrow_shift: Field = TWO_POW_246; // 2^{246}
    let borrow_carry: Field = TWO_POW_126; // 2^{246 - 120} = 2^{126}

    // Get the product_limbs into the form where each entry is a 246-bit value
    product_limbs[0] += (borrow_flags[0] as Field) * borrow_shift;
    for i in 1..(N + N - 2) {
        product_limbs[i] += (borrow_flags[i] as Field) * borrow_shift
            - (borrow_flags[i - 1] as Field) * borrow_carry;
    }
    product_limbs[N + N - 2] -= (borrow_flags[N + N - 3] as Field) * borrow_carry;

    product_limbs
}

/// Validate that `limbs` represent the integer value `0`
///
/// ## Assumptions
///     - `limbs` is a `2*N-1` array of `Field` values that was derived arithmetically as
///        a degree-2 expression
///     - each limb satisfies `limbs[i] < 2^{246}`, as ensured by
///       `compute_quadratic_expression_with_modulus` under its parameter bounds.
///
/// ## Details
/// Each element `i` in `limbs` overlaps in bit-range with element `i+1`, EXCEPT for the low 120 bits
/// i.e. we need to do the following for each limb `i`:
///      1. validate the limb's low-120 bits equals zero
///      2. compute the limb "carry" by right-shifting by 2^{120}
///      3. propagate the "carry" into limb `i+1`
/// We can efficiently do all of the above by multiplying the limb by 2^{-120} and constraining the result to be <2^{126}
///
/// If the low 120 bits are nonzero, there is no value in `[0, 2^{126})` that
/// could have produced this limb after multiplying by `2^{120}`. Since
/// multiplication by `2^{120}` is a bijection on the Field, any limb with
/// non-zero low 120 bits must map outside the `[0, 2^{126})` range after
/// scaling by `2^{-120}`.
///
/// The most significant limb has no limb to "carry" values into - the entire limb must equal zero
///
/// ## Note
/// The constant 126 is not arbitrary. We use 120-bit limbs and allow up to 64
/// products per limb, which contributes at most `log2(64) = 6` bits of headroom.
/// After scaling by `2^{-120}`, honest witnesses fit in 126 bits. We could in
/// principle go higher (up to roughly `CircuitModulusBits - 121`), but 126 is
/// the minimal bound consistent with `NUM_PRODUCTS < 64` and is significantly
/// cheaper than larger bounds for the barretenberg backend.
fn validate_expression_is_zero<let N: u32>(mut limbs: [Field; 2 * N - 1]) {
    let hi_shift: Field = TWO_POW_120 as Field;
    let hi_downshift: Field = 1 / hi_shift;
    for i in 0..N + N - 2 {
        limbs[i] *= hi_downshift;
        std::as_witness(limbs[i]);
        limbs[i].assert_max_bit_size::<126>(); // N.B. is this sufficient? going beyond 126 costs us 1 gate per limb
        limbs[i + 1] += limbs[i];
    }
    assert(limbs[N + N - 2] == 0);
}

/// Constrain a degree-2 `BigNum` expression to be equal to 0 (mod `MOD`)
///
//
/// This method is intended for relations where the remainder term of the
/// degree-2 expression is exactly zero as an integer relation. In other words,
/// we use it only when we expect:
///
///     \sum (L_i * R_i) + \sum (A_i) - QUOTIENT * MOD = 0
///
/// as integers, not just modulo the circuit field or `BigNum` field.
///
/// ## Details
///
/// The constrained expression, viewed over the integers, is:
///
///       \sum_{i=0}^{NUM_PRODUCTS-1} (L_i * R_i)
///     + \sum_{i=0}^{ADD_N-1} (A_i)
///     - QUOTIENT * MOD
///     = 0
///
/// Each `L_i`, `R_i`, `A_i` is an `N`-limb `BigNum` assembled from the
/// `(terms, flags)` arrays. For example, for `i = 0`:
///
///     L_0 = \sum_{j=0}^{LHS_N-1} lhs[0][j]    as a `BigNum`
///     R_0 = \sum_{j=0}^{RHS_N-1} rhs[0][j]    as a `BigNum`
///
/// The intent is to capture a generic degree-2 expression within Noir's
/// limitations (no efficient dynamically sized vectors).
///
/// The expensive parts of this algorithm are:
///   1. evaluating the limb products required to compute the `L_i * R_i` values;
///   2. applying range constraints to validate that the result encodes 0.
///
/// ## Note
/// When the expression is evaluated over `N`-limb `BigNum` values, the product
/// has up to `2N - 1` significant limbs. Each limb is a sum of at most
/// `NUM_PRODUCTS` products of `linear` 120-bit limbs and `quadratic` 240-bit-ish limbs
///
/// Note that:
///   * limb-wise multiplication is not uniform across indices. For example:
///
///       [x0, x1, x2] * [y0, y1, y2] =
///       [
///         x0*y0,                               // 1 term
///         x0*y1 + x1*y0,                       // 2 terms
///         x0*y2 + x1*y1 + x2*y0,               // 3 terms
///         x1*y2 + x2*y1,                       // 2 terms
///         x2*y2                                // 1 term
///       ]
///       (grows as C(n, k), the middle limb will always contain the most amount subproducts)
///
///   * we also allow linear combinations inside the products, which further increases the bound
///     on a `quadratic` limb
///
///   * finally, when `is_negative` flag is set, we effectively add 2 * MOD to each limb, where
///     2 * MOD limbs are structured in such a way that they all are > 2**120
///
/// We allow `NUM_PRODUCTS < 64` completeness-wise, but it certainly can overflow the 2^{240 + `twiddle_factor=6`} bound
/// in edge cases. See completeness section for an example.
///
/// ## Assumptions
///
/// Each `BigNum` value used in this gadget is already range constrained:
///   - limbs `0..N-2` satisfy `limb_i < 2^{120}`
///   - limb `N-1` satisfies `limb_{N-1} < 2^{TOP_LIMB_BITS}`
///
/// ## Completeness
/// If an honest prover supplies inputs that satisfy the assumptions above,
/// it can always find a `quotient` and `borrow_flags` such that the integer
/// relation holds and all constraints are satisfied.
///
/// The only possibility to break completeness is by providing too many inputs, for example:
///
///     (a0 + a1 + a2) * (b0 + b1 + b2) + ... (60 times), with each a_i having its limbs at maximum value of 2^{120} - 1
///     The middle limb will contain a value that will definitely overflow the 2^{246} bound.
///
/// ## Soundness
/// This function is conditionally sound: it enforces that the degree-2 relation
/// holds modulo `MOD`, but it does not, by itself, enforce that any particular
/// term (for example a result `z`) is a *canonical* representative in
/// `[0, MOD)`.
///
/// In other words, if the surrounding relation is invariant under adding a
/// multiple of `MOD` to one of its terms, then a dishonest prover can exploit
/// this. For example, consider a multiplication relation:
///
///     x * y - z = 0 (mod MOD)
///
/// Internally we encode this as:
///
///     x * y + 2 * MOD - z - quotient * MOD = 0
///
/// which is equivalent to:
///
///     x * y - z = (quotient - 2) * MOD
///
/// Suppose the honest witness uses some `z` satisfying
/// `0 <= z < MOD` and some `quotient`. If the `BigNum` encoding allows
/// `z' = z + MOD` (i.e. `z' < 2^{MOD_BITS}` still holds), then a dishonest
/// prover can instead provide:
///
///     z' = z + MOD
///     quotient' = quotient - 1
///
/// and still satisfy:
///
///     x * y + 2 * MOD - z' - quotient' * MOD = 0
///
/// even though `z'` is no longer the canonical representative of `x * y mod MOD`.
///
/// The same consideration applies to almost every constrained `BigNum` relation:
/// whenever a value participates *only* through a modular equality, and no
/// separate range constraint is imposed on that value, the prover is free to
/// shift it by an extra `MOD` as long as the resulting limb
/// encoding still satisfies its bit-bounds. This is inherent in working with
/// modular constraints; the responsibility for enforcing canonical
/// representatives lies with the caller when it is required.
///
/// This is the same "extra modulus" phenomenon as in the `add`/`sub` functions:
/// the constraints are sound for modular arithmetic, but any caller that
/// requires canonical outputs in `[0, MOD)` must additionally enforce a
/// range check (for example via `validate_in_field`) on the relevant terms.
pub(crate) fn evaluate_quadratic_expression<let N: u32, let MOD_BITS: u32, let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs_terms: [[[u128; N]; LHS_N]; NUM_PRODUCTS],
    lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
    rhs_terms: [[[u128; N]; RHS_N]; NUM_PRODUCTS],
    rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
    linear_terms: [[u128; N]; ADD_N],
    linear_flags: [bool; ADD_N],
) {
    assert(NUM_PRODUCTS < 64, f"evaluate_quadratic_expression overflow in operands count");
    // NUM_PRODUCTS < 64 is a light bound that tries to ensure each limb sum < 2^{246} so that the 126-bit bound is valid.

    lhs_terms.for_each(|lhs_limbs: [[u128; N]; LHS_N]| {
        lhs_limbs.for_each(|term: [u128; N]| validate_in_range::<u128, N, MOD_BITS>(term))
    });
    rhs_terms.for_each(|rhs_limbs: [[u128; N]; RHS_N]| {
        rhs_limbs.for_each(|term: [u128; N]| validate_in_range::<u128, N, MOD_BITS>(term))
    });
    linear_terms.for_each(|term: [u128; N]| validate_in_range::<u128, N, MOD_BITS>(term));

    let product_limbs: [Field; 2 * N - 1] = compute_quadratic_expression_with_modulus::<N, MOD_BITS, LHS_N, RHS_N, NUM_PRODUCTS, ADD_N>(
        params,
        lhs_terms,
        lhs_flags,
        rhs_terms,
        rhs_flags,
        linear_terms,
        linear_flags,
    );
    validate_expression_is_zero(product_limbs);
}
