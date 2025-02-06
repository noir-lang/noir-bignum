use crate::utils::split_bits;
use crate::utils::u60_representation::U60Repr;

use crate::fns::unconstrained_ops::{__add, __gte, __mul, __neg, __one, __pow};
use crate::params::BigNumParams as P;

global TWO_POW_60: u128 = 0x1000000000000000;
global TWO_POW_119: u128 = 0x800000000000000000000000000000;
global TWO_POW_120: u128 = 0x1000000000000000000000000000000;

/**
 * In this file:
 *
 * __validate_in_field_compute_borrow_flags
 * __validate_gt_remainder
 * __neg_with_flags
 * __add_with_flags
 * __sub_with_flags
 * __barrett_reduction
 * __tonelli_shanks_sqrt
 */

// pub(crate) unconstrained fn __from_field<let N: u32>(field: Field) -> [Field; N] {
//     // cast the field to a u60 representation
//     let res_u60: U60Repr<N, 2> = U60Repr::from_field(field);
//     let result: [Field; N] = U60Repr::into(res_u60);
//     result
// }

pub(crate) unconstrained fn __from_field<let N: u32>(field: Field) -> [u128; N] {
    let mut x = field;
    let x_first_u128 = (x as u128);
    let first: u128 = x_first_u128 % TWO_POW_120;
    // this becomes the same as a integer division because we're removing the remainder
    x = (x - (first as Field)) / (TWO_POW_120 as Field);
    let x_second_u128 = (x as u128);
    let second = x_second_u128 % TWO_POW_120;
    x = (x - (second as Field)) / (TWO_POW_120 as Field);
    let x_third_u128 = (x as u128);
    let third = x_third_u128 % TWO_POW_120;
    let mut result: [u128; N] = [0; N];
    if N > 2 {
        result[0] = first;
        result[1] = second;
        result[2] = third;
    }
    if N == 2 {
        result[0] = first;
        result[1] = second;
    }
    if N == 1 {
        result[0] = first;
    }
    result
}

pub(crate) unconstrained fn __validate_in_field_compute_borrow_flags<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    val: [u128; N],
) -> [bool; N] {
    let mut flags: [bool; N] = [false; N];
    let modulus: [u128; N] = params.modulus;
    flags[0] = modulus[0] < val[0];
    for i in 1..N - 1 {
        flags[i] = modulus[i] < val[i] + flags[i - 1] as u128;
    }
    flags
}

pub(crate) unconstrained fn __validate_gt_remainder<let N: u32>(
    lhs: [u128; N],
    rhs: [u128; N],
) -> ([u128; N], [bool; N], [bool; N]) {
    // let a_u60: U60Repr<N, 2> = From::from(lhs);
    // let mut b_u60: U60Repr<N, 2> = From::from(rhs);

    // let underflow = b_u60.gte(a_u60);
    let underflow = __gte(rhs, lhs);
    // b_u60 += U60Repr::one();
    // add one to the rhs
    let mut one = [0; N];
    one[0] = 1;
    //fix this in a sec
    let rhs: [u128; N] = __increment(rhs);
    assert(underflow == false, "BigNum::validate_gt check fails");
    // let mut result_u60: U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };
    let mut result: [u128; N] = [0; N];
    let mut carry_in: u128 = 0;
    let mut borrow_in: u128 = 0;
    let mut borrow_flags: [bool; N] = [false; N];
    let mut carry_flags: [bool; N] = [false; N];
    for i in 0..2 * N {
        let mut add_term: u128 = rhs[i] + carry_in as u128;
        let mut carry = (add_term >= TWO_POW_120) as u128;
        add_term -= carry * TWO_POW_120;
        carry_in = carry;

        let sub_term = rhs[i] + borrow_in;
        let mut borrow = (sub_term > add_term) as u128;
        result[i] = borrow * TWO_POW_60 + add_term - sub_term;

        borrow_in = borrow;

        if ((i & 1) == 1) {
            // Only set `borrow` and `carry` if they differ
            if (carry != borrow) {
                carry_flags[i / 2] = carry as bool;
                borrow_flags[i / 2] = borrow as bool;
            }
        }
    }
    // let result = U60Repr::into(result_u60);
    (result, carry_flags, borrow_flags)
}

pub(crate) unconstrained fn __neg_with_flags<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    val: [u128; N],
) -> ([u128; N], [bool; N]) {
    let mut result: [u128; N] = [0; N];
    let mut borrow_in: u128 = 0;

    let mut borrow_flags: [bool; N] = [false; N];
    for i in 0..2 * N {
        let sub_term = val[i] + borrow_in;
        let borrow = (sub_term > params.modulus[i]) as u128;
        result[i] = borrow * TWO_POW_120 + params.modulus[i] - sub_term;

        borrow_in = borrow;
        if ((i & 1) == 1) {
            borrow_flags[i / 2] = borrow as bool;
        }
    }
    // let result = U60Repr::into(result_u60);
    (result, borrow_flags)
}

pub(crate) unconstrained fn __add_with_flags<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> ([u128; N], [bool; N], [bool; N], bool) {
    // let a_u60: U60Repr<N, 2> = From::from(lhs);
    // let b_u60: U60Repr<N, 2> = From::from(rhs);
    // let add_u60 = a_u60 + b_u60;
    let mut add: [u128; N] = [0; N];
    let mut carry: u128 = 0;
    for i in 0..N {
        let mut add_term = (lhs[i] as u128 + rhs[i] as u128 + carry);
        carry = add_term >> 120;
        add_term = add_term - (carry << 120);
        add[i] = add_term;
    }

    // let overflow = add.gte(params.modulus_u60);
    let overflow = __gte(add, params.modulus);

    let mut subtrahend: [u128; N] = [0; N];
    // let mut result_u60: U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };
    let mut result: [u128; N] = [0; N];

    if overflow {
        subtrahend = params.modulus;
    }

    let mut carry_in: u128 = 0;
    let mut borrow_in: u128 = 0;
    let mut borrow_flags: [bool; N] = [false; N];
    let mut carry_flags: [bool; N] = [false; N];
    for i in 0..2 * N {
        let mut add_term: u128 = lhs[i] + rhs[i] + carry_in;
        let mut carry = (add_term >= TWO_POW_120) as u128;
        add_term -= carry * TWO_POW_120;
        carry_in = carry;

        let sub_term = subtrahend[i] + borrow_in;
        let mut borrow = (sub_term > add_term) as u128;
        result[i] = borrow * TWO_POW_120 + add_term - sub_term;
        borrow_in = borrow;

        if ((i & 1) == 1) {
            // Only set `borrow` and `carry` if they differ
            if (carry != borrow) {
                let idx = (i - 1) / 2;
                carry_flags[idx] = carry as bool;
                borrow_flags[idx] = borrow as bool;
            }
        }
    }
    // let result = U60Repr::into(result_u60);

    (result, carry_flags, borrow_flags, overflow)
}

pub(crate) unconstrained fn __sub_with_flags<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> ([u128; N], [bool; N], [bool; N], bool) {
    // let a_u60: U60Repr<N, 2> = U60Repr::from(lhs);
    // let b_u60: U60Repr<N, 2> = U60Repr::from(rhs);

    // let underflow = b_u60.gte(a_u60 + U60Repr::one());
    let ap1: [u128; N] = __increment(lhs);
    let underflow: bool = __gte(rhs, ap1);
    let addend: [u128; N] = if underflow { params.modulus } else { [0; N] };
    // let mut result_u60: U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };
    let mut result: [u128; N] = [0; N];

    let mut carry_in: u128 = 0;
    let mut borrow_in: u128 = 0;
    let mut borrow_flags: [bool; N] = [false; N];
    let mut carry_flags: [bool; N] = [false; N];
    for i in 0..2 * N {
        let mut add_term: u128 = lhs[i] + addend[i] + carry_in;
        let mut carry = (add_term >= TWO_POW_120) as u128;
        add_term -= carry * TWO_POW_120;
        carry_in = carry;

        let sub_term = rhs[i] + borrow_in;
        let mut borrow = (sub_term > add_term) as u128;
        result[i] = borrow * TWO_POW_120 + add_term - sub_term;
        borrow_in = borrow;

        if ((i & 1) == 1) {
            // Only set `borrow` and `carry` if they differ
            if (carry != borrow) {
                carry_flags[i / 2] = carry as bool;
                borrow_flags[i / 2] = borrow as bool;
            }
        }
    }
    (result, carry_flags, borrow_flags, underflow)
}

/**
 * @brief BARRETT_REDUCTION_OVERFLOW_BITS defines how large an input to barrett reduction can be
 * @details maximum value = modulus^2 <<BARRETT_REDUCTION_OVERFLOW_BITS
 *          see __barrett_reduction for more details
 **/
comptime global BARRETT_REDUCTION_OVERFLOW_BITS: u32 = 4;

pub(crate) unconstrained fn __barrett_reduction<let N: u32>(
    x: [u128; 2 * N],
    redc_param: [u128; N],
    k: u32,
    modulus: [u128; N],
) -> ([u128; N], [u128; N]) {
    // for each i in 0..(N + N), adds x[i] * redc_param[j] to mulout[i + j] for each j in 0..N
    let mut mulout: [Field; 3 * N] = [0; 3 * N];
    for i in 0..(N + N) {
        for j in 0..N {
            mulout[i + j] += (x[i] as Field * redc_param[j] as Field);
        }
    }

    let mulout = split_bits::__normalize_limbs(mulout, 3 * N - 1);
    // let mulout_u60: U60Repr<N, 6> = U60Repr::new(mulout);

    // When we apply the barrett reduction, the maximum value of the output will be
    // <= p * (1 + x/2^{2k})
    // where p = modulus,
    //       x = reduction input
    // if x > p * p, we need k to be larger than modulus_bits()
    // we hardcode k = 4, which means that the maximum value of x is approx. 16 * p * p
    // this should be larger than most values put into `evaluate_quadratic_expression`
    // TODO: try and detect cases where x might be too large at comptime
    // N.B. BARRETT_REDUCTION_OVERFLOW_BITS affects how `redc_param` is generated.
    // `redc_param` = 2^{modulus_bits() * 2 + BARRETT_REDUCTION_OVERFLOW_BITS} / modulus
    // NOTE: very niche edge case error that we need to be aware of:
    //       N must be large enough to cover the modulus *plus* BARRETT_REDUCTION_OVERFLOW_BITS
    //       i.e. a 359-bit prime needs (I think) 4 limbs to represent or we may overflow when calling __barrett_reduction
    let mut quotient = __shr(mulout, (k + k + BARRETT_REDUCTION_OVERFLOW_BITS));

    // N.B. we assume that the shifted quotient cannot exceed 2 times original bit size.
    //      (partial_quotient_full should be just slightly larger than the modulus, we could probably represent with a size N+1 array)
    let partial_quotient_full: [u128; 3 * N] = quotient;

    // quotient_mul_modulus_normalized can never exceed input value `x` so can fit into size-2 array
    let mut quotient_mul_modulus_normalized_field: [Field; 2 * N] = [0; 2 * N];
    let mut quotient_mul_modulus_normalized: [u128; 2 * N] = [0; 2 * N];
    // First, accumulate the products into quotient_mul_modulus_normalized
    for j in 0..N {
        for i in 0..(N + N - j) {
            quotient_mul_modulus_normalized_field[i + j] +=
                partial_quotient_full[i] as Field * modulus[j] as Field;
        }
    }

    // Then, split the accumulated values and propagate higher bits
    for i in 0..(N + N) {
        let (lo, hi) = split_bits::split_120_bits(quotient_mul_modulus_normalized_field[i]);
        quotient_mul_modulus_normalized[i] = lo;

        // Propagate higher bits to the next index
        // TODO: what is faster, leaving this if statement in or out?
        // (array is size-1 too large so we can tolerate adding 0 into max element)
        if (i + 1 < N + N) {
            quotient_mul_modulus_normalized[i + 1] += hi;
        }
    }

    // let quotient_mul_modulus_u60: U60Repr<N, 4> = U60Repr::new(quotient_mul_modulus_normalized);
    // convert the input into U60Repr
    // let x_u60: U60Repr<N, 4> = U60Repr::new(x);
    let mut remainder_2n_limbs = __helper_sub(x, quotient_mul_modulus_normalized);
    // the last N limbs of this are going to be 0 so we just need the first N limbs of it
    let mut remainder: [u128; N] = [0; N];
    for i in 0..N {
        remainder[i] = remainder_2n_limbs[i];
    }

    let mut quotient: [u128; N] = [0; N];
    // barrett reduction is quirky so might need to remove a few modulus_u60 from the remainder
    if (__gte(remainder, modulus)) {
        remainder = __helper_sub(remainder, modulus);
        quotient = __increment(quotient);
    }
    if (__gte(remainder, modulus)) {
        remainder = __helper_sub(remainder, modulus);
        quotient = __increment(quotient);
    }
    if (__gte(remainder, modulus)) {
        remainder = __helper_sub(remainder, modulus);
        quotient = __increment(quotient);
    }

    (quotient, remainder)
}

/**
* @brief compute the log of the size of the primitive root
* @details find the maximum value k where x^k = 1, where x = primitive root
*          This is needed for our Tonelli-Shanks sqrt algorithm
**/
pub(crate) unconstrained fn __primitive_root_log_size<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
) -> u32 {
    // let mut target: U60Repr<N, 2> = params.modulus_u60 - U60Repr::one();
    let mut one: [u128; N] = [0; N];
    one[0] = 1;
    let mut target = __helper_sub(params.modulus, one);
    let mut result: u32 = 0;
    for _ in 0..MOD_BITS {
        let lsb_is_one = (target[0] & 1) == 1;
        if (lsb_is_one) {
            break;
        }
        result += 1;
        target = __shr1(target);
    }
    result
}

/**
* @brief inner loop fn for `find_multiplive_generator`
* @details recursive function to get around the lack of a `while` keyword
**/
unconstrained fn __recursively_find_multiplicative_generator<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    target: [u128; N],
    p_minus_one_over_two: [u128; N],
) -> (bool, [u128; N]) {
    let exped = __pow(params, target, p_minus_one_over_two);
    let one: [u128; N] = __one();
    let neg_one = __neg(params, one);
    let found = exped == neg_one;
    let mut result: (bool, [u128; N]) = (found, target);
    if (!found) {
        let _target: [u128; N] = __add(params, target, one);
        result = __recursively_find_multiplicative_generator::<_, MOD_BITS>(
            params,
            _target,
            p_minus_one_over_two,
        );
    }
    result
}

/**
* @brief find multiplicative generator `g` where `g` is the smallest value that is not a quadratic residue
*        i.e. smallest g where g^2 = -1
* @note WARNING if multiplicative generator does not exist, this function will enter an infinite loop!
**/
pub(crate) unconstrained fn __multiplicative_generator<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
) -> [u128; N] {
    let mut target: [u128; N] = __one();
    let p_minus_one_over_two = __shr(__helper_sub(params.modulus, __one()), 1);
    // let p_minus_one_over_two: U60Repr<N, 2> = (params.modulus_u60 - U60Repr::one()).shr(1);
    let (_, target) = __recursively_find_multiplicative_generator::<_, MOD_BITS>(
        params,
        target,
        p_minus_one_over_two,
    );
    target
}

pub(crate) unconstrained fn __tonelli_shanks_sqrt_inner_loop_check<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    t2m: [u128; N],
    i: u32,
) -> u32 {
    let one: [u128; N] = __one();
    let is_one = t2m == one;
    let mut result = i;
    if (!is_one) {
        let t2m = __mul::<_, MOD_BITS>(params, t2m, t2m);
        let i = i + 1;
        result = __tonelli_shanks_sqrt_inner_loop_check::<_, MOD_BITS>(params, t2m, i);
    }
    result
}

pub(crate) unconstrained fn __increment<let N: u32>(val: [u128; N]) -> [u128; N] {
    let mut result: [u128; N] = [0; N];
    let mut carry: u128 = 1;
    for i in 0..N {
        let mut add_term = (val[i] + carry);
        carry = add_term >> 120;
        add_term = add_term - (carry << 120);
        result[i] = add_term;
    }
    result
}

pub(crate) unconstrained fn __shr<let N: u32>(input: [u128; N], shift: u32) -> [u128; N] {
    let mut result: [u128; N] = [0; N];
    let num_shifted_limbs = shift / 120;
    let limb_shift = (shift % 120) as u8;
    let remainder_shift = (120 - limb_shift) as u8;
    let mask: u128 = (((1 as u128) << limb_shift) - 1) << remainder_shift;
    result[0] = (input[0 + num_shifted_limbs] >> limb_shift);

    for i in 1..(N - num_shifted_limbs) {
        let value = input[i + num_shifted_limbs];
        result[i] = value >> limb_shift;
        let remainder: u128 = (value << remainder_shift) & mask;
        result[i - 1] = result[i - 1] + remainder;
    }
    result
}

pub(crate) unconstrained fn __shl<let N: u32>(input: [u128; N], shift: u32) -> [u128; N] {
    let mut result: [u128; N] = [0; N];

    let num_shifted_limbs = shift / 120;
    let limb_shift = (shift % 120) as u8;
    let remainder_shift: u8 = 120 - limb_shift as u8;

    // 83
    // limb shift = 1
    // inside shift = 19 bits to the left
    // meaning we have 19 carry bits and 41 remainder bits
    let mask: u128 = (1 as u128 << 120) - 1;
    //   let mask: u64 = (((1 as u64) << limb_shift as u8) - 1) << remainder_shift as u8;
    let value = input[0];

    let mut remainder = (value >> remainder_shift);
    result[num_shifted_limbs] = (value << limb_shift) & mask;

    // shift 84. num shifted = 1
    for i in 1..((N) - num_shifted_limbs) {
        let value = input[i];
        let upshift = ((value << limb_shift) + remainder) & mask;
        result[i + num_shifted_limbs] = upshift;
        remainder = (value >> remainder_shift);
        // let remainder: u64 = (self.limbs.get(i + num_shifted_limbs as u64) << remainder_shift as u8) & mask;
        // result.limbs.set(i - 1, result.limbs.get(i - 1) + remainder);
    }
    result
}

pub(crate) unconstrained fn __helper_sub<let N: u32>(lhs: [u128; N], rhs: [u128; N]) -> [u128; N] {
    let mut result: [u128; N] = [0; N];
    let mut borrow: u128 = 0;
    let mut borrow_in: u128 = 0;
    for i in 0..N {
        borrow = (rhs[i] as u128 + borrow_in > lhs[i] as u128) as u128;
        let sub = (borrow << 120) + lhs[i] as u128 - rhs[i] as u128 - borrow_in;
        result[i] = sub;
        borrow_in = borrow;
    }
    result
}

pub(crate) unconstrained fn __helper_add<let N: u32>(lhs: [u128; N], rhs: [u128; N]) -> [u128; N] {
    let mut result: [u128; N] = [0; N];
    let mut carry: u128 = 0;
    for i in 0..N {
        let mut add_term = (lhs[i] as u128 + rhs[i] as u128 + carry);
        carry = add_term >> 120;
        add_term = add_term - (carry << 120);
        result[i] = add_term;
    }
    result
}

pub(crate) unconstrained fn __shr1<let N: u32>(mut input: [u128; N]) -> [u128; N] {
    let value = input[N - 1];
    input[N - 1] = value >> 1;

    let mut remainder = (value & 1) << 59;

    for i in 0..N {
        let value = input[N - 1 - i];
        input[N - 1 - i] = (value >> 1) + remainder;
        remainder = (value << 119) & TWO_POW_119;
    }
    input
}

pub(crate) unconstrained fn __get_msb<let N: u32>(val: [u128; N]) -> u32 {
    let mut count = 0;
    for i in 0..N {
        let v = val[((N) - 1 - i)];
        if (v > 0) {
            count = 120 * ((N) - 1 - i) + get_msb128(v);
            break;
        }
    }
    count
}

pub(crate) fn __get_bit<let N: u32>(input: [u128; N], bit: u32) -> bool {
    let segment_index: u32 = bit / 60;
    let uint_index = bit % 60;

    let limb: u128 = input[segment_index];
    let value = (limb >> uint_index as u8) & 1;
    value == 1
}
