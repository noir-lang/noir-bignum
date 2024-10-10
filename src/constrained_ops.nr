use crate::params::BigNumParams as P;

use crate::unconstrained_helpers::{
    __validate_in_field_compute_borrow_flags, __validate_gt_remainder, __neg_with_flags,
    __add_with_flags, __sub_with_flags
};
use crate::unconstrained_ops::{__mul, __div, __udiv_mod};
use crate::expressions::evaluate_quadratic_expression;

/**
* @brief conditional_select given the value of `predicate` return either `self` (if 0) or `other` (if 1)
* @description should be cheaper than using an IF statement (TODO: check!)
**/
pub(crate) fn conditional_select<let N: u32>(lhs: [Field; N], rhs: [Field; N], predicate: bool) -> [Field; N] {
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
pub(crate) fn assert_is_not_equal<let N: u32, let MOD: u32>(params: P<N, MOD>, lhs: [Field; N], rhs: [Field; N]) {
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
        r += rhs[N - i - 1] ;
        modulus_mod_n += modulus[N - i - 1];
    }

    // lhs can be either X mod N or P + X mod N
    // rhs can be either Y mod N or P + Y mod N
    // If lhs - rhs = 0 mod P then lhs - rhs = 0, P or -P mod N
    let mut diff = l - r;
    let mut target = diff * (diff + modulus_mod_n) * (diff - modulus_mod_n);
    assert(target != 0, "asssert_is_not_equal fail");
}

pub(crate) fn eq<let N: u32, let MOD: u32>(
    params: P<N, MOD>,
    lhs: [Field; N],
    rhs: [Field; N]
) -> bool {
    let diff = sub::<_, MOD>(params, lhs, rhs);
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

pub(crate) fn validate_in_field<let N: u32, let MOD: u32>(params: P<N, MOD>, val: [Field; N]) {
    // N.B. need to combine with validate_in_range if `self` limbs have not been range constrained
    let mut p_minus_self: [Field; N] = [0; N];
    let modulus: [Field; N] = params.modulus;
    for i in 0..N {
        p_minus_self[i] = modulus[i] - val[i];
    }
    let borrow_flags = unsafe {
        __validate_in_field_compute_borrow_flags(params, val)
    };
    let two_pow_120: Field = 0x1000000000000000000000000000000;
    p_minus_self[0] += borrow_flags[0] as Field * two_pow_120;
    for i in 1..N - 1 {
        p_minus_self[i] += (borrow_flags[i] as Field * two_pow_120 - borrow_flags[i-1] as Field);
    }
    p_minus_self[N - 1] -= borrow_flags[N - 2] as Field;
    let mut compare = val;
    compare = p_minus_self;
    validate_in_range::<_, MOD>(compare);
}

/**
* @brief Validate a BigNum instance is correctly range constrained to contain no more than MOD::modulus_bits()
**/
pub(crate) fn validate_in_range<let N: u32, let MOD: u32>(limbs: [Field; N]) {
    for i in 0..(N - 1) {
        limbs[i].assert_max_bit_size(120);
    }
    let modulus_bits = MOD;
    let final_limb_bits = modulus_bits - ((N - 1) * 120);
    limbs[N - 1].assert_max_bit_size(final_limb_bits as u32);
}

/**
* @brief validate quotient produced from `evaluate_quadratic_expression` is well-formed
* @description because the inputs into evaluate_quadratic_expression may cause the quotient to extend beyond `MOD::modulus_bits`.
*              We allow the quotient to extend 6 bits beyond MOD::modulus_bits()
*              Why is this?
*              several factors:    1. quotient * modulus , limbs cannot overflow field boundary (254 bits)
*                                  2. in `evaluate_quadratic_expression`, we require that for `expression - quotient * modulus`,
*                                     limbs cannot exceed 246 bits (246 magic number due to a higher number adding extra range check gates)
*              because of factor 2 and the fact that modulus limbs are 120 bits, quotient limbs cannot be >126 bits
*
*              Note: doesn't this mean that final_limb_bits should be constrained to be 126 bits, not modulus_bits() - ((N - 1) * 120) + 6?
*              TODO: think about this more! we want the range constraint we apply to be as small as allowable as this is more efficient
**/
pub(crate) fn validate_quotient_in_range<let N: u32, let MOD: u32>(limbs: [Field; N]) {
    for i in 0..(N) {
        limbs[i].assert_max_bit_size(120);
    }
    // Note: replace magic number 6 with definition
    let modulus_bits = MOD;
    let final_limb_bits = modulus_bits - ((N - 1) * 120) + 6;
    limbs[N - 1].assert_max_bit_size(final_limb_bits as u32);
}

// validate that lhs - rhs does not underflow i.e. lhs > rhs
pub(crate) fn validate_gt<let N: u32, let MOD: u32>(lhs: [Field; N], rhs: [Field; N]) {
    // so we do... p - x - r = 0 and there might be borrow flags

    // a - b = r
    // p + a - b - r = 0
    let (result, carry_flags, borrow_flags) = unsafe {
        __validate_gt_remainder(lhs, rhs)
    };

    validate_in_range::<_, MOD>(result);

    let borrow_shift = 0x1000000000000000000000000000000;
    let carry_shift = 0x1000000000000000000000000000000;

    let mut addend: [Field; N] = [0; N];
    let result_limb = lhs[0] - rhs[0] + addend[0] - result[0] - 1 + (borrow_flags[0] as Field * borrow_shift)
        - (carry_flags[0] as Field * carry_shift);
    assert(result_limb == 0);
    for i in 1..N - 1 {
        let result_limb = lhs[i] - rhs[i] + addend[i] - result[i] - borrow_flags[i - 1] as Field
            + carry_flags[i - 1] as Field
            + ((borrow_flags[i] as Field - carry_flags[i] as Field) * borrow_shift);
        assert(result_limb == 0);
    }
    let result_limb = lhs[N - 1] - rhs[N - 1] + addend[N - 1] - result[N - 1] - borrow_flags[N - 2] as Field
        + carry_flags[N - 2] as Field;
    assert(result_limb == 0);
}

pub(crate) fn neg<let N: u32, let MOD: u32>(
    params: P<N, MOD>,
    val: [Field; N]
) -> [Field; N] {
    // so we do... p - x - r = 0 and there might be borrow flags
    let (result, borrow_flags) = unsafe {
        __neg_with_flags(params, val)
    };
    validate_in_range::<_, MOD>(result);
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

pub(crate) fn add<let N: u32, let MOD: u32>(
    params: P<N, MOD>,
    lhs: [Field; N],
    rhs: [Field; N]
) -> [Field; N] {
    // so we do... p - x - r = 0 and there might be borrow flags
    let (result, carry_flags, borrow_flags, overflow_modulus) = unsafe {
        __add_with_flags(params, lhs, rhs)
    };
    validate_in_range::<_, MOD>(result);
    let modulus = params.modulus;
    let borrow_shift = 0x1000000000000000000000000000000;
    let carry_shift = 0x1000000000000000000000000000000;

    let mut subtrahend: [Field; N] = [0; N];
    if (overflow_modulus) {
        subtrahend = modulus;
    }
    let result_limb = lhs[0] + rhs[0] - subtrahend[0] - result[0] + (borrow_flags[0] as Field * borrow_shift)
        - (carry_flags[0] as Field * carry_shift);
    assert(result_limb == 0);
    for i in 1..N - 1 {
        let result_limb = lhs[i] + rhs[i] - subtrahend[i] - result[i] - borrow_flags[i - 1] as Field
            + carry_flags[i - 1] as Field
            + ((borrow_flags[i] as Field - carry_flags[i] as Field) * borrow_shift);
        assert(result_limb == 0);
    }
    let result_limb = lhs[N - 1] + rhs[N - 1] - subtrahend[N - 1] - result[N - 1] - borrow_flags[N - 2] as Field
        + carry_flags[N - 2] as Field;
    assert(result_limb == 0);
    result
}

pub(crate) fn sub<let N: u32, let MOD: u32>(
    params: P<N, MOD>,
    lhs: [Field; N],
    rhs: [Field; N]
) -> [Field; N] {
    // so we do... p - x - r = 0 and there might be borrow flags

    // a - b = r
    // p + a - b - r = 0
    let (result, carry_flags, borrow_flags, underflow) = unsafe {
        __sub_with_flags(params, lhs, rhs)
    };
    validate_in_range::<_, MOD>(result);
    let modulus = params.modulus;
    let borrow_shift = 0x1000000000000000000000000000000;
    let carry_shift = 0x1000000000000000000000000000000;

    let mut addend: [Field; N] = [0; N];
    if (underflow) {
        addend = modulus;
    }
    let result_limb = lhs[0] - rhs[0] + addend[0] - result[0] + (borrow_flags[0] as Field * borrow_shift)
        - (carry_flags[0] as Field * carry_shift);
    assert(result_limb == 0);
    for i in 1..N - 1 {
        let result_limb = lhs[i] - rhs[i] + addend[i] - result[i] - borrow_flags[i - 1] as Field
            + carry_flags[i - 1] as Field
            + ((borrow_flags[i] as Field - carry_flags[i] as Field) * borrow_shift);
        assert(result_limb == 0);
    }
    let result_limb = lhs[N - 1] - rhs[N - 1] + addend[N - 1] - result[N - 1] - borrow_flags[N - 2] as Field
        + carry_flags[N - 2] as Field;
    assert(result_limb == 0);
    result
}

// Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
//       via evaluate_quadratic_expression
// e.g. performing a sum of multiple multiplications and additions via `evaluate_quadratic_expression`
//      will create much fewer constraints than calling `mul` and `add` directly
pub(crate) fn mul<let N: u32, let MOD: u32>(
    params: P<N, MOD>,
    lhs: [Field; N],
    rhs: [Field; N]
) -> [Field; N] {
    let result = unsafe {
        __mul::<_, MOD>(params, lhs, rhs)
    };
    evaluate_quadratic_expression::<_, MOD, _, _, _, _>(params, [[lhs]], [[false]], [[rhs]], [[false]], [result], [true]);
    result
}

// Note: this method is expensive! Witness computation is extremely expensive as it requires modular exponentiation
pub(crate) fn div<let N: u32, let MOD: u32>(
    params: P<N, MOD>,
    lhs: [Field; N],
    rhs: [Field; N]
) -> [Field; N] {
    assert(
        params.has_multiplicative_inverse, "BigNum has no multiplicative inverse. Use udiv for unsigned integer division"
    );
    let result = unsafe {
        __div::<_, MOD>(params, lhs, rhs)
    };
    evaluate_quadratic_expression::<_, MOD, _, _, _, _>(params, [[result]], [[false]], [[rhs]], [[false]], [lhs], [true]);
    result
}

/**
* @brief udiv_mod performs integer division between numerator, divisor 
*
* i.e. 1. floor(numerator / divisor) = quotient
*      2. numerator % divisor = remainder
*      3. divisor * quotient + remainder = numerator
**/
pub(crate) fn udiv_mod<let N: u32, let MOD: u32>(
    params: P<N, MOD>,
    numerator: [Field; N],
    divisor: [Field; N]
) -> ([Field; N], [Field; N]) {
    let (quotient, remainder) = unsafe {
        __udiv_mod(numerator, divisor)
    };

    // self / divisor = quotient rounded
    // quotient * divisor + remainder - self = 0
    evaluate_quadratic_expression::<_, MOD, _, _, _, _>(
        params,
        [[quotient]],
        [[false]],
        [[divisor]],
        [[false]],
        [numerator, remainder],
        [true, false]
    );
    // we need (remainder < divisor)
    // implies (divisor - remainder > 0)
    validate_gt::<_, MOD>(divisor, remainder);
    (quotient, remainder)
}

/**
* @brief udiv_mod performs integer division between numerator, divisor 
*
* i.e. return param is floor(numerator / divisor)
**/
pub(crate) fn udiv<let N: u32, let MOD: u32>(
    params: P<N, MOD>,
    numerator: [Field; N],
    divisor: [Field; N]
) -> [Field; N] {
    udiv_mod::<_, MOD>(params, numerator, divisor).0
}

/**
* @brief udiv_mod performs integer modular reduction
*
* i.e. 1. numerator % divisor = return value
**/
pub(crate) fn umod<let N: u32, let MOD: u32>(
    params: P<N, MOD>,
    numerator: [Field; N],
    divisor: [Field; N]
) -> [Field; N] {
    udiv_mod::<_, MOD>(params, numerator, divisor).1
}

