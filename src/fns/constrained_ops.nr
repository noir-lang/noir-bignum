use crate::params::BigNumParams as P;

use crate::fns::{
    expressions::evaluate_quadratic_expression,
    unconstrained_helpers::{
        __add_with_flags, __neg_with_flags, __sub_with_flags, __validate_gt_remainder,
        __validate_in_field_compute_borrow_flags,
    }, unconstrained_ops::{__div, __mul, __udiv_mod},
};

/**
 * In this file:
 *
 * conditional_select
 * assert_is_not_equal
 * eq
 * validate_in_field
 * validate_in_range
 * validate_quotient_in_range
 * validate_gt
 * neg
 * add
 * sub
 * mul
 * div
 * udiv_mod
 * udiv
 * umod
 */

/**
* @brief given an input seed, generate a pseudorandom BigNum value
* @details we hash the input seed into `modulus_bits * 2` bits of entropy,
* which is then reduced into a BigNum value
* We use a hash function that can be modelled as a random oracle
* This function *should* produce an output that is a uniformly randomly distributed value modulo BigNum::modulus()
**/
pub(crate) fn derive_from_seed<let N: u32, let MOD_BITS: u32, let SeedBytes: u32>(
    params: P<N, MOD_BITS>,
    seed: [u8; SeedBytes],
) -> [Field; N] {
    let mut rolling_seed: [u8; SeedBytes + 1] = [0; SeedBytes + 1];
    for i in 0..SeedBytes {
        rolling_seed[i] = seed[i];
        assert_eq(rolling_seed[i], seed[i]);
    }

    let mut hash_buffer: [u8; N * 2 * 15] = [0; N * 2 * 15];

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

    let compressed =
        std::hash::poseidon2::Poseidon2::hash(rolling_hash_fields, (SeedBytes / 31) + 1);
    let mut rolling_hash: [Field; 2] = [compressed, 0];

    let num_hashes = (240 * N) / 254 + (((30 * N) % 32) != 0) as u32;
    for i in 0..num_hashes - 1 {
        let hash: Field = std::hash::poseidon2::Poseidon2::hash(rolling_hash, 2);
        let hash: [u8; 32] = hash.to_le_bytes();
        for j in 0..30 {
            hash_buffer[i * 30 + j] = hash[j];
        }
        rolling_hash[1] += 1;
    }

    {
        let hash: Field = std::hash::poseidon2::Poseidon2::hash(rolling_hash, 2);
        let hash: [u8; 32] = hash.to_le_bytes();
        let remaining_bytes = 30 * N - (num_hashes - 1) * 30;
        for j in 0..remaining_bytes {
            hash_buffer[(num_hashes - 1) * 30 + j] = hash[j];
        }
    }

    let num_bits = MOD_BITS * 2;
    let num_bytes = num_bits / 8 + ((num_bits % 8) != 0) as u32;

    let bits_in_last_byte = num_bits as u8 % 8;
    let last_byte_mask = (1 as u8 << bits_in_last_byte) - 1;
    hash_buffer[num_bytes - 1] = hash_buffer[num_bytes - 1] & last_byte_mask;

    let num_bigfield_chunks = (2 * N) / (N - 1) + (((2 * N) % (N - 1)) != 0) as u32;
    let mut byte_ptr = 0;

    // we want to convert our byte array into bigfield chunks
    // each chunk has at most N-1 limbs
    // to determine the exact number of chunks, we need the `!=` or `>` operator which is not avaiable when defining array sizes
    // so we overestimate at 4
    // e.g. if N = 20, then we have 40 limbs we want to reduce, but each bigfield chunk is 19 limbs, so we need 3
    // if N = 2, we have 4 limbs we want to reduce but each bigfield chunk is only 1 limb, so we need 4
    // max possible number of chunks is therefore 4
    let mut bigfield_chunks: [[Field; N]; 4] = [[0; N]; 4];
    for k in 0..num_bigfield_chunks {
        let mut bigfield_limbs: [Field; N] = [0; N];
        let mut num_filled_bytes = (k * 30);
        let mut num_remaining_bytes = num_bytes - num_filled_bytes;
        let mut num_remaining_limbs =
            (num_remaining_bytes / 15) + (num_remaining_bytes % 15 > 0) as u32;
        let mut more_than_N_minus_one_limbs = (num_remaining_limbs > (N - 1)) as u32;
        let mut num_limbs_in_bigfield = more_than_N_minus_one_limbs * (N - 1)
            + num_remaining_limbs * (1 - more_than_N_minus_one_limbs);

        for j in 0..num_limbs_in_bigfield {
            let mut limb: Field = 0;
            for _ in 0..15 {
                let need_more_bytes = (byte_ptr < num_bytes);
                let mut byte = hash_buffer[byte_ptr];
                limb *= (256 * need_more_bytes as Field + (1 - need_more_bytes as Field));
                limb += byte as Field * need_more_bytes as Field;
                byte_ptr += need_more_bytes as u32;
            }
            bigfield_limbs[num_limbs_in_bigfield - 1 - j] = limb;
        }
        bigfield_chunks[num_bigfield_chunks - 1 - k] = bigfield_limbs;
    }

    let mut bigfield_rhs_limbs: [Field; N] = [0; N];
    bigfield_rhs_limbs[N - 1] = 1;
    validate_in_range::<_, MOD_BITS>(bigfield_rhs_limbs);

    let mut result: [Field; N] = [0; N];

    for i in 0..num_bigfield_chunks {
        let bigfield_lhs_limbs = bigfield_chunks[i];

        result = mul(params, result, bigfield_rhs_limbs);
        result = add(params, result, bigfield_lhs_limbs);
    }
    result
}

/**
* @brief conditional_select given the value of `predicate` return either `self` (if 0) or `other` (if 1)
* @description should be cheaper than using an IF statement (TODO: check!)
**/
pub(crate) fn conditional_select<let N: u32>(
    lhs: [Field; N],
    rhs: [Field; N],
    predicate: bool,
) -> [Field; N] {
    let mut result: [Field; N] = lhs;
    for i in 0..N {
        result[i] = (lhs[i] - rhs[i]) * predicate as Field + rhs[i];
    }
    result
}

/**
    * @brief Validate self != other
    * @details If A == B, then A == B mod N.
    *          We can efficiently evaluate A == B mod N where N = circuit modulus
    *          This method is *sound*, but not *complete* (i.e. A != B but A == B mod N)
    *          However the probability of an honest Prover being unable to satisfy this check is tiny!
    *          (todo: compute how tiny)
    **/
pub(crate) fn assert_is_not_equal<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [Field; N],
    rhs: [Field; N],
) {
    let mut l: Field = 0;
    let mut r: Field = 0;
    let mut modulus_mod_n: Field = 0;
    let two_pow_120: Field = 0x1000000000000000000000000000000;
    let modulus = params.modulus;
    for i in 0..N {
        l *= two_pow_120;
        r *= two_pow_120;
        modulus_mod_n *= two_pow_120;
        l += lhs[N - i - 1];
        r += rhs[N - i - 1];
        modulus_mod_n += modulus[N - i - 1];
    }

    // lhs can be either X mod N or P + X mod N
    // rhs can be either Y mod N or P + Y mod N
    // If lhs - rhs = 0 mod P then lhs - rhs = 0, P or -P mod N
    let mut diff = l - r;
    let mut target = diff * (diff + modulus_mod_n) * (diff - modulus_mod_n);
    assert(target != 0, "asssert_is_not_equal fail");
}

pub(crate) fn eq<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [Field; N],
    rhs: [Field; N],
) -> bool {
    let diff = sub::<_, MOD_BITS>(params, lhs, rhs);
    // if self == other, possible values of `diff` will be `p` or `0`
    // (the subtract operator constrains diff to be < ceil(log(p)))
    // TODO: can do this more efficiently via witngen in unconstrained functions?
    let mut is_equal_modulus: bool = true;
    let mut is_equal_zero: bool = true;
    for i in 0..N {
        is_equal_modulus = is_equal_modulus & (diff[i] == params.modulus[i]);
        is_equal_zero = is_equal_zero & (diff[i] == 0);
    }
    is_equal_modulus | is_equal_zero
}

pub(crate) fn validate_in_field<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    val: [Field; N],
) {
    // N.B. need to combine with validate_in_range if `self` limbs have not been range constrained
    let mut p_minus_self: [Field; N] = [0; N];
    let modulus: [Field; N] = params.modulus;
    for i in 0..N {
        p_minus_self[i] = modulus[i] - val[i];
    }
    let borrow_flags = unsafe { __validate_in_field_compute_borrow_flags(params, val) };
    let two_pow_120: Field = 0x1000000000000000000000000000000;
    p_minus_self[0] += borrow_flags[0] as Field * two_pow_120;
    for i in 1..N - 1 {
        p_minus_self[i] += (borrow_flags[i] as Field * two_pow_120 - borrow_flags[i - 1] as Field);
    }
    p_minus_self[N - 1] -= borrow_flags[N - 2] as Field;
    let mut compare = val;
    compare = p_minus_self;
    validate_in_range::<_, MOD_BITS>(compare);
}

/**
* @brief Validate a BigNum instance is correctly range constrained to contain no more than Params::modulus_bits()
**/
pub(crate) fn validate_in_range<let N: u32, let MOD_BITS: u32>(limbs: [Field; N]) {
    for i in 0..(N - 1) {
        limbs[i].assert_max_bit_size::<120>();
    }
    limbs[N - 1].assert_max_bit_size::<MOD_BITS - ((N - 1) * 120)>();
}

/**
* @brief validate quotient produced from `evaluate_quadratic_expression` is well-formed
* @description because the inputs into evaluate_quadratic_expression may cause the quotient to extend beyond `Params::modulus_bits`.
*              We allow the quotient to extend 6 bits beyond Params::modulus_bits()
*              Why is this?
*              several factors:    1. quotient * modulus , limbs cannot overflow field boundary (254 bits)
*                                  2. in `evaluate_quadratic_expression`, we require that for `expression - quotient * modulus`,
*                                     limbs cannot exceed 246 bits (246 magic number due to a higher number adding extra range check gates)
*              because of factor 2 and the fact that modulus limbs are 120 bits, quotient limbs cannot be >126 bits
*
*              Note: doesn't this mean that final_limb_bits should be constrained to be 126 bits, not modulus_bits() - ((N - 1) * 120) + 6?
*              TODO: think about this more! we want the range constraint we apply to be as small as allowable as this is more efficient
**/
pub(crate) fn validate_quotient_in_range<let N: u32, let MOD_BITS: u32>(limbs: [Field; N]) {
    for i in 0..(N) {
        limbs[i].assert_max_bit_size::<120>();
    }
    // Note: replace magic number 6 with definition
    limbs[N - 1].assert_max_bit_size::<MOD_BITS - ((N - 1) * 120) + 6>();
}

// validate that lhs - rhs does not underflow i.e. lhs > rhs
pub(crate) fn validate_gt<let N: u32, let MOD_BITS: u32>(lhs: [Field; N], rhs: [Field; N]) {
    // so we do... p - x - r = 0 and there might be borrow flags
    // a - b = r
    // p + a - b - r = 0
    let (result, carry_flags, borrow_flags) = unsafe { __validate_gt_remainder(lhs, rhs) };
    validate_in_range::<_, MOD_BITS>(result);

    let borrow_shift = 0x1000000000000000000000000000000;
    let carry_shift = 0x1000000000000000000000000000000;

    let mut addend: [Field; N] = [0; N];
    let result_limb = lhs[0] - rhs[0] + addend[0] - result[0] - 1
        + (borrow_flags[0] as Field * borrow_shift)
        - (carry_flags[0] as Field * carry_shift);
    assert(result_limb == 0);

    for i in 1..N - 1 {
        let result_limb = lhs[i] - rhs[i] + addend[i] - result[i] - borrow_flags[i - 1] as Field
            + carry_flags[i - 1] as Field
            + ((borrow_flags[i] as Field - carry_flags[i] as Field) * borrow_shift);
        assert(result_limb == 0);
    }

    let result_limb = lhs[N - 1] - rhs[N - 1] + addend[N - 1]
        - result[N - 1]
        - borrow_flags[N - 2] as Field
        + carry_flags[N - 2] as Field;
    assert(result_limb == 0);
}

pub(crate) fn neg<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    val: [Field; N],
) -> [Field; N] {
    // so we do... p - x - r = 0 and there might be borrow flags
    let (result, borrow_flags) = unsafe { __neg_with_flags(params, val) };
    validate_in_range::<_, MOD_BITS>(result);
    let modulus = params.modulus;
    let borrow_shift = 0x1000000000000000000000000000000;
    let result_limb = modulus[0] - val[0] - result[0] + (borrow_flags[0] as Field * borrow_shift);
    assert(result_limb == 0);
    for i in 1..N - 1 {
        let result_limb = modulus[i] - val[i] - result[i] - borrow_flags[i - 1] as Field
            + (borrow_flags[i] as Field * borrow_shift);
        assert(result_limb == 0);
    }
    let result_limb = modulus[N - 1] - val[N - 1] - result[N - 1] - borrow_flags[N - 2] as Field;
    assert(result_limb == 0);
    result
}

pub(crate) fn add<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [Field; N],
    rhs: [Field; N],
) -> [Field; N] {
    // so we do... p - x - r = 0 and there might be borrow flags
    let (result, carry_flags, borrow_flags, overflow_modulus) =
        unsafe { __add_with_flags(params, lhs, rhs) };
    validate_in_range::<_, MOD_BITS>(result);
    let modulus = params.modulus;
    let borrow_shift = 0x1000000000000000000000000000000;
    let carry_shift = 0x1000000000000000000000000000000;

    let mut subtrahend: [Field; N] = [0; N];
    if (overflow_modulus) {
        subtrahend = modulus;
    }
    let result_limb = lhs[0] + rhs[0] - subtrahend[0] - result[0]
        + (borrow_flags[0] as Field * borrow_shift)
        - (carry_flags[0] as Field * carry_shift);
    assert(result_limb == 0);
    for i in 1..N - 1 {
        let result_limb = lhs[i] + rhs[i] - subtrahend[i] - result[i] - borrow_flags[i - 1] as Field
            + carry_flags[i - 1] as Field
            + ((borrow_flags[i] as Field - carry_flags[i] as Field) * borrow_shift);
        assert(result_limb == 0);
    }
    let result_limb = lhs[N - 1] + rhs[N - 1]
        - subtrahend[N - 1]
        - result[N - 1]
        - borrow_flags[N - 2] as Field
        + carry_flags[N - 2] as Field;
    assert(result_limb == 0);
    result
}

pub(crate) fn sub<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [Field; N],
    rhs: [Field; N],
) -> [Field; N] {
    // so we do... p - x - r = 0 and there might be borrow flags
    // a - b = r
    // p + a - b - r = 0
    let (result, carry_flags, borrow_flags, underflow) =
        unsafe { __sub_with_flags(params, lhs, rhs) };
    validate_in_range::<_, MOD_BITS>(result);
    let modulus = params.modulus;
    let borrow_shift = 0x1000000000000000000000000000000;
    let carry_shift = 0x1000000000000000000000000000000;

    let mut addend: [Field; N] = [0; N];
    if (underflow) {
        addend = modulus;
    }
    let result_limb = lhs[0] - rhs[0] + addend[0] - result[0]
        + (borrow_flags[0] as Field * borrow_shift)
        - (carry_flags[0] as Field * carry_shift);
    assert(result_limb == 0);
    for i in 1..N - 1 {
        let result_limb = lhs[i] - rhs[i] + addend[i] - result[i] - borrow_flags[i - 1] as Field
            + carry_flags[i - 1] as Field
            + ((borrow_flags[i] as Field - carry_flags[i] as Field) * borrow_shift);
        assert(result_limb == 0);
    }
    let result_limb = lhs[N - 1] - rhs[N - 1] + addend[N - 1]
        - result[N - 1]
        - borrow_flags[N - 2] as Field
        + carry_flags[N - 2] as Field;
    assert(result_limb == 0);
    result
}

// Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
//       via evaluate_quadratic_expression
// e.g. performing a sum of multiple multiplications and additions via `evaluate_quadratic_expression`
//      will create much fewer constraints than calling `mul` and `add` directly
pub(crate) fn mul<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [Field; N],
    rhs: [Field; N],
) -> [Field; N] {
    let result = unsafe { __mul::<_, MOD_BITS>(params, lhs, rhs) };
    evaluate_quadratic_expression(
        params,
        [[lhs]],
        [[false]],
        [[rhs]],
        [[false]],
        [result],
        [true],
    );
    result
}

// Note: this method is expensive! Witness computation is extremely expensive as it requires modular exponentiation
pub(crate) fn div<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [Field; N],
    rhs: [Field; N],
) -> [Field; N] {
    assert(
        params.has_multiplicative_inverse,
        "BigNum has no multiplicative inverse. Use udiv for unsigned integer division",
    );
    let result = unsafe { __div::<_, MOD_BITS>(params, lhs, rhs) };
    evaluate_quadratic_expression(
        params,
        [[result]],
        [[false]],
        [[rhs]],
        [[false]],
        [lhs],
        [true],
    );
    result
}

/**
* @brief udiv_mod performs integer division between numerator, divisor 
*
* i.e. 1. floor(numerator / divisor) = quotient
*      2. numerator % divisor = remainder
*      3. divisor * quotient + remainder = numerator
**/
pub(crate) fn udiv_mod<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    numerator: [Field; N],
    divisor: [Field; N],
) -> ([Field; N], [Field; N]) {
    let (quotient, remainder) = unsafe { __udiv_mod(numerator, divisor) };

    // self / divisor = quotient rounded
    // quotient * divisor + remainder - self = 0
    evaluate_quadratic_expression(
        params,
        [[quotient]],
        [[false]],
        [[divisor]],
        [[false]],
        [numerator, remainder],
        [true, false],
    );
    // we need (remainder < divisor)
    // implies (divisor - remainder > 0)
    validate_gt::<_, MOD_BITS>(divisor, remainder);
    (quotient, remainder)
}

/**
* @brief udiv_mod performs integer division between numerator, divisor 
*
* i.e. return param is floor(numerator / divisor)
**/
pub(crate) fn udiv<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    numerator: [Field; N],
    divisor: [Field; N],
) -> [Field; N] {
    udiv_mod::<_, MOD_BITS>(params, numerator, divisor).0
}

/**
* @brief udiv_mod performs integer modular reduction
*
* i.e. 1. numerator % divisor = return value
**/
pub(crate) fn umod<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    numerator: [Field; N],
    divisor: [Field; N],
) -> [Field; N] {
    udiv_mod::<_, MOD_BITS>(params, numerator, divisor).1
}

