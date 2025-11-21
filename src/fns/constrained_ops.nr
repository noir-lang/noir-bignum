use crate::constants::TWO_POW_120;
use crate::fns::{
    expressions::evaluate_quadratic_expression,
    unconstrained_helpers::{
        __add_with_flags, __from_field, __neg_with_flags, __sub_with_flags,
        __validate_gt_with_flags, __validate_in_field_compute_borrow_flags,
    },
    unconstrained_ops::{__add, __div, __mul, __neg, __sqr, __sub, __udiv_mod},
};

use crate::params::BigNumParams;

use std::cmp::Ordering;

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
 * gt 
 * check_gt_with_flags
 */

pub(crate) fn limbs_to_field<let N: u32, let MOD_BITS: u32>(
    _params: BigNumParams<N, MOD_BITS>,
    limbs: [u128; N],
) -> Field {
    if N > 2 {
        // validate that the limbs is less than the modulus the grumpkin modulus
        let mut grumpkin_modulus = [0; N];
        grumpkin_modulus[0] = 0x33e84879b9709143e1f593f0000001;
        grumpkin_modulus[1] = 0x4e72e131a029b85045b68181585d28;
        grumpkin_modulus[2] = 0x3064;
        validate_gt::<N, MOD_BITS>(grumpkin_modulus, limbs);
        // validate that the limbs are in range
        validate_in_range::<_, N, MOD_BITS>(limbs);
    }
    // validate the limbs sum up to the field value
    if N < 2 {
        limbs[0] as Field
    } else if N == 2 {
        validate_in_range::<_, N, MOD_BITS>(limbs);
        (limbs[0] + limbs[1] * TWO_POW_120) as Field
    } else {
        // validate_in_range::<N, 254>(limbs);
        (
            limbs[0] as Field
                + limbs[1] as Field * TWO_POW_120 as Field
                + limbs[2] as Field * TWO_POW_120 as Field * TWO_POW_120 as Field
        )
    }
}

pub(crate) fn from_field<let N: u32, let MOD_BITS: u32>(
    _params: BigNumParams<N, MOD_BITS>,
    field: Field,
) -> [u128; N] {
    // Safety: we check that the resulting limbs represent the intended field element
    // we check the bit length, the limbs being max 120 bits, and the value in total is less than the field modulus
    let result: [u128; N] = unsafe { __from_field::<N>(field) };
    if !std::runtime::is_unconstrained() {
        // validate the limbs are in range and the value in total is less than 2^254
        let mut grumpkin_modulus = [0; N];
        if N > 2 {
            grumpkin_modulus[0] = 0x33e84879b9709143e1f593f0000001;
            grumpkin_modulus[1] = 0x4e72e131a029b85045b68181585d28;
            grumpkin_modulus[2] = 0x3064;
        }
        if MOD_BITS > 253 {
            // this means that the field modulus is larger than grumpkin modulus so we have to check if the element fields in the field size are less than the grumpkin modulus.
            // also for correct params N is always larger than 3 here
            validate_gt::<N, MOD_BITS>(grumpkin_modulus, result);
        } else if MOD_BITS < 253 {
            // this means that the field modulus is smaller than grumpkin modulus so we have to check if the element fields in the field size
            validate_in_field(_params, result);
        } else {
            // this is the tricky part, when MOD_BITS = 253, so we have to compare the limbs of the modulus to the grumpkin modulus limbs
            // any bignum with 253 bits will have 3 limbs

            // if modulus is larger than grumpkin modulus, this will be true
            let mut gt_grumpkin = false;
            for i in 0..3 {
                if !gt_grumpkin {
                    if _params.modulus[2 - i] < grumpkin_modulus[2 - i] {
                        gt_grumpkin = true;
                    }
                }
            }
            let result_2 = if gt_grumpkin {
                _params.modulus
            } else {
                grumpkin_modulus
            };
            validate_gt::<N, MOD_BITS>(result_2, result);
        }

        // validate the limbs sum up to the field value
        let TWO_POW_120_FIELD = TWO_POW_120 as Field;
        let field_val = if N < 2 {
            result[0] as Field
        } else if N == 2 {
            validate_in_range::<_, N, MOD_BITS>(result);
            result[0] as Field + result[1] as Field * TWO_POW_120_FIELD
        } else {
            validate_in_range::<_, N, MOD_BITS>(result);
            result[0] as Field
                + result[1] as Field * TWO_POW_120_FIELD
                + result[2] as Field * TWO_POW_120_FIELD * TWO_POW_120_FIELD
        };
        assert_eq(field_val, field);
    }

    result
}

/**
* @brief given an input seed, generate a pseudorandom BigNum value
* @details we hash the input seed into `modulus_bits * 2` bits of entropy,
* which is then reduced into a BigNum value
* We use a hash function that can be modelled as a random oracle
* This function *should* produce an output that is a uniformly randomly distributed value modulo BigNum::modulus()
**/

pub(crate) fn derive_from_seed<let N: u32, let MOD_BITS: u32, let SeedBytes: u32>(
    params: BigNumParams<N, MOD_BITS>,
    seed: [u8; SeedBytes],
) -> [u128; N] {
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
        poseidon::poseidon2::Poseidon2::hash(rolling_hash_fields, (SeedBytes / 31) + 1);
    let mut rolling_hash: [Field; 2] = [compressed, 0];

    let num_hashes = (240 * N) / 254 + (((30 * N) % 32) != 0) as u32;
    for i in 0..num_hashes - 1 {
        let hash: Field = poseidon::poseidon2::Poseidon2::hash(rolling_hash, 2);
        let hash: [u8; 32] = hash.to_le_bytes();
        for j in 0..30 {
            hash_buffer[i * 30 + j] = hash[j];
        }
        rolling_hash[1] += 1;
    }

    {
        let hash: Field = poseidon::poseidon2::Poseidon2::hash(rolling_hash, 2);
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
    let mut bigfield_chunks: [[u128; N]; 4] = [[0; N]; 4];
    for k in 0..num_bigfield_chunks {
        let mut bigfield_limbs: [u128; N] = [0; N];
        let mut num_filled_bytes = (k * 30);
        if num_bytes >= num_filled_bytes {
            let mut num_remaining_bytes = num_bytes - num_filled_bytes;
            let mut num_remaining_limbs =
                (num_remaining_bytes / 15) + (num_remaining_bytes % 15 > 0) as u32;
            let mut more_than_N_minus_one_limbs = (num_remaining_limbs > (N - 1)) as u32;
            let mut num_limbs_in_bigfield = more_than_N_minus_one_limbs * (N - 1)
                + num_remaining_limbs * (1 - more_than_N_minus_one_limbs);

            for j in 0..num_limbs_in_bigfield {
                let mut limb: u128 = 0;
                for _ in 0..15 {
                    let need_more_bytes = (byte_ptr < num_bytes);
                    let mut byte = hash_buffer[byte_ptr];
                    limb *= (256 * need_more_bytes as u128 + (1 - need_more_bytes as u128));
                    limb += byte as u128 * need_more_bytes as u128;
                    byte_ptr += need_more_bytes as u32;
                }
                bigfield_limbs[num_limbs_in_bigfield - 1 - j] = limb;
            }
            bigfield_chunks[num_bigfield_chunks - 1 - k] = bigfield_limbs;
        }
    }

    let mut bigfield_rhs_limbs: [u128; N] = [0; N];
    bigfield_rhs_limbs[N - 1] = 1;
    validate_in_range::<_, _, MOD_BITS>(bigfield_rhs_limbs);

    let mut result: [u128; N] = [0; N];

    for i in 0..num_bigfield_chunks {
        let bigfield_lhs_limbs = bigfield_chunks[i];

        result = mul(params, result, bigfield_rhs_limbs);
        result = add(params, result, bigfield_lhs_limbs);
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
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) {
    let mut l: Field = 0;
    let mut r: Field = 0;
    let mut modulus_mod_n: Field = 0;
    for i in 0..N {
        l *= TWO_POW_120 as Field;
        r *= TWO_POW_120 as Field;
        modulus_mod_n *= TWO_POW_120 as Field;
        l += lhs[N - i - 1] as Field;
        r += rhs[N - i - 1] as Field;
        modulus_mod_n += params.modulus[N - i - 1] as Field;
    }

    // lhs can be either X mod N or P + X mod N
    // rhs can be either Y mod N or P + Y mod N
    // If lhs - rhs = 0 mod P then lhs - rhs = 0, P or -P mod N
    let diff = l - r;
    let target = diff * (diff + modulus_mod_n) * (diff - modulus_mod_n);
    assert(target != 0, "asssert_is_not_equal fail");
}

pub(crate) fn eq<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> bool {
    let diff = sub::<_, MOD_BITS>(params, lhs, rhs);
    // if self == other, possible values of `diff` will be `p` or `0`
    // (the subtract operator constrains diff to be < ceil(log(p)))
    // TODO: can do this more efficiently via witngen in unconstrained functions?
    let is_equal_modulus: bool = diff == params.modulus;
    let is_equal_zero: bool = diff.all(|elem| elem == 0);
    is_equal_modulus | is_equal_zero
}

pub(crate) fn is_zero<let N: u32, let MOD_BITS: u32>(val: [u128; N]) -> bool {
    val.all(|limb| limb == 0)
}

/**
* @brief Validate a BigNum instance is correctly range constrained to contain no more than Params::modulus_bits()
**/
pub(crate) fn validate_in_range<T, let N: u32, let MOD_BITS: u32>(limbs: [T; N])
where
    T: Into<Field>,
{
    for i in 0..(N - 1) {
        limbs[i].into().assert_max_bit_size::<120>();
    }

    limbs[N - 1].into().assert_max_bit_size::<MOD_BITS - ((N - 1) * 120)>();
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
pub(crate) fn validate_quotient_in_range<let N: u32, let MOD_BITS: u32>(limbs: [u128; N]) {
    for i in 0..(N) {
        (limbs[i] as Field).assert_max_bit_size::<120>();
    }
    // Note: replace magic number 6 with definition
    (limbs[N - 1] as Field).assert_max_bit_size::<MOD_BITS - ((N - 1) * 120) + 6>();
}

// validate that lhs - rhs does not underflow i.e. lhs > rhs
pub(crate) fn validate_gt<let N: u32, let MOD_BITS: u32>(lhs: [u128; N], rhs: [u128; N]) {
    // so we do... p - x - r = 0 and there might be borrow flags
    // a - b = r
    // p + a - b - r = 0
    let (underflow, result, borrow_flags) = unsafe { __validate_gt_with_flags(lhs, rhs) };
    validate_in_range::<_, _, MOD_BITS>(result);
    assert(!underflow, "BigNum::validate_gt check fails");
    check_gt_with_flags::<N, MOD_BITS>(lhs, rhs, result, borrow_flags);
}

// the constraining function for the results returned by __validate_gt_with_flags. this is used in both comparisons and validate gt
pub(crate) fn check_gt_with_flags<let N: u32, let MOD_BITS: u32>(
    lhs: [u128; N],
    rhs: [u128; N],
    result: [u128; N],
    borrow_flags: [bool; N - 1],
) {
    let mut addend: [Field; N] = [0; N];
    let result_limb = lhs[0] as Field - rhs[0] as Field + addend[0] - result[0] as Field
        + (borrow_flags[0] as Field) * TWO_POW_120 as Field;
    assert(result_limb == 0);

    for i in 1..N - 1 {
        let prev_borrow_sub_carry = borrow_flags[i - 1] as Field;
        let borrow_sub_carry = borrow_flags[i] as Field;
        let result_limb = lhs[i] as Field - rhs[i] as Field + addend[i] as Field
            - result[i] as Field
            - prev_borrow_sub_carry
            + borrow_sub_carry * TWO_POW_120 as Field;
        assert(result_limb == 0);
    }

    let result_limb = lhs[N - 1] as Field - rhs[N - 1] as Field + addend[N - 1] as Field
        - result[N - 1] as Field
        - borrow_flags[N - 2] as Field;
    assert(result_limb == 0);
}

pub(crate) fn validate_in_field<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    val: [u128; N],
) {
    // N.B. need to combine with validate_in_range if `self` limbs have not been range constrained
    let mut p_minus_self: [Field; N] = [0; N];
    let modulus: [u128; N] = params.modulus;
    for i in 0..N {
        p_minus_self[i] = (modulus[i] as Field - val[i] as Field);
    }
    let borrow_flags = unsafe { __validate_in_field_compute_borrow_flags(params, val) };
    p_minus_self[0] += (borrow_flags[0] as Field * TWO_POW_120 as Field);
    for i in 1..N - 1 {
        p_minus_self[i] +=
            (borrow_flags[i] as Field * TWO_POW_120 as Field - borrow_flags[i - 1] as Field);
    }
    p_minus_self[N - 1] -= (borrow_flags[N - 2] as Field);
    validate_in_range::<_, _, MOD_BITS>(p_minus_self);
}

// a comparison function. returns true if lhs > rhs and false otherwise
pub(crate) fn cmp<let N: u32, let MOD_BITS: u32>(lhs: [u128; N], rhs: [u128; N]) -> Ordering {
    let (underflow, result, borrow_flags) = unsafe { __validate_gt_with_flags(lhs, rhs) };
    // if underflow is true, swap lhs and rhs
    let (lhs, rhs) = if underflow { (rhs, lhs) } else { (lhs, rhs) };

    check_gt_with_flags::<N, MOD_BITS>(lhs, rhs, result, borrow_flags);
    if lhs == rhs {
        Ordering::equal()
    } else if underflow {
        Ordering::less()
    } else {
        Ordering::greater()
    }
}

// ------------------------------ ARITHMETIC FUNCTIONS ------------------------------

/// Negate a `BigNum` value
///
/// Computes `result = MOD - val` using limb-wise subtraction with borrow flags,
/// then constrains:
///   - all `result` limbs to be a valid `BigNum` value, and
///   - the subtraction relation with the borrow flags
///
/// ## Assumptions
/// - `val` is a valid `BigNum` in the range `0 <= val <= MOD`.
///
/// ## Soundness
/// This function constrains the following relations:
///     result[0]     = MOD[0]     - val[0]     + bf[0] * 2^{120}             < 2^{120}
///     result[i]     = MOD[i]     - val[i]     + bf[i] * 2^{120} - bf[i - 1] < 2^{120},  i = 1..N-2
///     result[N - 1] = MOD[N - 1] - val[N - 1]                   - bf[N - 2] < 2^{TOP_LIMB_BITS}
///
/// If all `MOD` and `val` limbs are valid `BigNum` limbs, these constraints
/// ensure that:
///   - the borrow flags `bf[i]` form a valid limb-wise subtraction chain, and
///   - no underflow can occur in the subtraction `MOD - val`.
///
/// ## Completeness
/// This function is complete for inputs in the range `0 <= val <= MOD`.
/// If a value `val > MOD` is passed in (while still `< 2^{MOD_BITS}`), the
/// constraints above will fail, since there is no valid borrow chain making
/// `MOD - val` a well-formed `BigNum`.
///
/// In practice, honest provers should not hit this case: all functions in this
/// module are expected to return values `< MOD`.
///
/// ## Note
/// This function returns `MOD` when `val` is zero.
pub(crate) fn neg<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    val: [u128; N],
) -> [u128; N] {
    if std::runtime::is_unconstrained() {
        // Safety: no need to constrain in an unconstrained runtime
        unsafe {
            __neg(params.modulus, val)
        }
    } else {
        // Safety: compute borrow flags out-of-circuit
        let (result, borrow_flags): ([u128; N], [bool; N - 1]) =
            unsafe { __neg_with_flags(params.modulus, val) };
        validate_in_range::<u128, N, MOD_BITS>(result);

        let result_limb: Field = (params.modulus[0] as Field)
            - (val[0] as Field)
            - (result[0] as Field)
            + (borrow_flags[0] as Field) * (TWO_POW_120 as Field);
        assert(result_limb == 0);

        for i in 1..N - 1 {
            let result_limb: Field = (params.modulus[i] as Field)
                - (val[i] as Field)
                - (result[i] as Field)
                + (borrow_flags[i] as Field) * (TWO_POW_120 as Field)
                - (borrow_flags[i - 1] as Field);
            assert(result_limb == 0);
        }

        let result_limb: Field = (params.modulus[N - 1] as Field)
            - (val[N - 1] as Field)
            - (result[N - 1] as Field)
            - (borrow_flags[N - 2] as Field);
        assert(result_limb == 0);
        result
    }
}

/// Add two `BigNum` values
///
/// Computes `result = lhs + rhs` using limb-wise addition with carry flags,
/// and an optional subtraction of `MOD` using borrow flags. The function then
/// constrains:
///   - all `result` limbs to be a valid `BigNum` value, and
///   - the addition/subtraction relation with the carry/borrow flags and the
///     `overflow_modulus` bit.
///
/// ## Assumptions
/// - All limbs of `lhs`, `rhs` and `MOD` are valid `BigNum` limbs
///   (120-bit for non-top limbs, `TOP_LIMB_BITS` for the top limb).
/// - Semantically, we intend to use this only with `0 <= lhs, rhs < MOD`,
///   even though the limb/range constraints allow values up to `< 2^{MOD_BITS}`.
///
/// ## Soundness (intended relation)
/// This function constrains the following equations:
///
///     result[0]     = lhs[0]     + rhs[0]
///                     - sub[0]
///                     + bf[0] * 2^{120}
///                     - cf[0]                                        < 2^{120}
///
///     result[i]     = lhs[i]     + rhs[i]
///                     - sub[i]
///                     + bf[i] * 2^{120}  - bf[i - 1]
///                     - cf[i] * 2^{120}  + cf[i - 1]                 < 2^{120},
///                     for i = 1..N-2
///
///     result[N - 1] = lhs[N - 1] + rhs[N - 1]
///                     - sub[N - 1]
///                     - bf[N - 2]
///                     + cf[N - 2]                                   < 2^{TOP_LIMB_BITS}
///
/// where:
///   - `bf[i]` are the borrow flags of the optional subtraction,
///   - `cf[i]` are the carry flags of the addition, and
///   - `sub` is either the zero vector or `MOD`, depending on the
///     `overflow_modulus` flag:
///         * `overflow_modulus = 0`  =>  `sub = 0`
///         * `overflow_modulus = 1`  =>  `sub = MOD`
///
/// If `lhs`, `rhs` and `MOD` are valid `BigNum` limbs and the witness for
/// `(bf, cf, overflow_modulus)` is the honest one produced by `__add_with_flags`,
/// these constraints enforce:
///   - a valid limb-wise carry chain for `lhs + rhs`, and
///   - a valid limb-wise subtraction chain for either `lhs + rhs` or
///     `lhs + rhs - MOD`, with no underflow in any limb.
///
/// Under these assumptions the constrained result equals:
///
///     result = (lhs + rhs) mod MOD
///
/// in the intended arithmetic.
///
/// ## Limitations / extra satisfying witnesses
///
/// The constraint system itself does **not** uniquely determine the carry/borrow
/// flags nor the `overflow_modulus` bit:
///
/// - For each limb `i`, `bf[i]` and `cf[i]` only appear in the combination
///   `bf[i] * 2^{120} - cf[i] * 2^{120}`. This means that both
///
///       (bf[i], cf[i]) = (0, 0)  and  (bf[i], cf[i]) = (1, 1)
///
///   give the same contribution to the equation. As a result, there are multiple
///   valid flag assignments for the *same* `lhs`, `rhs`, `sub` and `result`.
///
/// - More importantly, if `lhs + rhs` is greater than `MOD` but still strictly
///   less than `2^{MOD_BITS}`, there exist *spurious* witnesses where:
///     * `overflow_modulus` is set inconsistently with the true arithmetic
///       overflow, and
///     * the `(bf, cf)` flags are adjusted accordingly,
///
///   such that all equations above still hold and all `result` limbs remain
///   within range. In particular, when
///
///       lhs + rhs + MOD < 2^{MOD_BITS},
///
///   a malicious prover can "hide" an extra `MOD` inside the choice of
///   `overflow_modulus`, `bf` and `cf`, so that the circuit is satisfied by a
///   witness
///
/// Consequently, this function is only *conditionally* sound: we rely on the
/// out-of-circuit implementation of `__add_with_flags` to provide the honest
/// `(borrow_flags, carry_flags, overflow_modulus)` witness. Under that
/// assumption, the constrained `result` matches `lhs + rhs mod MOD`.
///
/// ## Completeness
///
/// For inputs in the range `0 <= lhs, rhs < MOD` and honest flags from
/// `__add_with_flags`, the constraints are complete: every valid `BigNum` sum
/// `lhs + rhs mod MOD` admits a satisfying assignment.
///
/// Inputs with `lhs` or `rhs` in `[MOD, 2^{MOD_BITS})` are still representable
/// as limb arrays and may admit satisfying witnesses, but then the operation
/// no longer corresponds to a unique, well-defined addition in the field
/// `Z / MOD Z`. Such uses are outside the intended semantics of this function.
pub(crate) fn add<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    if std::runtime::is_unconstrained() {
        // Safety: no need to constrain in unconstrained runtime
        unsafe {
            __add(params.modulus, lhs, rhs)
        }
    } else {
        // Safety: compute borrow/carry flags out-of-circuit
        let (result, carry_flags, borrow_flags, overflow_modulus): ([u128; N], [bool; N - 1], [bool; N - 1], bool) =
            unsafe { __add_with_flags(params.modulus, lhs, rhs) };
        validate_in_range::<u128, N, MOD_BITS>(result);

        let mut subtrahend: [u128; N] = if overflow_modulus {
            params.modulus
        } else {
            [0; N]
        };

        let result_limb: Field = (lhs[0] as Field) + (rhs[0] as Field)
            - (result[0] as Field)
            - (subtrahend[0] as Field)
            + (borrow_flags[0] as Field) * (TWO_POW_120 as Field)
            - (carry_flags[0] as Field) * (TWO_POW_120 as Field);
        assert(result_limb == 0);
        for i in 1..N - 1 {
            let result_limb: Field = (lhs[i] as Field) + (rhs[i] as Field)
                - (result[i] as Field)
                - (subtrahend[i] as Field)
                - (borrow_flags[i - 1] as Field)
                + (carry_flags[i - 1] as Field)
                + (borrow_flags[i] as Field) * (TWO_POW_120 as Field)
                - (carry_flags[i] as Field) * (TWO_POW_120 as Field);
            assert(result_limb == 0);
        }
        let result_limb: Field = (lhs[N - 1] as Field) + (rhs[N - 1] as Field)
            - (result[N - 1] as Field)
            - (subtrahend[N - 1] as Field)
            - (borrow_flags[N - 2] as Field)
            + (carry_flags[N - 2] as Field);
        assert(result_limb == 0);
        result
    }
}

/// Subtract two `BigNum` values
///
/// Computes `result = lhs - rhs` using limb-wise subtraction with borrow flags,
/// and an optional addition of `MOD` using carry flags. The function then
/// constrains:
///   - all `result` limbs to be a valid `BigNum` value, and
///   - the subtraction/addition relation with the carry/borrow flags and the
///     `underflow_modulus` bit.
///
/// ## Assumptions
/// - All limbs of `lhs`, `rhs` and `MOD` are valid `BigNum` limbs
///   (120-bit for non-top limbs, `TOP_LIMB_BITS` for the top limb).
/// - Semantically, we intend to use this only with `0 <= lhs, rhs < MOD`,
///   even though the limb/range constraints allow values up to `< 2^{MOD_BITS}`.
///
/// ## Soundness (intended relation)
/// This function constrains the following equations:
///
///     result[0]     = lhs[0]     - rhs[0]
///                     + add[0]
///                     + bf[0] * 2^{120}
///                     - cf[0]                                        < 2^{120}
///
///     result[i]     = lhs[i]     - rhs[i]
///                     + add[i]
///                     + bf[i] * 2^{120}  - bf[i - 1]
///                     - cf[i] * 2^{120}  + cf[i - 1]                 < 2^{120},
///                     for i = 1..N-2
///
///     result[N - 1] = lhs[N - 1] - rhs[N - 1]
///                     + add[N - 1]
///                     - bf[N - 2]
///                     + cf[N - 2]                                   < 2^{TOP_LIMB_BITS}
///
/// where:
///   - `bf[i]` are the borrow flags of the subtraction,
///   - `cf[i]` are the carry flags of the optional addition, and
///   - `add` is either the zero vector or `MOD`, depending on the
///     `underflow_modulus` flag:
///         * `underflow_modulus = 0`  =>  `add = 0`
///         * `underflow_modulus = 1`  =>  `add = MOD`
///
/// If `lhs`, `rhs` and `MOD` are valid `BigNum` limbs and the witness for
/// `(bf, cf, underflow_modulus)` is the honest one produced by `__sub_with_flags`,
/// these constraints enforce:
///   - a valid limb-wise borrow chain for `lhs - rhs`, and
///   - a valid limb-wise addition chain for either `lhs - rhs` or
///     `lhs - rhs + MOD`, with no underflow in any limb.
///
/// Under these assumptions the constrained result equals:
///
///     result = (lhs - rhs) mod MOD
///
/// in the intended arithmetic.
///
/// ## Limitations / extra satisfying witnesses
///
/// The constraint system itself does **not** uniquely determine the carry/borrow
/// flags nor the `underflow_modulus` bit:
///
/// - For each limb `i`, `bf[i]` and `cf[i]` only appear in the combination
///   `bf[i] * 2^{120} - cf[i] * 2^{120}`. This means that both
///
///       (bf[i], cf[i]) = (0, 0)  and  (bf[i], cf[i]) = (1, 1)
///
///   give the same contribution to the equation. As a result, there are multiple
///   valid flag assignments for the *same* `lhs`, `rhs`, `add` and `result`.
///
/// - More importantly, when `lhs < rhs`, the true field result is
///
///       lhs - rhs + MOD,
///
///   and as long as
///
///       lhs - rhs + MOD < 2^{MOD_BITS},
///
///   a malicious prover can:
///     * set `underflow_modulus` inconsistently with the true underflow, and
///     * adjust the `(bf, cf)` flags accordingly,
///
///   such that all equations above still hold and all `result` limbs remain
///   within range. In other words, the circuit can be satisfied by a witness
///   that does **not** correspond to the unique intended subtraction modulo
///   `MOD` for some inputs with `lhs < rhs`.
///
/// Consequently, this function is only *conditionally* sound: we rely on the
/// out-of-circuit implementation of `__sub_with_flags` to provide the honest
/// `(borrow_flags, carry_flags, underflow_modulus)` witness. Under that
/// assumption, the constrained `result` matches `(lhs - rhs) mod MOD`.
///
/// ## Completeness
///
/// For inputs in the range `0 <= lhs, rhs < MOD` and honest flags from
/// `__sub_with_flags`, the constraints are complete: every valid `BigNum`
/// difference `(lhs - rhs) mod MOD` admits a satisfying assignment.
///
/// Inputs with `lhs` or `rhs` in `[MOD, 2^{MOD_BITS})` are still representable
/// as limb arrays and may admit satisfying witnesses, but then the operation
/// no longer corresponds to a unique, well-defined subtraction in the field
/// `Z / MOD Z`. Such uses are outside the intended semantics of this function.
pub(crate) fn sub<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    if std::runtime::is_unconstrained() {
        // Safety: no need to constrain in unconstrained runtime
        unsafe {
            __sub(params.modulus, lhs, rhs)
        }
    } else {
        // Safety: we constrain carry, borrow, underflow and result immediately
        let (result, carry_flags, borrow_flags, underflow_modulus): ([u128; N], [bool; N - 1], [bool; N - 1], bool) =
            unsafe { __sub_with_flags(params.modulus, lhs, rhs) };
        validate_in_range::<u128, N, MOD_BITS>(result);

        let mut addend: [u128; N] = if underflow_modulus {
            params.modulus
        } else {
            [0; N]
        };

        let result_limb: Field = (lhs[0] as Field) - (rhs[0] as Field) - (result[0] as Field)
            + (addend[0] as Field)
            + (borrow_flags[0] as Field) * (TWO_POW_120 as Field)
            - (carry_flags[0] as Field) * (TWO_POW_120 as Field);
        assert(result_limb == 0);

        for i in 1..N - 1 {
            let result_limb: Field = (lhs[i] as Field) - (rhs[i] as Field) - (result[i] as Field)
                + (addend[i] as Field)
                + (borrow_flags[i] as Field) * (TWO_POW_120 as Field)
                - (carry_flags[i] as Field) * (TWO_POW_120 as Field)
                - (borrow_flags[i - 1] as Field)
                + (carry_flags[i - 1] as Field);
            assert(result_limb == 0);
        }
        let result_limb: Field = (lhs[N - 1] as Field)
            - (rhs[N - 1] as Field)
            - (result[N - 1] as Field)
            + (addend[N - 1] as Field)
            - (borrow_flags[N - 2] as Field)
            + (carry_flags[N - 2] as Field);
        assert(result_limb == 0);
        result
    }
}

/// Compute the `BigNum` multiplication
///
/// Computes `result = lhs * rhs mod MOD` by:
///   1. Computing `result` out of circuit via `__mul`.
///   2. Constraining the quadratic relation `lhs * rhs - result = 0` with
///      `evaluate_quadratic_expression`.
///
/// ## Soundness
/// Soundness reduces to `evaluate_quadratic_expression` for the relation
/// `lhs * rhs - result = 0`
///
/// ## Note
/// When possible, prefer expressing your computation directly as a quadratic
///   relation and calling `evaluate_quadratic_expression` instead of using `mul`
pub(crate) fn mul<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    // Safety: we constrain the multiplication result immediately after
    let result: [u128; N] = unsafe { __mul::<N, MOD_BITS>(params, lhs, rhs) };
    if !std::runtime::is_unconstrained() {
        // lhs * rhs - result = 0
        evaluate_quadratic_expression(
            params,
            [[lhs]],
            [[false]],
            [[rhs]],
            [[false]],
            [result],
            [true],
        );
    }
    result
}

/// Compute the `BigNum` squaring
///
/// Computes `result = val * val mod MOD` by:
///   1. Computing `result` out of circuit via `__sqr`.
///   2. Constraining the quadratic relation `val * val - result = 0` with
///      `evaluate_quadratic_expression`.
///
/// ## Soundness
/// Soundness reduces to `evaluate_quadratic_expression` for the relation
/// `val * val - result = 0`
///
/// ## Note
/// When possible, prefer expressing your computation directly as a quadratic
///   relation and calling `evaluate_quadratic_expression` instead of using `sqr`
pub(crate) fn sqr<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    val: [u128; N],
) -> [u128; N] {
    // Safety: we constrain the multiplication result immediately after
    let result: [u128; N] = unsafe { __sqr::<_, MOD_BITS>(params, val) };
    if !std::runtime::is_unconstrained() {
        // val * val - result = 0
        evaluate_quadratic_expression(
            params,
            [[val]],
            [[false]],
            [[val]],
            [[false]],
            [result],
            [true],
        );
    }
    result
}

/// Compute the `BigNum` division
///
/// Computes `result = lhs * rhs^{-1} mod MOD` by:
///   1. Computing `result` out of circuit via `__div`.
///   2. Constraining the quadratic relation `result * rhs - lhs = 0` with
///      `evaluate_quadratic_expression`.
///   3. Enforcing `rhs != 0`.
///
/// ## Soundness
/// Soundness reduces to `evaluate_quadratic_expression` for the relation
/// `result * rhs - lhs = 0`, together with the non-zero check on `rhs` and the
/// assumption that `MOD` has multiplicative inverses for all non-zero elements
/// (`params.has_multiplicative_inverse = true`).
///
/// ## Note
/// - This is **expensive** in witness time due to modular inversion.
/// - When possible, prefer expressing your computation directly as a quadratic
///   relation and calling `evaluate_quadratic_expression` instead of using `div`.
/// - In the unconstrained runtime, the behavior of `__div` on zero divisors is
///   not constrained by this function.
pub(crate) fn div<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    assert(params.has_multiplicative_inverse);
    // Safety: We constrain the result of division immediately after
    let result: [u128; N] = unsafe { __div::<_, MOD_BITS>(params, lhs, rhs) };
    if !std::runtime::is_unconstrained() {
        // result * rhs - lhs = 0
        evaluate_quadratic_expression(
            params,
            [[result]],
            [[false]],
            [[rhs]],
            [[false]],
            [lhs],
            [true],
        );
        assert(!is_zero::<N, MOD_BITS>(rhs));
    }
    result
}

/// Compute the `BigNum` integer division with remainder
///
/// Computes `quotient = floor(numerator / divisor)` and
/// `remainder = numerator % divisor` by:
///   1. Computing `(quotient, remainder)` out of circuit via `__udiv_mod`.
///   2. Constraining the quadratic relation
///        quotient * divisor + remainder - numerator = 0
///      with `evaluate_quadratic_expression`.
///   3. Enforcing `divisor != 0` and `remainder < divisor`.
///
/// ## Soundness
/// Soundness reduces to `evaluate_quadratic_expression` for the relation
///     quotient * divisor + remainder - numerator = 0,
/// together with:
///   - the non-zero check on `divisor`, and
///   - the `remainder < divisor` check enforced via `validate_gt`.
///
/// Under these checks, any satisfying assignment corresponds to a valid
/// integer division `numerator = quotient * divisor + remainder` with
/// `0 <= remainder < divisor`.
pub(crate) fn udiv_mod<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    numerator: [u128; N],
    divisor: [u128; N],
) -> ([u128; N], [u128; N]) {
    // Safety: We constrain the result of udiv immediately after
    let (quotient, remainder): ([u128; N], [u128; N]) = unsafe { __udiv_mod(numerator, divisor) };
    if !std::runtime::is_unconstrained() {
        // quotient * divisor + remainder - numerator = 0
        // remainder < divisor
        // divisor != 0
        evaluate_quadratic_expression(
            params,
            [[quotient]],
            [[false]],
            [[divisor]],
            [[false]],
            [numerator, remainder],
            [true, false],
        );
        validate_gt::<N, MOD_BITS>(divisor, remainder);
        assert(!is_zero::<N, MOD_BITS>(divisor));
    }
    (quotient, remainder)
}

/// Compute the `BigNum` integer division
///
/// Returns `floor(numerator / divisor)`.
/// All constraints and soundness details are handled inside `udiv_mod`.
pub(crate) fn udiv<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    numerator: [u128; N],
    divisor: [u128; N],
) -> [u128; N] {
    udiv_mod::<N, MOD_BITS>(params, numerator, divisor).0
}

/// Compute the `BigNum` remainder
///
/// Returns `numerator % divisor`.
/// All constraints and soundness details are handled inside `udiv_mod`.
pub(crate) fn umod<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    numerator: [u128; N],
    divisor: [u128; N],
) -> [u128; N] {
    udiv_mod::<N, MOD_BITS>(params, numerator, divisor).1
}
