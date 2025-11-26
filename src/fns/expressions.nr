use crate::utils::split_bits;

use crate::constants::{TWO_POW_120, TWO_POW_126, TWO_POW_246};

use crate::fns::constrained_ops::validate_quotient_in_range;
use crate::fns::unconstrained_helpers::__barrett_reduction;
use crate::fns::unconstrained_ops::__is_zero;

use crate::params::BigNumParams;

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

/// Constrain a degree-2 `BigNum` expression to be equal to 0 (mod `MOD`)
///
/// ## Note
/// The constant 126 is not arbitrary.
/// We could go higher, up to the number of bits in the CircuitModulus - 121, but 126 *should be* sufficient and is much cheaper
///
/// This method requires the remainder term of the expression to be exactly *ZERO* integer wise
///
/// ## Details
///
/// The expression is of the form (when evaluated as an integer relation):
///
/// \sum_{i=0}^{NUM_PRODUCTS-1} (L_i * R_i) + \sum_{i=0}^{ADD_N-1} (A_i) - QUOTIENT * MODULUS = 0
///
/// Where each `L_i`, `R_i`, `A_i` is an `N`-limb `BigNum` assembled from the provided
/// `(terms, flags)` arrays
/// For example for i = 0:
///     L_0 = \sum_{j = 0}^{LHS_N-1} lhs[0][j] - As a `BigNum`
///     R_0 = \sum_{j = 0}^{RHS_N-1} rhs[0][j] - As a `BigNum`
///
/// The intent is to capture an arbitrary degree-2 expression within the limitations of Noir (no efficient dynamically-sized vectors)
///
/// The expensive parts of this algorithm are the following:
///      1. evaluating the limb products required to compute `lhs * rhs`
///      2. applying range constraints to validate the result is 0
///
/// When the expression is evaluated over `N`-limb `BigNum` object, the product has up to `2N - 1` significant limbs.
/// Each limb is a sum of at most `NUM_PRODUCTS` products of 120-bit limbs, so for `NUM_PRODUCTS < 64` every limb lies in the range
///     [0, ..., 2^{240 + twiddle_factor} - 1] with `twiddle_factor <= 6`
/// In particular, in this implementation we bound each limb by 2^{246}
///
/// ## Note
/// Of course we have to take into account that each product has to be exactly 240-bit value to get 2^{246} bound. It may not be the case, because
/// We allow linear combinations as parts of a product. But in general, the 2^{246} still holds.
/// Also limb-wise multiplication is not uniform depending on limb:
///    [x0, x1, x2] * [y0, y1, y2] =
///    [
///          x0 * y0,                         // 1 term
///          x0 * y1 + x1 * y0,               // 2 terms
///          x0 * y2 + x1 * y1 + x2 * y0,     // 3 terms
///          x1 * y2 + x2 * y1,               // 2 terms
///          x2 * y2                          // 1 term
///     ])
///
/// Because of the possible subtraction of `quotient * MOD`, the resulting limbs may underflow and represent *NEGATIVE* values.
/// To account for this, we allow the *Prover* to choose a sequence of borrow flags and interpret the limbs with additional terms:
///     - for each limb `i` we may *add* `2^{246}` (via a flag at position `i`)
///     - for each limb `i` we may *subtract* `2^{126 = 246 - 120}` (via the flag at position `i-1`)
///
/// Which corresponds to borrowing `2^{126}` from limb `i+1` and adding `2^{246}` into limb`i`.
/// After this adjustment, an honest prover can ensure that every limb lies in `[0, 2^{246})` and that the adjusted limbs encode the correct integer value
///
/// To test that the adjusted multi-limb integer is equal to 0, we then:
///     1. Multiply each limb by `2^{-120}` in the circuit field
///     2. Enforce that the result fits in 126 bits
///     3. Add that result into the next more significant limb and repeat
///
/// ## Assumptions
/// Each `BigNum` value is valid:
///     - limbs(i=0..N-2) < 2^{120}
///     - limb_{N-1} < 2^{TOP_LIMB_BITS}
///
///     T = [t0, t1, t2, ..., t_{2N - 2}] - the computed expression limb-wise, each t_i < 2^{240 + 6}
///     S = [s0, s1, s2, ..., s_{2N - 2}] = quotient * MOD, each s_i < 2^{240}
///
/// ## Soundness
///
/// Then we compute T - S and constrain:
///     (t0       - s0       + bf[0]    * 2^{246}                     ) * 2^{-120} < 2^{126}
///     (t1       - s1       + bf[1]    * 2^{246} - bf[0]    * 2^{126}) * 2^{-120} < 2^{126}
///     ...
///     (t_{2N-3} - s_{2N-3} + bf[2N-3] * 2^{246} - bf[2N-4] * 2^{126}) * 2^{-120} < 2^{126}
///     (t_{2N-2} - s_{2N-2}                      - bf[2N-3] * 2^{126}             = 0
///
/// Additionally we constrain the quotient limbs:
///     - limbs(0..N-2) < 2^{120}
///     - limb_{N-1}    < 2^{TOP_LIMB_BITS + 6}
///
/// For honest prover, after applying the chosen borrow pattern, each limb has magnitude strictly less than 2^{246},
/// with lower 120-bits being 0
/// Multiplication by `2^{-120}` therefore just shift the value to be a 126-bit integer
///
/// The dishonest prover whose integer relation is not zero, some limb must have a non-zero low 120 bits in the true integer representation
/// Regardless of the chosen `quotient` and borrow flags. For such a limb, multiplying by `2^{-120}` produces a field element which is
/// effectively pseudorandom in `F_p` with respect to the small interval `[0, 2^{126})`
///
/// The probability that a uniformly random element of `F_p` lies in `[0, 2^{126})` is approximately 2^{126} / CircuitModulus ~ 2^{126 - k} (Idk maybe not)
///
/// ## Completeness
///
/// Under the assumptions:
///     - `NUM_PRODUCTS < 64`
///     - all input `BigNum` limbs are computed correctly
///
/// any honest assignment that satisfies the integer relation:
///     \sum L_i * R_i + \sum A_i - quotient * MOD = 0
///
/// admits a choice of `borrow_flags` such that:
///     - the adjusted `product_limbs` array lies within `[0, 2^{246})` limb-wise
///     - the per-limb scaling by 2^{-120} never overflows the 126-bit bound
///     - the iterative carry propagation leaves the final limb equal to 0
///
/// Thus any honest witness that realizes a valid integer relation will satisfy all constraints in this function.
///
/// ## TODO:
/// apply checks in this method to validate `twiddle_factor` does not exceed 6
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
    // NUM_PRODUCTS < 64 ensures each limb sum < 2^{246} so that the 126-bit bound is valid.

    // Safety: use an unconstrained function to compute the value of the quotient
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

    // (should be a compile-time check...unconstrained function?)
    // Compute the linear sums that represent lhs_1, rhs_1, lhs_2, rhs_2

    // lhs linear terms
    let mut t0: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
    // rhs linear terms
    let mut t1: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
    // linear terms
    let mut t4: [Field; N] = [0; N];

    let double_modulus: [u128; N] = params.double_modulus;

    for k in 0..NUM_PRODUCTS {
        for i in 0..N {
            for j in 0..LHS_N {
                // Note: if lhs_flags[k][j] - `is_negative` is not known at comptime this is very expensive
                if (lhs_flags[k][j]) {
                    t0[k][i] -= lhs_terms[k][j][i] as Field;
                    t0[k][i] += double_modulus[i] as Field;
                } else {
                    t0[k][i] += lhs_terms[k][j][i] as Field;
                }
            }
            for j in 0..RHS_N {
                // Note: if rhs_flags[k][j] - `is_negative` is not known at comptime this is very expensive
                if (rhs_flags[k][j]) {
                    t1[k][i] -= rhs_terms[k][j][i] as Field;
                    t1[k][i] += double_modulus[i] as Field;
                } else {
                    t1[k][i] += rhs_terms[k][j][i] as Field;
                }
            }
        }
    }

    for i in 0..N {
        for j in 0..ADD_N {
            // Note: if linear_flags[j] - `is_negative` is not known at comptime this is very expensive
            if (linear_flags[j]) {
                t4[i] -= linear_terms[j][i] as Field;
                t4[i] += double_modulus[i] as Field;
            } else {
                t4[i] += linear_terms[j][i] as Field;
            }
        }
    }

    // We want to evaluate that t0 * t1 + t4 - Quotient * MOD = 0, evaluated over the integers
    // For this we need to be able to borrow values from more-significant limbs into less-significant limbs,
    // so that we can ensure that no limbs will underflow for an honest Prover
    let mut product_limbs: [Field; 2 * N - 1] = [0; 2 * N - 1];

    // Compute the product t0 * t1 + t4 - Quotient * MOD
    // TODO: this is super nasty as it requires a multiplication
    for i in 0..N {
        for j in 0..N {
            for k in 0..NUM_PRODUCTS {
                if k == 0 {
                    let new_term: Field =
                        t0[k][i] * t1[k][j] - (quotient[i] as Field) * (params.modulus[j] as Field);
                    // width-4 optimization
                    std::as_witness(new_term);
                    product_limbs[i + j] += new_term;
                } else {
                    product_limbs[i + j] += t0[k][i] * t1[k][j];
                }
            }
            // This is the fallback for pure linear expression
            if (NUM_PRODUCTS == 0) {
                product_limbs[i + j] -= (quotient[i] as Field) * (params.modulus[j] as Field);
            }
        }
        product_limbs[i] += t4[i];
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

    // Get the product_limbs into the form where each entry is a 126-bit value
    product_limbs[0] += (borrow_flags[0] as Field) * borrow_shift;
    for i in 1..(N + N - 2) {
        product_limbs[i] += (borrow_flags[i] as Field) * borrow_shift
            - (borrow_flags[i - 1] as Field) * borrow_carry;
    }
    product_limbs[N + N - 2] -= (borrow_flags[N + N - 3] as Field) * borrow_carry;

    // Final step: Validate `product_limbs` represents the integer value `0`
    // Each element `i` in `product_limbs` overlaps in bit-range with element `i+1`, EXCEPT for the low 120 bits
    // i.e. we need to do the following for each limb `i`:
    //      1. validate the limb's low-120 bits equals zero
    //      2. compute the limb "carry" by right-shifting by 2^{120}
    //      3. add the carry into limb `i+1`
    // We can efficiently do all of the above by multiplying the limb by 2^{-120} and constraining the result to be <2^{126}
    // (if the low 120 bits are nonzero the result will underflow and product a large value that cannot be range constrained)
    // (the probability of an underflow value satisfying a 126-bit range constraint is approx. 2^{k - 126},
    //  where k is the number of bits in the prime field)
    // We then add the result into the next limb and repeat.
    let hi_shift: Field = TWO_POW_120 as Field;
    let hi_downshift: Field = 1 / hi_shift;
    for i in 0..N + N - 2 {
        product_limbs[i] *= hi_downshift;
        std::as_witness(product_limbs[i]);
        product_limbs[i].assert_max_bit_size::<126>(); // N.B. is this sufficient? going beyond 126 costs us 1 gate per limb
        product_limbs[i + 1] += product_limbs[i];
    }
    // the most significant limb has no limb to "carry" values into - the entire limb must equal zero
    assert(product_limbs[N + N - 2] == 0);
}
