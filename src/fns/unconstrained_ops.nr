// This file contains the unconstrained operations that are used directly by BigNum class

use crate::fns::constrained_ops::derive_from_seed;

use crate::fns::unconstrained_helpers::{
    __barrett_reduction, __get_bit, __get_msb, __helper_add, __helper_mul, __helper_sub,
    __increment, __multiplicative_generator, __one, __primitive_root_log_size, __shl, __shr, __shr1,
    __tonelli_shanks_sqrt_inner_loop_check,
};

use crate::constants::TWO_POW_120;

use crate::params::BigNumParams;

// ------------------------------ DERIVATION FUNCTIONS ------------------------------

/// Deterministically derives a `BigNum` from a seed value (unconstrained)
///
/// Takes a seed byte array and generates a `BigNum` in the range [0, modulus-1].
///
/// See more information in `constrained_ops.nr`: `derive_from_seed`
pub(crate) unconstrained fn __derive_from_seed<let N: u32, let MOD_BITS: u32, let SeedBytes: u32>(
    params: BigNumParams<N, MOD_BITS>,
    seed: [u8; SeedBytes],
) -> [u128; N] {
    derive_from_seed::<N, MOD_BITS, SeedBytes>(params, seed)
}

// ------------------------------ COMPARISON FUNCTIONS ------------------------------

/// Compare two limb arrays for equality (unconstrained)
pub(crate) unconstrained fn __eq<let N: u32>(lhs: [u128; N], rhs: [u128; N]) -> bool {
    lhs == rhs
}

/// Compare a limb array to a zero array (unconstrained)
pub(crate) unconstrained fn __is_zero<let N: u32>(limbs: [u128; N]) -> bool {
    limbs == [0; N]
}

/// Compare two little-endian limb arrays for `lhs >= rhs` over integers (unconstrained)
///
/// Starts from the most significant limb (`N - 1`) and returns true
/// if `lhs` is greater or equal to `rhs`
pub(crate) unconstrained fn __gte<let N: u32>(lhs: [u128; N], rhs: [u128; N]) -> bool {
    let mut result: bool = true;
    for i in 0..N {
        let idx: u32 = N - 1 - i;
        if (lhs[idx] != rhs[idx]) {
            result = lhs[idx] > rhs[idx];
            break;
        }
    }
    result
}

// ------------------------------ ARITHMETIC FUNCTIONS ------------------------------

/// Negates a `BigNum` value, returning `m - x` (unconstrained)
///
/// ## Note
/// The input is assumed to be less than modulus
pub(crate) unconstrained fn __neg<let N: u32>(modulus: [u128; N], limbs: [u128; N]) -> [u128; N] {
    __helper_sub(modulus, limbs)
}

/// Adds two `BigNum` values with modular reduction (unconstrained)
///
/// Sums the limbs one by one, keeping the carry.
/// In case the result overflows the modulus, the modulus is subtracted once
///
/// ## Note
/// The `carry` must be `0` at the end of the loop.
/// No explicit assertion is made, as this condition is validated during evaluation.
pub(crate) unconstrained fn __add<let N: u32>(
    modulus: [u128; N],
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    let mut result: [u128; N] = [0; N];
    let mut carry: u128 = 0;
    let mask: u128 = TWO_POW_120 - 1;

    for i in 0..N {
        let add_term: u128 = (lhs[i] + rhs[i] + carry);
        carry = add_term >> 120;
        result[i] = add_term & mask;
    }

    // check if the result is greater than the modulus
    if __gte(result, modulus) {
        __helper_sub(result, modulus)
    } else {
        result
    }
}

/// Subtracts two `BigNum` values with modular reduction (unconstrained).
///
/// Computes `x + (m - y)` (mod m)
pub(crate) unconstrained fn __sub<let N: u32>(
    modulus: [u128; N],
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    __add(modulus, lhs, __neg(modulus, rhs))
}

/// Multiply `x` and `y` and reduce via Barrett, returning (Q, R) (unconstrained).
///
/// For `BigNum` values `x` and `y` compute (`Q`, `R`) such that:
///      x * y = R + Q * m, 0 <= R < m
/// See `__barrett_reduction` for details.
pub(crate) unconstrained fn __mul_with_quotient<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> ([u128; N], [u128; N]) {
    let to_reduce: [u128; N * 2] = __helper_mul(lhs, rhs);
    let (q, r): ([u128; N], [u128; N]) =
        __barrett_reduction(to_reduce, params.redc_param, MOD_BITS, params.modulus);
    (q, r)
}

/// Multiplies two `BigNum` values with modular reduction (unconstrained).
pub(crate) unconstrained fn __mul<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    __mul_with_quotient::<N, MOD_BITS>(params, lhs, rhs).1
}

/// Squares a `BigNum` value with modular reduction (unconstrained).
pub(crate) unconstrained fn __sqr<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    val: [u128; N],
) -> [u128; N] {
    __mul_with_quotient::<N, MOD_BITS>(params, val, val).1
}

/// Modular exponentiation via square-and-multiply. LSB-first (unconstrained).
///
/// Computes `x^e mod m`
///
/// ## Note
/// For the loop, we are using `MOD_BITS` instead of `__get_msb`
/// because it is much much cheaper
pub(crate) unconstrained fn __pow<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    val: [u128; N],
    exponent: [u128; N],
) -> [u128; N] {
    let mut accumulator: [u128; N] = __one();
    let mut x: [u128; N] = val;
    let num_bits: u32 = MOD_BITS + 1;

    for i in 0..num_bits {
        if __get_bit(exponent, i) {
            accumulator = __mul::<N, MOD_BITS>(params, accumulator, x);
        }
        x = __sqr::<N, MOD_BITS>(params, x);
    }
    accumulator
}

/// Given a `BigNum` value `x` compute x^{-1} (mod m) (unconstrained)
///
/// x^{p-1} = 1 (mod p) (Fermat's little theorem)
/// x^{p-2} = x^{-1} (mod p)
///
/// ## Note
/// The input value must be nonzero
/// No explicit assertion is made, as this condition is validated during evaluation
pub(crate) unconstrained fn __invmod<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    val: [u128; N],
) -> [u128; N] {
    let one: [u128; N] = __one();
    let exp: [u128; N] = __helper_sub(params.modulus, __helper_add(one, one));
    __pow::<N, MOD_BITS>(params, val, exp)
}

/// Divides two `BigNum` values with modular reduction (unconstrained).
///
/// Computes `x * y^{-1}` (mod m)
///
/// ## Note
/// The divisor must be nonzero
/// No explicit assertion is made, as this condition is validated during evaluation
pub(crate) unconstrained fn __div<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    numerator: [u128; N],
    divisor: [u128; N],
) -> [u128; N] {
    let inv_divisor: [u128; N] = __invmod::<N, MOD_BITS>(params, divisor);
    __mul::<N, MOD_BITS>(params, numerator, inv_divisor)
}

/// Given the `BigNum` inputs `x, y`, compute integer division x / y (unconstrained)
///
/// This function implements binary long division and outputs (`quotient`, `remainder`) such that:
///   1. floor(numerator / divisor) = quotient
///   2. numerator % divisor = remainder
///   3. divisor * quotient + remainder = numerator
///
/// ## Note
/// The divisor must be nonzero
/// No explicit assertion is made, as this condition is validated during evaluation
pub(crate) unconstrained fn __udiv_mod<let N: u32>(
    numerator: [u128; N],
    divisor: [u128; N],
) -> ([u128; N], [u128; N]) {
    let mut quotient: [u128; N] = [0; N];
    let mut remainder: [u128; N] = numerator;
    let b: [u128; N] = divisor;

    let numerator_msb: u32 = __get_msb(numerator);
    let divisor_msb: u32 = __get_msb(divisor);
    if divisor_msb > numerator_msb {
        ([0; N], numerator)
    } else {
        let mut bit_difference: u32 = __get_msb(remainder) - __get_msb(divisor);
        let mut divisor: [u128; N] = __shl(divisor, bit_difference);
        let mut accumulator: [u128; N] = __shl(__one(), bit_difference);

        // The same as divisor > remainder
        if (__gte(divisor, __increment(remainder))) {
            divisor = __shr1(divisor);
            accumulator = __shr1(accumulator);
        }

        for _ in 0..(N * 120) {
            if (__gte(remainder, b) == false) {
                break;
            }
            // we've shunted 'divisor' up to have the same bit length as our remainder.
            // If remainder >= divisor, then a is at least '1 << bit_difference' multiples of b
            if (__gte(remainder, divisor)) {
                remainder = __helper_sub(remainder, divisor);
                // we can use OR here instead of +, as
                // accumulator is always a nice power of two
                quotient = __helper_add(quotient, accumulator);
            }
            divisor = __shr1(divisor);
            accumulator = __shr1(accumulator);
        }

        (quotient, remainder)
    }
}

/// Batch modular inversion of `BigNum` values in an array (unconstrained)
///
/// Given values v[0..M), returns inv[0...M) with inv[i] = v[i]^{-1} (mod m)
///
/// We use the Montgomery trick:
/// First we compute the partial products:
///         T0 = 1
///         T1 = v1,
///         T2 = v1 * v2,
///         ...
///         T_{m - 1} = T_{m - 2} * v_{m - 1} = v1 * ... * v_{m - 1}
///
///         P = T_{m-1} * v_m = v1 * v2 * ... * v_m
///
/// Then we calculate a single inverse P^-1 = v1^-1 * v2^-1 * ... * v_m^-1
/// Finally we compute
///         v_m^-1       = (P^-1 * T_{m-1})
///         v_{m - 1}^-1 = (P^-1 * v_m * T_{m - 2})
///         ....
///         v_2^-1       = (P^-1 * v_m * ... * v_3 * T_1)
///         v_1^-1       = (P^-1 * v_m * ... * v_2 * T_0)
///
/// ## Note
/// All the values must be nonzero
/// No explicit assertion is made, as this condition is validated during evaluation
pub(crate) unconstrained fn batch_invert<let N: u32, let MOD_BITS: u32, let M: u32>(
    params: BigNumParams<N, MOD_BITS>,
    vals: [[u128; N]; M],
) -> [[u128; N]; M] {
    let mut accumulator: [u128; N] = __one();
    let mut temporaries: [[u128; N]; M] = [[0; N]; M];

    for i in 0..M {
        temporaries[i] = accumulator;
        accumulator = __mul::<N, MOD_BITS>(params, accumulator, vals[i]);
    }

    let mut result: [[u128; N]; M] = [[0; N]; M];
    accumulator = __invmod::<N, MOD_BITS>(params, accumulator);
    for i in 0..M {
        let idx: u32 = M - 1 - i;
        let T0: [u128; N] = __mul::<N, MOD_BITS>(params, accumulator, temporaries[idx]);
        accumulator = __mul::<N, MOD_BITS>(params, accumulator, vals[idx]);
        result[idx] = T0;
    }
    result
}

/// Batch modular inversion of `BigNum` values in a slice (unconstrained)
///
/// See `batch_invert` for details
pub(crate) unconstrained fn batch_invert_slice<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    vals: [[u128; N]],
) -> [[u128; N]] {
    let mut accumulator: [u128; N] = __one();
    let mut temporaries: [[u128; N]] = &[];

    let M: u32 = vals.len();

    for i in 0..M {
        temporaries = temporaries.push_back(accumulator);
        accumulator = __mul::<N, MOD_BITS>(params, accumulator, vals[i]);
    }

    let mut result: [[u128; N]] = [];
    accumulator = __invmod::<N, MOD_BITS>(params, accumulator);
    for i in 0..M {
        let idx: u32 = M - 1 - i;
        let T0: [u128; N] = __mul::<_, MOD_BITS>(params, accumulator, temporaries[idx]);
        accumulator = __mul::<_, MOD_BITS>(params, accumulator, vals[idx]);
        result = result.push_front(T0);
    }

    result
}

/**
* @brief compute a modular square root using the Tonelli-Shanks algorithm
* @details only use for prime fields! Function may infinite loop if used for non-prime fields
* @note this is unconstrained fn. To constrain a square root, validate that output^2 = self
* TODO: create fn that constrains nonexistence of square root (i.e. find x where x^2 = -self)
**/
pub(crate) unconstrained fn __tonelli_shanks_sqrt<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    input: [u128; N],
) -> std::option::Option<[u128; N]> {
    // Tonelli-shanks algorithm begins by finding a field element Q and integer S,
    // such that (p - 1) = Q.2^{s}
    // We can compute the square root of a, by considering a^{(Q + 1) / 2} = R
    // Once we have found such an R, we have
    // R^{2} = a^{Q + 1} = a^{Q}a
    // If a^{Q} = 1, we have found our square root.
    // Otherwise, we have a^{Q} = t, where t is a 2^{s-1}'th root of unity.
    // This is because t^{2^{s-1}} = a^{Q.2^{s-1}}.
    // We know that (p - 1) = Q.w^{s}, therefore t^{2^{s-1}} = a^{(p - 1) / 2}
    // From Euler's criterion, if a is a quadratic residue, a^{(p - 1) / 2} = 1
    // i.e. t^{2^{s-1}} = 1
    // To proceed with computing our square root, we want to transform t into a smaller subgroup,
    // specifically, the (s-2)'th roots of unity.
    // We do this by finding some value b,such that
    // (t.b^2)^{2^{s-2}} = 1 and R' = R.b
    // Finding such a b is trivial, because from Euler's criterion, we know that,
    // for any quadratic non-residue z, z^{(p - 1) / 2} = -1
    // i.e. z^{Q.2^{s-1}} = -1
    // => z^Q is a 2^{s-1}'th root of -1
    // => z^{Q^2} is a 2^{s-2}'th root of -1
    // Since t^{2^{s-1}} = 1, we know that t^{2^{s - 2}} = -1
    // => t.z^{Q^2} is a 2^{s - 2}'th root of unity.
    // We can iteratively transform t into ever smaller subgroups, until t = 1.
    // At each iteration, we need to find a new value for b, which we can obtain
    // by repeatedly squaring z^{Q}
    let one = __one();
    let primitive_root_log_size = __primitive_root_log_size::<_, MOD_BITS>(params);
    let Q = __shr(
        __helper_sub(params.modulus, one),
        primitive_root_log_size - 1,
    );
    let two = __helper_add(one, one);
    let Q_minus_one_over_two = __shr(__helper_sub(Q, two), 2);
    let mut z = __multiplicative_generator::<_, MOD_BITS>(params); // the generator is a non-residue
    let mut b = __pow::<_, MOD_BITS>(params, input, Q_minus_one_over_two);
    let mut r = __mul::<_, MOD_BITS>(params, input, b);
    let mut t = __mul::<_, MOD_BITS>(params, r, b);
    let mut check: [u128; N] = t;
    for _ in 0..primitive_root_log_size - 1 {
        check = __mul::<_, MOD_BITS>(params, check, check);
    }
    let mut result = Option::none();
    if (__eq(check, one)) {
        let mut t1 = __pow::<_, MOD_BITS>(params, z, Q_minus_one_over_two);
        let mut t2 = __mul::<_, MOD_BITS>(params, t1, z);
        let mut c = __mul::<_, MOD_BITS>(params, t2, t1);
        let mut m: u32 = primitive_root_log_size;
        // tonelli shanks inner 1
        // (if t2m == 1) then skip
        // else increase i and square t2m and go again
        // algorithm runtime should only be max the number of bits in modulus
        for _ in 0..MOD_BITS {
            if (__eq(t, one)) {
                result = Option::some(r);
                break;
            }
            let mut t2m = t;
            // while loop time
            let i = __tonelli_shanks_sqrt_inner_loop_check::<_, MOD_BITS>(params, t2m, 0);
            let mut j = m - i - 1;
            b = c;
            for _ in 0..j {
                // how big
                if (j == 0) {
                    break;
                }
                b = __mul(params, b, b);
                //j -= 1;
            }
            c = __mul::<_, MOD_BITS>(params, b, b);
            t = __mul::<_, MOD_BITS>(params, t, c);
            r = __mul::<_, MOD_BITS>(params, r, b);
            m = i;
        }
    }
    result
}
