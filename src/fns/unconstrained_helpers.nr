// This file contains the unconstrained helpers that are mostly used by unconstrained ops

use crate::constants::{TWO_POW_119, TWO_POW_120};

use crate::fns::unconstrained_ops::{__add, __gte, __mul, __neg, __pow};

use crate::utils::msb::get_msb;
use crate::utils::split_bits::{__normalize_limbs, __split_120_bits};

use crate::params::BigNumParams;

// ------------------------------ DERIVATION HELPER FUNCTIONS ------------------------------

///  Construct a `1` BigNum value (unconstrained)
pub(crate) unconstrained fn __one<let N: u32>() -> [u128; N] {
    let mut limbs: [u128; N] = [0; N];
    limbs[0] = 1;
    limbs
}

/// Construct a BigNum value from Field (unconstrained)
///
/// Split the native `Field` value into `N` 120-bit limbs
pub(crate) unconstrained fn __from_field<let N: u32>(val: Field) -> [u128; N] {
    let mut x: Field = val;
    let mut result: [u128; N] = [0; N];

    if (N == 1) {
        let (first_limb, _): (u128, Field) = __split_120_bits(x);
        result[0] = first_limb;
    }

    if (N == 2) {
        let (first_limb, x): (u128, Field) = __split_120_bits(x);
        let (second_limb, _): (u128, Field) = __split_120_bits(x);
        result[0] = first_limb;
        result[1] = second_limb;
    }

    if (N > 2) {
        let (first_limb, x): (u128, Field) = __split_120_bits(x);
        let (second_limb, x): (u128, Field) = __split_120_bits(x);
        let (third_limb, _): (u128, Field) = __split_120_bits(x);
        result[0] = first_limb;
        result[1] = second_limb;
        result[2] = third_limb;
    }
    result
}

pub(crate) unconstrained fn __neg_with_flags<let N: u32>(
    modulus: [u128; N],
    val: [u128; N],
) -> ([u128; N], [bool; N - 1]) {
    let mut result: [u128; N] = [0; N];
    let mut borrow_in: u128 = 0;

    let mut borrow_flags: [bool; N - 1] = [false; N - 1];
    for i in 0..N {
        let sub_term = val[i] + borrow_in;
        let borrow = (sub_term > modulus[i]) as u128;
        result[i] = borrow * TWO_POW_120 + modulus[i] - sub_term;

        borrow_in = borrow;
        if (i < N - 1) {
            borrow_flags[i] = borrow != 0;
        }
    }
    (result, borrow_flags)
}

pub(crate) unconstrained fn __add_with_flags<let N: u32>(
    modulus: [u128; N],
    lhs: [u128; N],
    rhs: [u128; N],
) -> ([u128; N], [bool; N], [bool; N - 1], bool) {
    let add_res = __helper_add(lhs, rhs);
    let overflow = __gte(add_res, modulus);

    let mut subtrahend: [u128; N] = [0; N];
    let mut result: [u128; N] = [0; N];

    if overflow {
        subtrahend = modulus;
    }

    let mut carry_in: u128 = 0;
    let mut borrow_in: u128 = 0;
    let mut borrow_flags: [bool; N - 1] = [false; N - 1];
    let mut carry_flags: [bool; N] = [false; N];
    for i in 0..N {
        let mut add_term = lhs[i] + rhs[i] + carry_in;
        let mut carry = (add_term as u128 >= TWO_POW_120) as u128;
        add_term -= carry * TWO_POW_120;
        carry_in = carry as u128;

        let sub_term = subtrahend[i] + borrow_in;

        let mut borrow: u128 = (sub_term > add_term) as u128;
        result[i] = borrow * TWO_POW_120 + add_term - sub_term;
        borrow_in = borrow as u128;

        // Only set `borrow` and `carry` if they differ
        if (carry != borrow) {
            carry_flags[i] = carry != 0;
            if (i < N - 1) {
                borrow_flags[i] = borrow != 0;
            }
        }
    }
    (result, carry_flags, borrow_flags, overflow)
}

pub(crate) unconstrained fn __sub_with_flags<let N: u32>(
    modulus: [u128; N],
    lhs: [u128; N],
    rhs: [u128; N],
) -> ([u128; N], [bool; N], [bool; N - 1], bool) {
    let mut one: [u128; N] = [0; N];
    one[0] = 1;
    let underflow = !__gte(lhs, rhs);
    let addend: [u128; N] = if underflow { modulus } else { [0; N] };
    let mut result: [u128; N] = [0; N];

    let mut carry_in: u128 = 0;
    let mut borrow_in: u128 = 0;
    let mut borrow_flags: [bool; N - 1] = [false; N - 1];
    let mut carry_flags: [bool; N] = [false; N];
    for i in 0..N {
        let mut add_term: u128 = lhs[i] + addend[i] + carry_in;
        let mut carry = (add_term as u128 >= TWO_POW_120) as u128;
        add_term -= carry * TWO_POW_120;
        carry_in = carry;

        let sub_term = rhs[i] + borrow_in;
        let mut borrow = (sub_term > add_term) as u128;
        result[i] = borrow as u128 * TWO_POW_120 + add_term - sub_term;
        borrow_in = borrow;

        // Only set `borrow` and `carry` if they differ
        if (carry != borrow) {
            carry_flags[i] = carry != 0;
            if (i < N - 1) {
                borrow_flags[i] = borrow != 0;
            }
        }
    }
    (result, carry_flags, borrow_flags, underflow)
}

pub(crate) unconstrained fn __validate_in_field_compute_borrow_flags<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
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
) -> (bool, [u128; N], [bool; N], [bool; N]) {
    let mut a = lhs;
    let mut b = rhs;
    let underflow = !__gte(lhs, rhs);

    let mut result: [u128; N] = [0; N];
    // swap a and b if there's an underflow
    let (a, b) = if underflow { (b, a) } else { (a, b) };
    let mut carry_in: u128 = 0;
    let mut borrow_in: u128 = 0;
    let mut borrow_flags: [bool; N] = [false; N];
    let mut carry_flags: [bool; N] = [false; N];
    for i in 0..N {
        let mut add_term: u128 = a[i] + carry_in;
        let mut carry = (add_term as u128 >= TWO_POW_120) as u128;
        add_term -= carry * TWO_POW_120;
        carry_in = carry;

        let sub_term = b[i] + borrow_in;
        let mut borrow = (sub_term > add_term) as u128;
        result[i] = (borrow * TWO_POW_120 + add_term - sub_term);

        borrow_in = borrow;

        // Only set `borrow` and `carry` if they differ
        if (carry != borrow) {
            carry_flags[i] = carry != 0;
            borrow_flags[i] = borrow != 0;
        }
    }
    (underflow, result, carry_flags, borrow_flags)
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
    let mut mulout_field: [Field; 3 * N] = [0; 3 * N];
    for i in 0..(N + N) {
        for j in 0..N {
            mulout_field[i + j] += x[i] as Field * redc_param[j] as Field;
        }
    }

    let mulout: [u128; 3 * N] = __normalize_limbs(mulout_field);

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
    // the quotient has bunch of zero limbs now, so we can just take the first N limbs as a result
    let mut smaller_quotient = [0; N];
    for i in 0..N {
        smaller_quotient[i] = quotient[i] as u128;
    }

    // N.B. we assume that the shifted quotient cannot exceed 2 times original bit size.
    //      (partial_quotient_full should be just slightly larger than the modulus, we could probably represent with a size N+1 array)
    let partial_quotient_full: [Field; 3 * N] = __into_field_array(quotient);

    // quotient_mul_modulus_normalized can never exceed input value `x` so can fit into size-2 array
    let mut quotient_mul_modulus_normalized: [Field; 2 * N] = [0; 2 * N];

    // First, accumulate the products into quotient_mul_modulus_normalized
    for j in 0..N {
        for i in 0..(N + N - j) {
            quotient_mul_modulus_normalized[i + j] +=
                partial_quotient_full[i] * modulus[j] as Field;
        }
    }

    // Then, split the accumulated values and propagate higher bits
    let long_quotient_mul_modulus_normalized: [u128; 2 * N] =
        __normalize_limbs(quotient_mul_modulus_normalized);
    let mut quotient_mul_modulus_normalized: [u128; N] = [0; N];
    for i in 0..N {
        quotient_mul_modulus_normalized[i] = long_quotient_mul_modulus_normalized[i];
    }

    let mut long_remainder = __helper_sub(x, long_quotient_mul_modulus_normalized);
    // ugly but have to remove a bunch of zeros from this
    let mut remainder = [0; N];
    for i in 0..N {
        remainder[i] = long_remainder[i];
    }
    // barrett reduction is quirky so might need to remove a few modulus from the remainder
    if (__gte(remainder, modulus)) {
        remainder = __helper_sub(remainder, modulus);
        smaller_quotient = __increment(smaller_quotient);
    }
    if (__gte(remainder, modulus)) {
        remainder = __helper_sub(remainder, modulus);
        smaller_quotient = __increment(smaller_quotient);
    }
    if (__gte(remainder, modulus)) {
        remainder = __helper_sub(remainder, modulus);
        smaller_quotient = __increment(smaller_quotient);
    }

    (smaller_quotient, remainder)
}

// ------------------------------ ARITHMETIC HELPER FUNCTIONS ------------------------------
// These are the functions that operate on limbs as if they were just big integers

/// Adds `1` to the BigNum value without modular reduction (unconstrained)
///
/// ## Note
/// The `carry` must be `0` at the end of the loop.
/// No explicit assertion is made, as this condition is validated during evaluation.
pub(crate) unconstrained fn __increment<let N: u32>(val: [u128; N]) -> [u128; N] {
    let mut result: [u128; N] = [0; N];
    let mut carry: u128 = 1;
    for i in 0..N {
        let mut add_term: u128 = val[i] + carry;
        carry = add_term >> 120;
        add_term = add_term - (carry << 120);
        result[i] = add_term;
    }
    result
}

/// Adds two `BigNum` values without modular reduction (unconstrained).
///
/// ## Note
/// The `carry` must be `0` at the end of the loop.
/// No explicit assertion is made, as this condition is validated during evaluation.
pub(crate) unconstrained fn __helper_add<let N: u32>(lhs: [u128; N], rhs: [u128; N]) -> [u128; N] {
    let mut result: [u128; N] = [0; N];

    let mut carry: u128 = 0;
    for i in 0..N {
        let mut add_term: u128 = lhs[i] + rhs[i] + carry;
        carry = add_term >> 120;
        add_term = add_term - (carry << 120);
        result[i] = add_term;
    }
    result
}

/// Subtracts two `BigNum` values without modular reduction (unconstrained).
///
/// ## Note
/// The `borrow` must be `0` at the end of the loop.
/// No explicit assertion is made, as this condition is validated during evaluation.
pub(crate) unconstrained fn __helper_sub<let N: u32>(lhs: [u128; N], rhs: [u128; N]) -> [u128; N] {
    let mut result: [u128; N] = [0; N];

    let mut borrow: u128 = 0;
    for i in 0..N {
        let subtrahend: u128 = rhs[i] + borrow;
        borrow = (subtrahend > lhs[i]) as u128;
        result[i] = (borrow << 120) + lhs[i] - subtrahend;
    }
    result
}

/// Multiplies two `BigNum` values without modular reduction (unconstrained).
///
/// Computes the full schoolbook product of two N-limb little-endian arrays
///
/// ## Note
/// The mathematical product fits in `2 * N - 1` limbs, but we keep `2 * N`
/// limbs intentionally as the extra high limb safely absorbs a possible single limb overflow
/// for moduli close to `120 * N` bits.
pub(crate) unconstrained fn __helper_mul<let N: u32>(
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; 2 * N] {
    let mut result: [Field; 2 * N] = [0; 2 * N];
    for i in 0..N {
        for j in 0..N {
            result[i + j] += (lhs[i] as Field) * (rhs[j] as Field);
        }
    }
    __normalize_limbs(result)
}

// ------------------------------ LOGIC HELPER FUNCTIONS ------------------------------
// These are the functions that operate on limbs as if they were just big integers

/// Left-shifts a `BigNum` value by `shift` bits (unconstrained).
///
/// Performs a bitwise left shift across limbs.
///
/// ## Note
/// The most significant limb is truncated to 120 bits after the shift.
pub(crate) unconstrained fn __shl<let N: u32>(input: [u128; N], shift: u32) -> [u128; N] {
    let mut result: [u128; N] = [0; N];

    let num_shifted_limbs: u32 = shift / 120;
    if num_shifted_limbs < N {
        let limb_shift: u128 = (shift % 120) as u128;
        let remainder_shift: u128 = 120 - limb_shift;

        let mask: u128 = TWO_POW_120 - 1;
        let value: u128 = input[0];

        let mut remainder: u128 = value >> remainder_shift;
        result[num_shifted_limbs] = (value << limb_shift) & mask;

        for i in 1..(N - num_shifted_limbs) {
            let value: u128 = input[i];
            let upshift: u128 = ((value << limb_shift) + remainder) & mask;
            result[i + num_shifted_limbs] = upshift;
            remainder = value >> remainder_shift;
        }
    }
    result
}

/// Right-shifts a `BigNum` value by `shift` bits (unconstrained).
///
/// Performs a bitwise right shift across limbs.
pub(crate) unconstrained fn __shr<let N: u32>(input: [u128; N], shift: u32) -> [u128; N] {
    let mut result: [u128; N] = [0; N];

    let num_shifted_limbs: u32 = shift / 120;
    if num_shifted_limbs < N {
        let limb_shift: u128 = (shift % 120) as u128;
        let remainder_shift: u128 = 120 - limb_shift;
        let mask: u128 = (((1 as u128) << limb_shift) - 1) << remainder_shift;

        result[0] = input[num_shifted_limbs] >> limb_shift;
        for i in 1..(N - num_shifted_limbs) {
            let value: u128 = input[i + num_shifted_limbs];
            result[i] = value >> limb_shift;
            let remainder: u128 = (value << remainder_shift) & mask;
            result[i - 1] = result[i - 1] + remainder;
        }
    }
    result
}

/// Right-shifts a `BigNum` value by `1` bit  (unconstrained)
pub(crate) unconstrained fn __shr1<let N: u32>(mut input: [u128; N]) -> [u128; N] {
    let mut result: [u128; N] = [0; N];

    let value: u128 = input[N - 1];
    result[N - 1] = value >> 1;
    let mut remainder: u128 = (value & 1) << 119;

    for i in 1..N {
        let value: u128 = input[N - 1 - i];
        result[N - 1 - i] = (value >> 1) + remainder;
        remainder = (value << 119) & TWO_POW_119;
    }
    result
}

/// Returns the index of the most significant set bit in a `BigNum` value (unconstrained).
pub(crate) unconstrained fn __get_msb<let N: u32>(val: [u128; N]) -> u32 {
    let mut count: u32 = 0;
    for i in 0..N {
        let idx: u32 = N - 1 - i;
        let v: u128 = val[idx];
        if (v > 0) {
            count = 120 * idx + get_msb(v);
            break;
        }
    }
    count
}

/// Returns `true` if the bit at position `bit` is set in the `BigNum` (unconstrained).
///
/// ## Note
/// No bounds check is performed
pub(crate) fn __get_bit<let N: u32>(input: [u128; N], bit: u32) -> bool {
    let segment_index: u32 = bit / 120;
    let uint_index: u128 = (bit % 120) as u128;

    let limb: u128 = input[segment_index];
    let value: u128 = (limb >> uint_index) & 1;
    value == 1
}

/**
* @brief compute the log of the size of the primitive root
* @details find the maximum value k where x^k = 1, where x = primitive root
*          This is needed for our Tonelli-Shanks sqrt algorithm
**/
pub(crate) unconstrained fn __primitive_root_log_size<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
) -> u32 {
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
    params: BigNumParams<N, MOD_BITS>,
    target: [u128; N],
    p_minus_one_over_two: [u128; N],
) -> (bool, [u128; N]) {
    let exped = __pow(params, target, p_minus_one_over_two);
    let one: [u128; N] = __one();
    let neg_one = __neg(params.modulus, one);
    let found = exped == neg_one;
    let mut result: (bool, [u128; N]) = (found, target);
    if (!found) {
        let _target: [u128; N] = __add(params.modulus, target, one);
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
    params: BigNumParams<N, MOD_BITS>,
) -> [u128; N] {
    let mut target: [u128; N] = __one();
    let p_minus_one_over_two = __shr1(__helper_sub(params.modulus, __one()));
    let (_, target) = __recursively_find_multiplicative_generator::<_, MOD_BITS>(
        params,
        target,
        p_minus_one_over_two,
    );
    target
}

pub(crate) unconstrained fn __tonelli_shanks_sqrt_inner_loop_check<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
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

pub(crate) fn __into_field_array<let N: u32>(input: [u128; N]) -> [Field; N] {
    let mut result: [Field; N] = [0; N];
    for i in 0..N {
        result[i] = input[i] as Field;
    }
    result
}
