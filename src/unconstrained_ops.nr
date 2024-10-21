use crate::utils::u60_representation::U60Repr;
use crate::utils::split_bits;

use crate::params::BigNumParams as P;
use crate::unconstrained_helpers::__barrett_reduction;

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

unconstrained pub(crate) fn __one<let N: u32>() -> [Field; N] {
    let mut limbs: [Field; N] = [0; N];
    limbs[0] = 1;
    limbs
}

unconstrained pub(crate) fn __derive_from_seed<let N: u32, let SeedBytes: u32>(params: P<N>, seed: [u8; SeedBytes]) -> [Field; N] {
    let mut rolling_hash_fields: [Field; (SeedBytes / 31) + 1] = [0; (SeedBytes / 31) + 1];
    let mut seed_ptr = 0;
    for i in 0..(SeedBytes / 31) + 1 {
        let mut packed: Field = 0;
        for _ in 0..31 {
            if (seed_ptr < SeedBytes) {
                packed *= 256;
                packed += seed[seed_ptr] as Field;
                seed_ptr += 1;
            }
        }
        rolling_hash_fields[i] = packed;
    }
    let compressed = std::hash::poseidon2::Poseidon2::hash(rolling_hash_fields, (SeedBytes / 31) + 1);
    let mut rolling_hash: [Field; 2] = [compressed, 0];

    let mut to_reduce: [Field; 2 * N] = [0; 2 * N];

    let modulus_bits_getter = params.modulus_bits_getter;
    let modulus_bits = modulus_bits_getter();
    let mut double_modulus_bits = modulus_bits * 2;
    let mut double_modulus_bytes = (double_modulus_bits) / 8 + (double_modulus_bits % 8 != 0) as u32;

    let mut last_limb_bytes = double_modulus_bytes % 15;
    if (last_limb_bytes == 0) {
        last_limb_bytes = 15;
    }
    let mut last_limb_bits = double_modulus_bits % 8;
    if (last_limb_bits == 0) {
        last_limb_bits = 8;
    }

    for i in 0..(N - 1) {
        let hash = std::hash::poseidon2::Poseidon2::hash(rolling_hash, 2);
        let hash : [u8; 30] = hash.to_le_bytes();
        let mut lo: Field = 0;
        let mut hi: Field = 0;
        for j in 0..15 {
            hi *= 256;
            lo *= 256;

            if (i < 2 * N - 2) {
                lo += hash[j + 15] as Field;
                hi += hash[j] as Field;
            }
        }
        to_reduce[2 * i] = lo;
        to_reduce[2 * i + 1] = hi;
        rolling_hash[1] += 1;
    }

    {
        let hash = std::hash::poseidon2::Poseidon2::hash(rolling_hash, 2);
        let hash : [u8; 30] = hash.to_le_bytes();
        let mut hi: Field = 0;
        for j in 0..(last_limb_bytes - 1) {
            hi *= 256;
            hi += hash[j] as Field;
        }
        hi *= 256;
        let last_byte = hash[last_limb_bytes - 1];
        let mask = (1 as u64 << (last_limb_bits) as u8) - 1;
        let last_bits = last_byte as u64 & mask;
        hi += last_bits as Field;
        to_reduce[2 * N - 2] = hi;
    }
    let modulus_bits_getter = params.modulus_bits_getter;
    let modulus_bits = modulus_bits_getter();
    let (_, remainder) = __barrett_reduction(
        to_reduce,
        params.redc_param,
        modulus_bits,
        params.modulus,
        params.modulus_u60_x4
    );
    let result = remainder;
    result
}

unconstrained pub(crate) fn __eq<let N: u32>(lhs: [Field; N], rhs: [Field; N]) -> bool {
    lhs == rhs
}

unconstrained pub(crate) fn __is_zero<let N: u32>(limbs: [Field; N]) -> bool {
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
unconstrained pub(crate) fn __neg<let N: u32>(params: P<N>, limbs: [Field; N]) -> [Field; N] {
    let f: [Field; N] = limbs;
    let x_u60 : U60Repr<N, 2> = U60Repr::from(f);
    U60Repr::into(params.modulus_u60 - x_u60)
}

unconstrained pub(crate) fn __add<let N: u32>(
    params: P<N>,
    lhs: [Field; N],
    rhs: [Field; N]
) -> [Field; N] {
    let x_u60 : U60Repr<N, 2> = U60Repr::from(lhs);
    let y_u60 : U60Repr<N, 2> = U60Repr::from(rhs);

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
unconstrained pub(crate) fn __sub<let N: u32>(params: P<N>, lhs: [Field; N], rhs: [Field; N]) -> [Field; N] {
    __add(params, lhs, __neg(params, rhs))
}

unconstrained pub(crate) fn __mul_with_quotient<let N: u32>(params: P<N>, lhs: [Field; N], rhs: [Field; N]) -> ([Field; N], [Field; N]) {
    let mut mul: [Field; 2 * N] = [0; 2 * N];
    for i in 0..N {
        for j in 0..N {
            mul[i + j] += lhs[i] * rhs[j];
        }
    }
    let to_reduce = split_bits::__normalize_limbs(mul, 2 * N);
    let modulus_bits_getter = params.modulus_bits_getter;
    let modulus_bits = modulus_bits_getter();
    let (q, r) = __barrett_reduction(
        to_reduce,
        params.redc_param,
        modulus_bits,
        params.modulus,
        params.modulus_u60_x4
    );

    (q, r)
}

unconstrained pub(crate) fn __mul<let N: u32>(
    params: P<N>,
    lhs: [Field; N],
    rhs: [Field; N]
) -> [Field; N] {
    let (_, b) = __mul_with_quotient(params, lhs, rhs);
    b
}

unconstrained pub(crate) fn __div<let N: u32>(
    params: P<N>,
    numerator: [Field; N],
    divisor: [Field; N]
) -> [Field; N] {
    let inv_divisor = __invmod(params, divisor);
    __mul(params, numerator, inv_divisor)
}

/**
* @brief __udiv_mod performs *unconstrained* integer division between numerator, divisor 
*
* i.e. 1. floor(numerator / divisor) = quotient
*      2. numerator % divisor = remainder
*      3. divisor * quotient + remainder = numerator
**/
unconstrained pub(crate) fn __udiv_mod<let N: u32>(numerator: [Field; N], divisor: [Field; N]) -> ([Field; N], [Field; N]) {
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

unconstrained pub(crate) fn __invmod<let N: u32>(params: P<N>, val: [Field; N]) -> [Field; N] {
    let one: [Field; N] = __one::<N>();
    let one_u60: U60Repr<N, 2> = U60Repr::from(one);
    let exp_u60 = params.modulus_u60.sub(one_u60.add(one_u60));
    let exp = U60Repr::into(exp_u60);
    __pow(params, val, exp)
}

unconstrained pub(crate) fn __pow<let N: u32>(
    params: P<N>,
    val: [Field; N],
    exponent: [Field; N]
) -> [Field; N] {
    let x: U60Repr<N, 2> = U60Repr::from(exponent);

    let modulus_bits_getter = params.modulus_bits_getter;
    let modulus_bits = modulus_bits_getter();
    let num_bits = modulus_bits + 1;

    let mut accumulator: [Field; N] = __one::<N>();

    for i in 0..num_bits {
        accumulator = __mul(params, accumulator, accumulator);
        if x.get_bit(num_bits - i - 1) {
            accumulator = __mul(params, accumulator, val);
        }
    }
    accumulator
}

unconstrained pub(crate) fn __batch_invert<let N: u32, let M: u32>(params: P<N>, x: [[Field; N]; M]) -> [[Field; N]; M] {
    // TODO: ugly! Will fail if input slice is empty
    let mut accumulator: [Field; N] = __one::<N>();
    let mut result: [[Field; N]; M] = [[0; N]; M];
    let mut temporaries: [[Field; N]] = &[];
    for i in 0..x.len() {
        temporaries = temporaries.push_back(accumulator);
        if (__is_zero(x[i]) == false) {
            accumulator = __mul(params, accumulator, x[i]);
        }
    }

    accumulator = __invmod(params, accumulator);
    let mut T0: [Field; N] = [0; N];
    for i in 0..x.len() {
        let idx = x.len() - 1 - i;
        if (__is_zero(x[idx]) == false) {
            T0 = __mul(params, accumulator, temporaries[idx]);
            accumulator = __mul(params, accumulator, x[idx]);
            result[idx] = T0;
        }
    }
    result
}

unconstrained pub(crate) fn __batch_invert_slice<let N: u32>(params: P<N>, x: [[Field; N]]) -> [[Field; N]] {
    // TODO: ugly! Will fail if input slice is empty
    let mut accumulator: [Field; N] = __one::<N>();
    let mut result: [[Field; N]] = [[0; N]];
    let mut temporaries: [[Field; N]] = &[];
    for i in 0..x.len() {
        temporaries = temporaries.push_back(accumulator);
        if (__is_zero(x[i]) == false) {
            accumulator = __mul(params, accumulator, x[i]);
        }
        result = result.push_back([0; N]);
    }

    accumulator = __invmod(params, accumulator);
    let mut T0: [Field; N] = [0; N];
    for i in 0..x.len() {
        let idx = x.len() - 1 - i;
        if (__is_zero(x[idx]) == false) {
            T0 = __mul(params, accumulator, temporaries[idx]);
            accumulator = __mul(params, accumulator, x[idx]);
            result[idx] = T0;
        }
    }
    result
}
