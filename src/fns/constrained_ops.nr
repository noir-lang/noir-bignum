use crate::constants::TWO_POW_120;

use crate::fns::{
    expressions::evaluate_quadratic_expression,
    unconstrained_helpers::{
        __add_with_flags, __from_field, __neg_with_flags, __sub_with_flags,
        __validate_gte_with_flags, __validate_in_field_compute_borrow_flags,
    },
    unconstrained_ops::{__add, __div, __mul, __neg, __sub, __udiv_mod},
};

use crate::params::BigNumParams;

use std::cmp::Ordering;

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

// ------------------------------ COMPARISON FUNCTIONS ------------------------------

/// Validate lhs != rhs
///
/// We compare `A` and `B` via their encodings in the circuit `Field`
///
/// Under our range assumptions, equality in `Field` implies equality of the underlying
/// `BigNum` values, hence equality (mod `MOD`)
///
/// In this library it is possible that A or B is a little bit greater than `MOD`
/// So A == B (mod `MOD`) implies that A == B, A == B + MOD or A == B - MOD over the integers
/// Hence we can compute everything (mod p) and constrain that
/// (A - B) * (A - B + MOD) * (A - B - MOD) != 0 (mod p)
///
/// ## Soundness
/// This method is *sound* for checking `A != B (mod MOD)`
///
/// If `A == B (mod MOD)`, then `A - B` is in `{0, +-MOD}` as an integer,
/// so one of the factors `A-B`, `A-B+MOD`, `A-B-MOD` is zero in `Field`, and the product is zero
/// Therefore, whenever the assertion `target != 0` holds, we must have `A != B (mod MOD)`
/// under our range assumptions
///
/// ## Completeness
/// In general, this method is not *complete*: if the admissible range of `A` and `B`
/// is large enough relative to the circuit `Field` prime `p`, an honest prover with
/// `A != B (mod MOD)` can still hit an alias where
///     (A - B) * (A - B + MOD) * (A - B - MOD) == 0 (mod p),
/// i.e.
///     - A = B      (mod p), or
///     - A = B + MOD (mod p), or
///     - A = B - MOD (mod p).
///
/// For random `A, B` in such a wide range, the probability of this collision is
/// roughly 3/p.
///
/// In case `MOD` < `p` this function becomes *complete*
pub(crate) fn assert_is_not_equal<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) {
    let mut l: Field = 0;
    let mut r: Field = 0;
    let mut modulus_mod_p: Field = 0;
    for i in 0..N {
        l *= TWO_POW_120 as Field;
        r *= TWO_POW_120 as Field;
        modulus_mod_p *= TWO_POW_120 as Field;

        l += lhs[N - i - 1] as Field;
        r += rhs[N - i - 1] as Field;
        modulus_mod_p += params.modulus[N - i - 1] as Field;
    }

    let diff: Field = l - r;
    let target: Field = diff * (diff + modulus_mod_p) * (diff - modulus_mod_p);
    assert(target != 0, "assert_is_not_equal fail");
}

/// Compute equality flag
///
/// A == B (mod MOD)
/// We compute A - B and check whether it is `0` or `MOD`
/// This is due to subtract constrains the diff value to be < 2^MOD_BITS, not < `MOD`
///
/// ## Soundness
/// This function is conditionally *sound*. See `sub` for details
///
/// ## Completeness
/// This function is *complete*. An honest prover will always be able to execute it.
///
/// ## TODO
/// can do this more efficiently via witngen in unconstrained functions?
pub(crate) fn eq<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> bool {
    let diff: [u128; N] = sub::<N, MOD_BITS>(params, lhs, rhs);
    is_zero::<N, MOD_BITS>(params, diff)
}

/// Validate that `val` is not equal to zero when interpreted as an integer.
///
/// This enforces that at least one limb of `val` is non-zero.
/// It does *not* check "BigNum zero" in the modular sense (e.g. it
/// treats `MOD` as non-zero).
///
/// ## Assumptions
/// * Each limb of `val` is range-constrained to be a 120-bit value:
///   `0 <= val[i] < 2^120`.
/// * For our concrete fields and limb counts we have `N * 2^120 < p`,
///   so the sum of all limbs fits strictly inside the field modulus.
///
/// ## Completeness
/// If `val` is non-zero as an integer, then at least one limb is non-zero,
/// so the integer sum of the limbs satisfies `0 < limb_sum < p`. In this
/// case `limb_sum != 0` in the `Field`, and the assertion passes.
///
/// ## Soundness
/// If all limbs of `val` are zero, then `limb_sum` is zero as an integer
/// and as a field element, so the assertion fails. A witness representing
/// the zero integer can never satisfy this check.
///
/// ## Note
/// This is slightly cheaper than doing `val != [0; N]`, as we avoid
/// creating per-limb boolean equalities and chaining them with `and`s.
pub(crate) fn assert_is_not_zero_integer<let N: u32>(val: [u128; N]) {
    let mut limb_sum: Field = 0;
    for i in 0..N {
        limb_sum += val[i] as Field;
    }
    assert(limb_sum != 0, "assert_is_not_zero_integer fail");
}

/// Check whether `val` is the zero `BigNum` in the integer sense.
///
/// This returns `true` iff all limbs of `val` are zero. It does *not*
/// treat `MOD` as zero; for modular `BigNum` zero use `is_zero`.
///
/// See `assert_is_not_zero_integer` for the underlying assumptions.
///
/// ## Note
/// This is slightly cheaper than testing `val == [0; N]`, as we avoid
/// creating per-limb boolean equalities and chaining them with `and`s.
pub(crate) fn is_zero_integer<let N: u32>(val: [u128; N]) -> bool {
    let mut limb_sum: Field = 0;
    for i in 0..N {
        limb_sum += val[i] as Field;
    }
    limb_sum == 0
}

/// Validate that a `BigNum` value is not zero modulo `MOD`.
///
/// Convenience wrapper around `assert_is_not_equal`.
pub(crate) fn assert_is_not_zero<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    val: [u128; N],
) {
    assert_is_not_equal::<N, MOD_BITS>(params, val, [0; N]);
}

/// Check whether a `BigNum` value is zero modulo `MOD`.
///
/// This treats both the all-zero limb vector and `params.modulus` as
/// representing zero. It assumes that all valid `BigNum` values are
/// range-constrained so that no other representatives of `0 mod MOD`
/// can appear.
///
/// ## Note
/// This is cheaper than calling `eq(val, [0; N])`
pub(crate) fn is_zero<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    val: [u128; N],
) -> bool {
    is_zero_integer(val) | (val == params.modulus)
}

/// Validate a `BigNum` instance is correctly range constrained to contain no more than `MOD_BITS` bits
///
/// Constrain the `BigNum` instance to be < 2^MOD_BITS by:
///     - Constraining each limb(0..N-2) to be 120-bit limb
///     - Constraining the last limb to be `MOD_BITS - 120 * (N - 1)`
///
/// ## Note
/// This can be a very expensive function, when the `TOP_LIMB_BITS` is uncommon
///
/// For example: BLS12_377Fr, with `TOP_LIMB_BITS`=13
/// It creates a new 13-bit range table, which consists of roughly 3k variables
/// And ~2k circuit gates
///
/// Compare this to BLS12_377Fq, with `TOP_LIMB_BITS`=17
/// It is nicely decomposed into
/// 14-bit range check and 3-bit range check - much much cheaper, since 14-bit range checks
/// are already pretty common for 120-bit range checks
pub(crate) fn validate_in_range<T, let N: u32, let MOD_BITS: u32>(limbs: [T; N])
where
    T: Into<Field>,
{
    for i in 0..(N - 1) {
        limbs[i].into().assert_max_bit_size::<120>();
    }

    limbs[N - 1].into().assert_max_bit_size::<MOD_BITS - ((N - 1) * 120)>();
}

/// Validate quotient produced from `evaluate_quadratic_expression` is well-formed
///
/// Because the inputs into `evaluate_quadratic_expression` may cause the quotient to extend beyond `Params::modulus_bits`.
///           We allow the quotient to extend `6` bits beyond `Params::modulus_bits()`
///           Why is this?
///           several factors:    1. quotient * modulus , limbs cannot overflow `Field` boundary (254 bits)
///                               2. in `evaluate_quadratic_expression`, we require that for `expression - quotient * modulus`,
///                                  limbs cannot exceed `246` bits (246 magic number due to a higher number adding extra range check gates)
///           because of factor 2 and the fact that modulus limbs are 120 bits, quotient limbs cannot be > 126 bits
pub(crate) fn validate_quotient_in_range<let N: u32, let MOD_BITS: u32>(limbs: [u128; N]) {
    for i in 0..(N - 1) {
        (limbs[i] as Field).assert_max_bit_size::<120>();
    }
    (limbs[N - 1] as Field).assert_max_bit_size::<MOD_BITS - (N - 1) * 120 + 6>();
}

/// Validate that `lhs - rhs` does not underflow i.e. that lhs > rhs over the integers
///
/// Compute `result = lhs - rhs` along with `borrow_flags`,
/// then constrain `result` to be a valid `BigNum` value.
///
/// ## Completeness
/// This function is complete and will work only if `lhs > rhs` over the integers.
///
/// ## Soundness
/// This function is sound:
///     result[0]     = lhs[0]     - rhs[0]     + bf[0] * 2^{120}             < 2^{120}
///     result[i]     = lhs[i]     - rhs[i]     + bf[i] * 2^{120} - bf[i - 1] < 2^{120},  i = 1..N-2
///     result[N - 1] = lhs[N - 1] - rhs[N - 1]                   - bf[N - 2] < 2^{TOP_LIMB_BITS}
///     result != 0
///
/// If `lhs < rhs`, then some limb of `result` would have to borrow from a higher limb,
/// which is impossible because the top limb cannot borrow
/// Without the extra borrow, the resulting difference will be wrapped around the `Field` modulus
/// And won't satisfy the range constraint, since all the limbs are < 2^120
///
/// ## Note
/// `assert_is_not_zero_integer(result)` is crucial. Without it, we could always provide
/// two identical inputs `x`, `x` and set `borrow_flags = [false; N]`,
/// which would satisfy the limb constraints.
///
/// Also note that `underflow` is not properly constrained, so it just hangs there for
/// completeness
pub(crate) fn validate_gt<let N: u32, let MOD_BITS: u32>(lhs: [u128; N], rhs: [u128; N]) {
    // Safety: compute borrow flags out-of-circuit
    let (underflow, result, borrow_flags): (bool, [u128; N], [bool; N - 1]) =
        unsafe { __validate_gte_with_flags(lhs, rhs) };

    // Completeness: require that no underflow occurred
    assert(!underflow, "validate_gt fail");

    // Constrain the `result` to be a valid `BigNum` value
    validate_in_range::<u128, N, MOD_BITS>(result);
    // Constrain it to be strict inequality
    assert_is_not_zero_integer(result);

    // Constrain `result` and `borrow_flags` to match the expected arithmetic
    check_gte_with_flags(lhs, rhs, result, borrow_flags);
}

/// Constraining function for the results of `__validate_gte_with_flags`,
/// used by both `cmp` and `validate gt`
///
/// This function checks the relations between `lhs`, `rhs`, `result` adn `borrow_flags`:
///     lhs[0]     - rhs[0]     - result[0]     + bf[0] * 2^{120}             = 0
///     lhs[i]     - rhs[i]     - result[i]     + bf[i] * 2^{120} - bf[i - 1] = 0,  i = 1..N-2
///     lhs[N - 1] - rhs[N - 1] - result[N - 1]                   - bf[N - 2] = 0
pub(crate) fn check_gte_with_flags<let N: u32>(
    lhs: [u128; N],
    rhs: [u128; N],
    result: [u128; N],
    borrow_flags: [bool; N - 1],
) {
    let result_limb: Field = (lhs[0] as Field) - (rhs[0] as Field) - (result[0] as Field)
        + (borrow_flags[0] as Field) * TWO_POW_120 as Field;
    assert(result_limb == 0);

    for i in 1..N - 1 {
        let result_limb: Field = (lhs[i] as Field) - (rhs[i] as Field) - (result[i] as Field)
            + (borrow_flags[i] as Field) * (TWO_POW_120 as Field)
            - (borrow_flags[i - 1] as Field);
        assert(result_limb == 0);
    }

    let result_limb: Field = (lhs[N - 1] as Field)
        - (rhs[N - 1] as Field)
        - (result[N - 1] as Field)
        - (borrow_flags[N - 2] as Field);
    assert(result_limb == 0);
}

/// Validate that `val` <= `MOD`
///
/// Compute `result = MOD - val` along with `borrow_flags`,
/// then constrain `result` to be a valid `BigNum` value.
///
/// Basically the same as `validate_gt` but we compute the result on the fly
/// It is just a bit more optimized as we expect each `BigNum` value to be \leq `MOD`
///
/// ## Note
/// In contrast to `validate_gt`, we allow the value to be `MOD`
/// Since it is consistent with the rest of the library
pub(crate) fn validate_in_field<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    val: [u128; N],
) {
    let modulus: [u128; N] = params.modulus;

    // Safety: compute borrow flags out-of-circuit
    let borrow_flags: [bool; (N - 1)] =
        unsafe { __validate_in_field_compute_borrow_flags(params, val) };

    let mut p_minus_self: [Field; N] = [0; N];
    p_minus_self[0] = (modulus[0] as Field) - (val[0] as Field)
        + (borrow_flags[0] as Field) * (TWO_POW_120 as Field);
    for i in 1..N - 1 {
        p_minus_self[i] = (modulus[i] as Field) - (val[i] as Field)
            + (borrow_flags[i] as Field) * (TWO_POW_120 as Field)
            - (borrow_flags[i - 1] as Field);
    }
    p_minus_self[N - 1] =
        (modulus[N - 1] as Field) - (val[N - 1] as Field) - (borrow_flags[N - 2] as Field);
    validate_in_range::<Field, N, MOD_BITS>(p_minus_self);
}

/// Compare two `BigNum` values
///
/// Returns `lhs > rhs`
///
/// ## Note
/// This is a strict value comparison over the integers,
/// the values do not have to be reduced modulo `MOD`.
pub(crate) fn cmp<let N: u32, let MOD_BITS: u32>(lhs: [u128; N], rhs: [u128; N]) -> Ordering {
    // Safety: we constrain:
    //        - `result` and `borrow_flags` with `check_gte_with_flags`
    //        - `borrow_flags` are also booleans
    //        - `underflow` with the following swap and (bool)
    let (underflow, result, borrow_flags): (bool, [u128; N], [bool; N - 1]) =
        unsafe { __validate_gte_with_flags(lhs, rhs) };

    // if underflow is true, swap lhs and rhs
    let (lhs, rhs): ([u128; N], [u128; N]) = if underflow { (rhs, lhs) } else { (lhs, rhs) };

    // Constrain the `result` to be a valid `BigNum` value
    validate_in_range::<u128, N, MOD_BITS>(result);

    // Constrain subtraction: result = lhs - rhs with borrow_flags
    check_gte_with_flags(lhs, rhs, result, borrow_flags);

    if lhs == rhs {
        Ordering::equal()
    } else if underflow {
        Ordering::less()
    } else {
        Ordering::greater()
    }
}

pub(crate) fn neg<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    val: [u128; N],
) -> [u128; N] {
    if std::runtime::is_unconstrained() {
        // Safety: not need to constrain in unconstrained runtime
        unsafe {
            __neg(params.modulus, val)
        }
    } else {
        // so we do... p - x - r = 0 and there might be borrow flags
        let (result, borrow_flags) = unsafe { __neg_with_flags(params.modulus, val) };
        validate_in_range::<_, _, MOD_BITS>(result);
        let modulus = params.modulus;
        let result_limb = modulus[0] + (borrow_flags[0] as u128 * TWO_POW_120) - val[0] - result[0];
        assert(result_limb == 0);
        for i in 1..N - 1 {
            let result_limb = modulus[i] + (borrow_flags[i] as u128 * TWO_POW_120)
                - val[i]
                - result[i]
                - borrow_flags[i - 1] as u128;
            assert(result_limb == 0);
        }
        let result_limb = modulus[N - 1] - val[N - 1] - result[N - 1] - borrow_flags[N - 2] as u128;
        assert(result_limb == 0);
        result
    }
}

pub(crate) fn add<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    if std::runtime::is_unconstrained() {
        // Safety: not need to constrain in unconstrained runtime
        unsafe {
            // __add_u128(params, lhs, rhs)
            __add(params.modulus, lhs, rhs)
        }
    } else {
        // so we do... p - x - r = 0 and there might be borrow flags
        let (result, carry_flags, borrow_flags, overflow_modulus) =
            unsafe { __add_with_flags(params.modulus, lhs, rhs) };
        validate_in_range::<_, _, MOD_BITS>(result);
        let modulus = params.modulus;

        let mut subtrahend: [u128; N] = [0; N];
        if (overflow_modulus) {
            subtrahend = modulus;
        }
        let borrow_sub_carry = borrow_flags[0] as Field - carry_flags[0] as Field;
        let result_limb = lhs[0] as Field + rhs[0] as Field
            - subtrahend[0] as Field
            - result[0] as Field
            + borrow_sub_carry * TWO_POW_120 as Field;
        assert(result_limb == 0);
        for i in 1..N - 1 {
            let prev_borrow_sub_carry = borrow_flags[i - 1] as Field - carry_flags[i - 1] as Field;
            let borrow_sub_carry = borrow_flags[i] as Field - carry_flags[i] as Field;
            let result_limb = lhs[i] as Field + rhs[i] as Field
                - subtrahend[i] as Field
                - result[i] as Field
                - prev_borrow_sub_carry
                + borrow_sub_carry * TWO_POW_120 as Field;
            assert(result_limb == 0);
        }
        let borrow_sub_carry = borrow_flags[N - 2] as Field - carry_flags[N - 2] as Field;
        let result_limb = lhs[N - 1] as Field + rhs[N - 1] as Field
            - subtrahend[N - 1] as Field
            - result[N - 1] as Field
            - borrow_sub_carry as Field;
        assert(result_limb == 0);
        result
    }
}

pub(crate) fn sub<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    if std::runtime::is_unconstrained() {
        // Safety: not need to constrain in unconstrained runtime
        unsafe {
            __sub(params.modulus, lhs, rhs)
        }
    } else {
        // so we do... p - x - r = 0 and there might be borrow flags
        // a - b = r
        // p + a - b - r = 0
        let (result, carry_flags, borrow_flags, underflow) =
            unsafe { __sub_with_flags(params.modulus, lhs, rhs) };

        validate_in_range::<_, _, MOD_BITS>(result);
        let modulus = params.modulus;

        let mut addend: [u128; N] = [0; N];
        if (underflow) {
            addend = modulus;
        }

        let borrow_sub_carry = borrow_flags[0] as Field - carry_flags[0] as Field;
        let result_limb = borrow_sub_carry * TWO_POW_120 as Field
            + addend[0] as Field
            + lhs[0] as Field
            - rhs[0] as Field
            - result[0] as Field;
        assert(result_limb == 0);
        for i in 1..N - 1 {
            let prev_borrow_sub_carry = borrow_flags[i - 1] as Field - carry_flags[i - 1] as Field;
            let borrow_sub_carry = borrow_flags[i] as Field - carry_flags[i] as Field;
            let result_limb = borrow_sub_carry * TWO_POW_120 as Field
                + addend[i] as Field
                + lhs[i] as Field
                - rhs[i] as Field
                - result[i] as Field
                - prev_borrow_sub_carry;
            assert(result_limb == 0);
        }
        let borrow_sub_carry = borrow_flags[N - 2] as Field - carry_flags[N - 2] as Field;
        let result_limb = addend[N - 1] as Field + lhs[N - 1] as Field
            - rhs[N - 1] as Field
            - result[N - 1] as Field
            - borrow_sub_carry as Field;
        assert(result_limb == 0);
        result
    }
}

// Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
//       via evaluate_quadratic_expression
// e.g. performing a sum of multiple multiplications and additions via `evaluate_quadratic_expression`
//      will create much fewer constraints than calling `mul` and `add` directly
pub(crate) fn mul<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    let result = unsafe { __mul::<_, MOD_BITS>(params, lhs, rhs) };
    if !std::runtime::is_unconstrained() {
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

// Note: this method is expensive! Witness computation is extremely expensive as it requires modular exponentiation
pub(crate) fn div<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    assert(
        params.has_multiplicative_inverse,
        "BigNum has no multiplicative inverse. Use udiv for unsigned integer division",
    );
    let result = unsafe { __div::<_, MOD_BITS>(params, lhs, rhs) };
    if !std::runtime::is_unconstrained() {
        evaluate_quadratic_expression(
            params,
            [[result]],
            [[false]],
            [[rhs]],
            [[false]],
            [lhs],
            [true],
        );
    }
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
    params: BigNumParams<N, MOD_BITS>,
    numerator: [u128; N],
    divisor: [u128; N],
) -> ([u128; N], [u128; N]) {
    let (quotient, remainder) = unsafe { __udiv_mod(numerator, divisor) };
    if !std::runtime::is_unconstrained() {
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
    }
    (quotient, remainder)
}

/**
* @brief udiv_mod performs integer division between numerator, divisor
*
* i.e. return param is floor(numerator / divisor)
**/
pub(crate) fn udiv<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    numerator: [u128; N],
    divisor: [u128; N],
) -> [u128; N] {
    udiv_mod::<_, MOD_BITS>(params, numerator, divisor).0
}

/**
* @brief udiv_mod performs integer modular reduction
*
* i.e. 1. numerator % divisor = return value
**/
pub(crate) fn umod<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    numerator: [u128; N],
    divisor: [u128; N],
) -> [u128; N] {
    udiv_mod::<_, MOD_BITS>(params, numerator, divisor).1
}
