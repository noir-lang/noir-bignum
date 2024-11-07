use crate::fns::constrained_ops::derive_from_seed;
use crate::fns::unconstrained_helpers::{
    __barrett_reduction, __multiplicative_generator, __primitive_root_log_size,
    __tonelli_shanks_sqrt_inner_loop_check,
};
use crate::params::BigNumParams as P;
use crate::utils::split_bits;
use crate::utils::u60_representation::U60Repr;

/**
 * In this file:
 *
 * __one
 * __derive_from_seed
 * __eq
 * __is_zero
 * __neg
 * __add
 * __sub
 * __mul_with_quotient
 * __mul
 * __div
 * __udiv_mod
 * __invmod
 * __pow
 * __batch_invert
 * __batch_invert_slice
 */

pub(crate) unconstrained fn __one<let N: u32>() -> [Field; N] {
    let mut limbs: [Field; N] = [0; N];
    limbs[0] = 1;
    limbs
}

/// Deterministically derives a big_num from a seed value.
///
/// Takes a seed byte array and generates a big_num in the range [0, modulus-1].
///
/// ## Value Parameters
///
/// - `params`: The BigNum parameters containing modulus and reduction info
/// - `seed`:  Input seed bytes to derive from.
///
/// ## Returns
///
///  An array of field elements derived from the seed (the limbs of the big_num)
pub(crate) unconstrained fn __derive_from_seed<let N: u32, let MOD_BITS: u32, let SeedBytes: u32>(
    params: P<N, MOD_BITS>,
    seed: [u8; SeedBytes],
) -> [Field; N] {
    let out = derive_from_seed::<N, MOD_BITS, SeedBytes>(params, seed);
    out
}

pub(crate) unconstrained fn __eq<let N: u32>(lhs: [Field; N], rhs: [Field; N]) -> bool {
    lhs == rhs
}

pub(crate) unconstrained fn __is_zero<let N: u32>(limbs: [Field; N]) -> bool {
    let mut result: bool = true;
    for i in 0..N {
        result = result & (limbs[i] == 0);
    }

    result
}

/**
* @brief given an input `x`, compute `2p - x` (unconstrained)
*
* @description we subtract the input from double the modulus, because all constrained BigNum operations
*              only guarantee that the output is in the range [0, ceil(log2(p))].
*              I.E. the input may be larger than the modulus `p`.
*              In order to ensure this operation does not underflow, we compute `2p - x` instead of `p - x`.
*              N.B. constrained BigNum operations do not fully constrain outputs to be in the range [0, p-1]
*              because such a check is expensive and usually unneccesary.
*/
pub(crate) unconstrained fn __neg<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    limbs: [Field; N],
) -> [Field; N] {
    let f: [Field; N] = limbs;
    let x_u60: U60Repr<N, 2> = U60Repr::from(f);
    U60Repr::into(params.modulus_u60 - x_u60)
}

pub(crate) unconstrained fn __add<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [Field; N],
    rhs: [Field; N],
) -> [Field; N] {
    let x_u60: U60Repr<N, 2> = U60Repr::from(lhs);
    let y_u60: U60Repr<N, 2> = U60Repr::from(rhs);

    let mut z_u60 = x_u60 + y_u60;

    if z_u60.gte(params.modulus_u60) {
        z_u60 = z_u60 - params.modulus_u60;
    }
    U60Repr::into(z_u60)
}

/**
* @brief given inputs `x, y` compute 2p + x - y (unconstrained)
* @description see `__neg` for why we use 2p instead of p
**/
pub(crate) unconstrained fn __sub<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [Field; N],
    rhs: [Field; N],
) -> [Field; N] {
    __add(params, lhs, __neg(params, rhs))
}

pub(crate) unconstrained fn __mul_with_quotient<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [Field; N],
    rhs: [Field; N],
) -> ([Field; N], [Field; N]) {
    let mut mul: [Field; 2 * N] = [0; 2 * N];
    for i in 0..N {
        for j in 0..N {
            mul[i + j] += lhs[i] * rhs[j];
        }
    }
    let to_reduce = split_bits::__normalize_limbs(mul, 2 * N);
    let (q, r) = __barrett_reduction(
        to_reduce,
        params.redc_param,
        MOD_BITS,
        params.modulus,
        params.modulus_u60_x4,
    );

    (q, r)
}

pub(crate) unconstrained fn __mul<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [Field; N],
    rhs: [Field; N],
) -> [Field; N] {
    let (_, b) = __mul_with_quotient::<_, MOD_BITS>(params, lhs, rhs);
    b
}

pub(crate) unconstrained fn __div<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    numerator: [Field; N],
    divisor: [Field; N],
) -> [Field; N] {
    let inv_divisor = __invmod::<_, MOD_BITS>(params, divisor);
    __mul::<_, MOD_BITS>(params, numerator, inv_divisor)
}

/**
* @brief __udiv_mod performs *unconstrained* integer division between numerator, divisor 
*
* i.e. 1. floor(numerator / divisor) = quotient
*      2. numerator % divisor = remainder
*      3. divisor * quotient + remainder = numerator
**/
pub(crate) unconstrained fn __udiv_mod<let N: u32>(
    numerator: [Field; N],
    divisor: [Field; N],
) -> ([Field; N], [Field; N]) {
    let mut quotient_u60: U60Repr<N, 2> = U60Repr::from([0; N]);
    let mut remainder_u60: U60Repr<N, 2> = U60Repr::from(numerator);

    let mut divisor_u60: U60Repr<N, 2> = U60Repr::from(divisor);
    let b = divisor_u60;

    let mut bit_difference = remainder_u60.get_msb() - divisor_u60.get_msb();

    let mut accumulator_u60: U60Repr<N, 2> = U60Repr::one();
    divisor_u60 = divisor_u60.shl(bit_difference);
    accumulator_u60 = accumulator_u60.shl(bit_difference);

    if (divisor_u60.gte(remainder_u60 + U60Repr::one())) {
        divisor_u60.shr1();
        accumulator_u60.shr1();
    }
    for _ in 0..(N * 120) {
        if (remainder_u60.gte(b) == false) {
            break;
        }

        // we've shunted 'divisor' up to have the same bit length as our remainder.
        // If remainder >= divisor, then a is at least '1 << bit_difference' multiples of b
        if (remainder_u60.gte(divisor_u60)) {
            remainder_u60 -= divisor_u60;
            // we can use OR here instead of +, as
            // accumulator is always a nice power of two
            quotient_u60 = quotient_u60 + accumulator_u60;
        }
        divisor_u60.shr1(); // >>= 1;
        accumulator_u60.shr1(); //  >>= 1;
    }

    (U60Repr::into(quotient_u60), U60Repr::into(remainder_u60))
}

pub(crate) unconstrained fn __invmod<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    val: [Field; N],
) -> [Field; N] {
    let one: [Field; N] = __one::<N>();
    let one_u60: U60Repr<N, 2> = U60Repr::from(one);
    let exp_u60 = params.modulus_u60.sub(one_u60.add(one_u60));
    let exp = U60Repr::into(exp_u60);
    __pow::<_, MOD_BITS>(params, val, exp)
}

pub(crate) unconstrained fn __pow<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    val: [Field; N],
    exponent: [Field; N],
) -> [Field; N] {
    let x: U60Repr<N, 2> = U60Repr::from(exponent);

    let num_bits = MOD_BITS + 1;

    let mut accumulator: [Field; N] = __one::<N>();

    for i in 0..num_bits {
        accumulator = __mul::<_, MOD_BITS>(params, accumulator, accumulator);
        if x.get_bit(num_bits - i - 1) {
            accumulator = __mul::<_, MOD_BITS>(params, accumulator, val);
        }
    }
    accumulator
}

pub(crate) unconstrained fn __batch_invert<let N: u32, let MOD_BITS: u32, let M: u32>(
    params: P<N, MOD_BITS>,
    x: [[Field; N]; M],
) -> [[Field; N]; M] {
    // TODO: ugly! Will fail if input slice is empty
    let mut accumulator: [Field; N] = __one::<N>();
    let mut result: [[Field; N]; M] = [[0; N]; M];
    let mut temporaries: [[Field; N]] = &[];
    for i in 0..x.len() {
        temporaries = temporaries.push_back(accumulator);
        if (__is_zero(x[i]) == false) {
            accumulator = __mul::<_, MOD_BITS>(params, accumulator, x[i]);
        }
    }

    accumulator = __invmod::<_, MOD_BITS>(params, accumulator);
    let mut T0: [Field; N] = [0; N];
    for i in 0..x.len() {
        let idx = x.len() - 1 - i;
        if (__is_zero(x[idx]) == false) {
            T0 = __mul::<_, MOD_BITS>(params, accumulator, temporaries[idx]);
            accumulator = __mul::<_, MOD_BITS>(params, accumulator, x[idx]);
            result[idx] = T0;
        }
    }
    result
}

pub(crate) unconstrained fn __batch_invert_slice<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    x: [[Field; N]],
) -> [[Field; N]] {
    // TODO: ugly! Will fail if input slice is empty
    let mut accumulator: [Field; N] = __one::<N>();
    let mut result: [[Field; N]] = [[0; N]];
    let mut temporaries: [[Field; N]] = &[];
    for i in 0..x.len() {
        temporaries = temporaries.push_back(accumulator);
        if (__is_zero(x[i]) == false) {
            accumulator = __mul::<_, MOD_BITS>(params, accumulator, x[i]);
        }
        result = result.push_back([0; N]);
    }

    accumulator = __invmod::<_, MOD_BITS>(params, accumulator);
    let mut T0: [Field; N] = [0; N];
    for i in 0..x.len() {
        let idx = x.len() - 1 - i;
        if (__is_zero(x[idx]) == false) {
            T0 = __mul::<_, MOD_BITS>(params, accumulator, temporaries[idx]);
            accumulator = __mul::<_, MOD_BITS>(params, accumulator, x[idx]);
            result[idx] = T0;
        }
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
    params: P<N, MOD_BITS>,
    input: [Field; N],
) -> std::option::Option<[Field; N]> {
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
    let one_u60: U60Repr<N, 2> = unsafe { U60Repr::one() };
    let primitive_root_log_size = __primitive_root_log_size::<_, MOD_BITS>(params);
    let mut Q = (params.modulus_u60 - one_u60).shr(primitive_root_log_size - 1);
    let Q_minus_one_over_two_u60 = (Q - one_u60).shr(2);
    let Q_minus_one_over_two: [Field; N] = U60Repr::into(Q_minus_one_over_two_u60);
    let mut z = __multiplicative_generator::<_, MOD_BITS>(params); // the generator is a non-residue
    let mut b = __pow::<_, MOD_BITS>(params, input, Q_minus_one_over_two);
    let mut r = __mul::<_, MOD_BITS>(params, input, b);
    let mut t = __mul::<_, MOD_BITS>(params, r, b);
    let mut check: [Field; N] = t;
    for _ in 0..primitive_root_log_size - 1 {
        check = __mul::<_, MOD_BITS>(params, check, check);
    }
    let mut found_root = false;
    let one: [Field; N] = __one::<N>();
    if (__eq(check, one) == false) {} else {
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
                found_root = true;
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
    let result = if found_root {
        std::option::Option::some(r)
    } else {
        std::option::Option::none()
    };
    result
}
