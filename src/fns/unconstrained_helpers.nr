// This file contains the unconstrained helpers that are mostly used by unconstrained ops

use crate::constants::TWO_POW_120;

use crate::fns::unconstrained_ops::{__add, __eq, __gte, __mul, __neg, __pow, __sqr};

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

// ------------------------------ ARITHMETIC WITH FLAGS HELPER FUNCTIONS ------------------------------
// These are the functions that compute modular operations results as well as borrow and carry flags for constraints

/// Compute the `MOD - val` and the corresponding borrow flags (unconstrained)
///
/// Negate the value and compute the flags indicating whether we need
///      to borrow a `bit` from the upper limb when subtracting the value from modulus
///
/// ## Note
/// The `borrow_in` must be `0` at the end of the loop.
/// No explicit assertion is made, as this condition is validated during evaluation.
pub(crate) unconstrained fn __neg_with_flags<let N: u32>(
    modulus: [u128; N],
    val: [u128; N],
) -> ([u128; N], [bool; N - 1]) {
    let mut result: [u128; N] = [0; N];
    let mut borrow_in: u128 = 0;

    let mut borrow_flags: [bool; N - 1] = [false; N - 1];
    for i in 0..N {
        let sub_term: u128 = val[i] + borrow_in;
        borrow_in = (sub_term > modulus[i]) as u128;
        result[i] = borrow_in * TWO_POW_120 + modulus[i] - sub_term;
        if (i < N - 1) {
            borrow_flags[i] = (borrow_in != 0);
        }
    }
    (result, borrow_flags)
}

/// Compute modular addition and the corresponding borrow and carry flags (unconstrained)
///
/// Given `x, y, MOD` compute x + y or x + y - MOD in case it overflows
/// Additionally compute all the carries from addition (x + y)
/// and borrows from subtraction  (- MOD)
///
/// ## Note
/// The `borrow` must be equal to `carry` at the end of the loop.
/// No explicit assertion is made, as this condition is validated during evaluation.
pub(crate) unconstrained fn __add_with_flags<let N: u32>(
    modulus: [u128; N],
    lhs: [u128; N],
    rhs: [u128; N],
) -> ([u128; N], [bool; N - 1], [bool; N - 1], bool) {
    let mask: u128 = TWO_POW_120 - 1;

    let add_res: [u128; N] = __helper_add(lhs, rhs);
    let overflow: bool = __gte(add_res, modulus);

    let mut subtrahend: [u128; N] = if overflow { modulus } else { [0; N] };
    let mut result: [u128; N] = [0; N];

    let mut borrow_flags: [bool; N - 1] = [false; N - 1];
    let mut carry_flags: [bool; N - 1] = [false; N - 1];

    let mut carry: u128 = 0;
    let mut borrow: u128 = 0;
    for i in 0..N {
        let mut add_term: u128 = lhs[i] + rhs[i] + carry;
        carry = add_term >> 120;
        add_term &= mask;

        let sub_term: u128 = subtrahend[i] + borrow;
        borrow = (sub_term > add_term) as u128;

        result[i] = borrow * TWO_POW_120 + add_term - sub_term;

        // Only set `borrow` and `carry` if they differ
        // And if it's not the last limb
        if (carry != borrow) & (i < N - 1) {
            carry_flags[i] = carry != 0;
            borrow_flags[i] = borrow != 0;
        }
    }
    (result, carry_flags, borrow_flags, overflow)
}

/// Compute modular subtraction and the corresponding borrow and carry flags (unconstrained)
///
/// Given `x, y, MOD` compute x - y or x - y + MOD in case it overflows
/// Additionally compute all the carries from addition (x + MOD)
/// and borrows from subtraction  (- y)
///
/// ## Note
/// The `borrow` must be equal to `carry` at the end of the loop.
/// No explicit assertion is made, as this condition is validated during evaluation.
pub(crate) unconstrained fn __sub_with_flags<let N: u32>(
    modulus: [u128; N],
    lhs: [u128; N],
    rhs: [u128; N],
) -> ([u128; N], [bool; N - 1], [bool; N - 1], bool) {
    let mask: u128 = TWO_POW_120 - 1;

    let underflow: bool = !__gte(lhs, rhs);

    let addend: [u128; N] = if underflow { modulus } else { [0; N] };
    let mut result: [u128; N] = [0; N];

    let mut borrow_flags: [bool; N - 1] = [false; N - 1];
    let mut carry_flags: [bool; N - 1] = [false; N - 1];

    let mut carry: u128 = 0;
    let mut borrow: u128 = 0;
    for i in 0..N {
        let mut add_term: u128 = lhs[i] + addend[i] + carry;
        carry = add_term >> 120;
        add_term &= mask;

        let sub_term: u128 = rhs[i] + borrow;
        borrow = (sub_term > add_term) as u128;

        result[i] = borrow * TWO_POW_120 + add_term - sub_term;

        // Only set `borrow` and `carry` if they differ
        // And if it's not the last limb
        if (carry != borrow) & (i < N - 1) {
            carry_flags[i] = carry != 0;
            borrow_flags[i] = borrow != 0;
        }
    }
    (result, carry_flags, borrow_flags, underflow)
}

/// Validate that lhs - rhs does not underflow (unconstrained)
///
/// Same as `__validate_gte_with_flags`, but we don't compute the
/// result of a subtraction
pub(crate) unconstrained fn __validate_in_field_compute_borrow_flags<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    val: [u128; N],
) -> [bool; N - 1] {
    let modulus: [u128; N] = params.modulus;

    let mut borrow_flags: [bool; N - 1] = [false; N - 1];
    borrow_flags[0] = modulus[0] < val[0];
    for i in 1..N - 1 {
        borrow_flags[i] = modulus[i] < val[i] + (borrow_flags[i - 1] as u128);
    }
    borrow_flags
}

/// Validate that lhs - rhs does not underflow (unconstrained)
///
/// Compute underflow flag (lhs < rhs)
///       then perform subtraction with borrow flags
///
/// ## Note
/// The `borrow` must be equal to 0 at the end of the loop.
/// And it can't be nonzero, since we swap the terms at the beginning
pub(crate) unconstrained fn __validate_gte_with_flags<let N: u32>(
    lhs: [u128; N],
    rhs: [u128; N],
) -> (bool, [u128; N], [bool; N - 1]) {
    let mut a: [u128; N] = lhs;
    let mut b: [u128; N] = rhs;

    let underflow: bool = !__gte(lhs, rhs);
    // swap a and b if there's an underflow
    let (a, b): ([u128; N], [u128; N]) = if underflow { (b, a) } else { (a, b) };

    let mut result: [u128; N] = [0; N];

    let mut borrow_flags: [bool; N - 1] = [false; N - 1];

    let mut borrow: u128 = 0;
    for i in 0..N {
        let mut add_term: u128 = a[i];

        let sub_term: u128 = b[i] + borrow;
        borrow = (sub_term > add_term) as u128;

        result[i] = borrow * TWO_POW_120 + add_term - sub_term;

        if (i < N - 1) {
            borrow_flags[i] = borrow != 0;
        }
    }
    (underflow, result, borrow_flags)
}

// ------------------------------ BARRETT REDUCTION ------------------------------

/// `BARRETT_REDUCTION_OVERFLOW_BITS` defines how large an input to barrett reduction can be
///
/// maximum value = modulus^2 << BARRETT_REDUCTION_OVERFLOW_BITS
/// see __barrett_reduction for more details
comptime global BARRETT_REDUCTION_OVERFLOW_BITS: u32 = 4;

/// Optimized modular multiplication (unconstrained)
///
/// The trick is to approximate 1/p with m/2**r, because division by 2**r is much cheaper
/// In our case m = redc_param = floor(2^{MOD_BITS * 2 + BARRET_REDUCTION_OVERFLOW_BITS} / p)
///             r = MOD_BITS * 2 + BARRET_REDUCTION_OVERFLOW_BITS
///
/// When we apply the barrett reduction, the maximum value of the output will be <= p * (1 + x/2^{2k})
/// where p = modulus,
///       x = reduction input
///
/// If x > p * p, we need k to be larger than modulus_bits()
/// We hardcode k = 4, which means that the maximum value of x is approx. 16 * p * p
/// This should be larger than most values put into `evaluate_quadratic_expression`
///
/// ## TODO
/// Detect cases where x might be too large at comptime
///
/// ## Note
/// very niche edge case error that we need to be aware of:
///      N must be large enough to cover the modulus *plus* BARRETT_REDUCTION_OVERFLOW_BITS
///      i.e. a 359-bit prime needs (I think) 4 limbs to represent or we may overflow
///      when calling __barrett_reduction
///
/// ## Note on final reduction
///
/// Assumptions:
///  - k = ceil(log2 p), so p <= 2^k
///  - s = 4, m = redc_param = floor(2^{2*k + s}/p)
///  - x < 16 * p^2 (x < 2^{2 * k + s})
///
/// Let m' = 2^{2*k + s} / p, and write m = m' - \epsilon, \epsilon \in [0, 1)
//
/// quo = floor(x * m / 2^{2 * k + s}) = floor(x * m' / 2^{2 * k + s} - x * \epsilon / 2^{2 * k + s}) =
/// floor(x / p - x * \epsilon / 2^{2 * k + s})
///
/// Bounds:
///   quo <= floor(x / p)
///
///   floor(a - b) >= floor(a) - ceil(b) (known identity) =>
///   quo >= floor(x / p) - ceil(x * \epsilon / 2^{2 * k + s})
///       >= floor(x / p) - ceil(x / 2^{2 * k + s}) (epsilon < 1)
///
/// x / 2^{2 * k + s} < C * p^2 / 2^{2 * k + s} <= C * 2^{2 * k} / 2^{2 * k + s} = C / 2^s
///
/// When the assumption holds (C = 16), ceil(x / 2^{2 * k + s}) = 1, for x > 0
/// Therefore quo = {floor(x/p), floor(x/p) - 1}
///
/// In first case: rem = x - quo * p = x - floor(x/p) * p < p
/// In second case: rem = x - (floor(x/p) - 1) * p = (x - floor(x/p) * p) + p -> need 1 subtraction
///
/// ### Note
/// We allow 64 products to be summed inside the `evaluate_quadratic_expression`
/// In that case x / 2^{2 * k + s} < 64 / 2^4 = 4 => hence we need to subtract modulus at most 4 times
/// We can leave it 2 for now as it is unlikely to reach beyond 32 * p^2
///
/// In the worst case though, we will have the input > 64 * p^2
/// (for example (a1 + b1) * (c1 + d1) + ... 64 times)
/// This is highly unlikely though.
///
/// ### TODO:
/// Possibly change the `BARRETT_REDUCTION_OVERFLOW_BITS` to 6, so that we need only 1 reduction here
/// However we will have to recompute all the fields `redc_param`s and fix paramgen
pub(crate) unconstrained fn __barrett_reduction<let N: u32>(
    x: [u128; 2 * N],
    redc_param: [u128; N],
    k: u32,
    modulus: [u128; N],
) -> ([u128; N], [u128; N]) {
    // TODO: switch to __helper_mul, once the compiler is smart enough to handle this
    let mut mulout_field: [Field; 3 * N] = [0; 3 * N];
    for i in 0..(2 * N) {
        for j in 0..N {
            mulout_field[i + j] += (x[i] as Field) * (redc_param[j] as Field);
        }
    }
    let mulout: [u128; 3 * N] = __normalize_limbs(mulout_field);

    let quotient: [u128; 3 * N] = __shr(mulout, (k + k + BARRETT_REDUCTION_OVERFLOW_BITS));

    // Remove a bunch of zeros from the end
    let mut smaller_quotient: [u128; N] = [0; N];
    for i in 0..N {
        smaller_quotient[i] = quotient[i] as u128;
    }

    // long_quotient_mul_modulus can never exceed input value `x` so can fit into size-2 array
    let long_quotient_mul_modulus: [u128; 2 * N] = __helper_mul(smaller_quotient, modulus);
    let long_remainder: [u128; 2 * N] = __helper_sub(x, long_quotient_mul_modulus);

    // Remove a bunch of zeros from the end
    let mut remainder: [u128; N] = [0; N];
    for i in 0..N {
        remainder[i] = long_remainder[i];
    }

    for _ in 0..2 {
        if (__gte(remainder, modulus)) {
            remainder = __helper_sub(remainder, modulus);
            smaller_quotient = __increment(smaller_quotient);
        }
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
    let mask: u128 = TWO_POW_120 - 1;

    let mut result: [u128; N] = [0; N];
    let mut carry: u128 = 1;
    for i in 0..N {
        let add_term: u128 = val[i] + carry;
        carry = add_term >> 120;
        result[i] = add_term & mask;
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
    let mask: u128 = TWO_POW_120 - 1;

    for i in 0..N {
        let add_term: u128 = lhs[i] + rhs[i] + carry;
        carry = add_term >> 120;
        result[i] = add_term & mask;
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
///
/// No bounds check is performed on `num_shifted_limbs`.
/// However, we use it only in `__udiv_mod`, where it is not possible to reach
/// `num_shifted_limbs` > `N`
pub(crate) unconstrained fn __shl<let N: u32>(input: [u128; N], shift: u32) -> [u128; N] {
    let mut result: [u128; N] = [0; N];

    let num_shifted_limbs: u32 = shift / 120;
    let limb_shift: u128 = (shift % 120) as u128;
    let remainder_shift: u128 = 120 - limb_shift;

    let mask: u128 = TWO_POW_120 - 1;
    let mut remainder: u128 = input[0] >> remainder_shift;

    result[num_shifted_limbs] = (input[0] << limb_shift) & mask;

    for i in 1..(N - num_shifted_limbs) {
        let value: u128 = input[i];
        let upshift: u128 = ((value << limb_shift) | remainder) & mask;
        result[i + num_shifted_limbs] = upshift;
        remainder = value >> remainder_shift;
    }
    result
}

/// Right-shifts a `BigNum` value by `shift` bits (unconstrained).
///
/// Performs a bitwise right shift across limbs.
///
/// # Note
/// No bounds check is performed on `num_shifted_limbs`.
/// However, we use it only in `__tonelli_shanks_sqrt`, where it is not possible to reach
/// `num_shifted_limbs` > `N`
pub(crate) unconstrained fn __shr<let N: u32>(input: [u128; N], shift: u32) -> [u128; N] {
    let mut result: [u128; N] = [0; N];

    let num_shifted_limbs: u32 = shift / 120;
    let limb_shift: u128 = (shift % 120) as u128;

    let remainder_shift: u128 = 120 - limb_shift;
    let low_mask: u128 = (1 as u128 << limb_shift) - 1;

    result[0] = input[num_shifted_limbs] >> limb_shift;
    for i in 1..(N - num_shifted_limbs) {
        let value: u128 = input[i + num_shifted_limbs];

        let carry: u128 = (value & low_mask) << remainder_shift;
        result[i - 1] |= carry;

        result[i] = value >> limb_shift;
    }
    result
}

/// Right-shifts a `BigNum` value by `1` bit  (unconstrained)
///
/// # Note
/// All the operations on limbs are executed in place
/// to save opcodes
pub(crate) unconstrained fn __shr1<let N: u32>(mut input: [u128; N]) -> [u128; N] {
    let value: u128 = input[N - 1];
    let mut remainder: u128 = (value & 1) << 119;
    input[N - 1] >>= 1;

    for i in 1..N {
        let value: u128 = input[N - 1 - i];
        input[N - 1 - i] = (value >> 1) | remainder;
        remainder = (value & 1) << 119;
    }
    input
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
/// No bounds check is performed on `bit`
pub(crate) fn __get_bit<let N: u32>(input: [u128; N], bit: u32) -> bool {
    let segment_index: u32 = bit / 120;
    let uint_index: u128 = (bit % 120) as u128;

    let limb: u128 = input[segment_index];
    let value: u128 = (limb >> uint_index) & 1;
    value == 1
}

// ------------------------------ SQRT HELPER FUNCTIONS ------------------------------
// These are the functions that are used during taking a square root

/// Compute the maximal power of 2 that divides the group order (unconstrained)
///
/// Find the maximum value s such that `MOD = 2^s * q + 1`, where `q` is odd
///       This is needed for our Tonelli-Shanks sqrt algorithm
pub(crate) unconstrained fn __primitive_root_log_size<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
) -> u32 {
    let mut target: [u128; N] = __helper_sub(params.modulus, __one());
    let mut result: u32 = 0;
    while !__get_bit(target, result) {
        result += 1;
    }
    result
}

/// Find a quadratic non-residue `g` where `g` is the smallest such value (unconstrained)
///       i.e. smallest `g` such that `g^{(p - 1)/2} = -1 (mod MOD)`
///       or smallest `g`, such that `x^2 - g = 0 (mod MOD)` has no solutions
///
/// ## Note
/// WARNING If the field is not prime, this function will enter an infinite loop!
pub(crate) unconstrained fn __quadratic_non_residue<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
) -> [u128; N] {
    let one: [u128; N] = __one();
    let neg_one: [u128; N] = __neg(params.modulus, one);

    let p_minus_one_over_two: [u128; N] = __shr1(__helper_sub(params.modulus, __one()));

    // We start with 2
    let mut target: [u128; N] = __increment(one);
    let mut expd: [u128; N] = __pow(params, target, p_minus_one_over_two);
    while !__eq(expd, neg_one) {
        target = __increment(target);
        expd = __pow(params, target, p_minus_one_over_two);
    }
    target
}

/// Compute the smallest `i`, such that `t^{2^i} = 1, t^{2^{i-1}} = -1 (mod MOD)` (unconstrained)
///
/// ## Note
/// Multiplicative order of t must divide 2^v2(MOD-1), otherwise you'll end up in an infinite loop!
pub(crate) unconstrained fn __tonelli_shanks_sqrt_find_i<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    t: [u128; N],
) -> u32 {
    let one: [u128; N] = __one();
    let mut c: [u128; N] = t;

    let mut i: u32 = 0;
    // Compute t^{2^k} until it hits 1 for the first time
    while !__eq(c, one) {
        c = __sqr::<N, MOD_BITS>(params, c);
        i += 1;
    }
    i
}
