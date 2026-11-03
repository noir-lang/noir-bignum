use crate::constants::{GRUMPKIN_MODULUS, TWO_POW_120, TWO_POW_240};

use crate::fns::{
    expressions::{evaluate_quadratic_expression, validate_udiv_mod_expression},
    unconstrained_helpers::{
        __from_field, compute_add_flags, compute_borrow_flags, compute_gte_flags, compute_sub_flags,
    },
    unconstrained_ops::{__add, __div, __eq_hints, __eq_mod, __mul, __neg, __sqr, __sub, __udiv_mod},
};

use crate::params::BigNumParams;

use std::cmp::Ordering;

/// Lift the limbs of a `BigNum` value onto the circuit `Field`
///
/// Descent the `BigNum` value back into the `Field` and
///    - check that it's a proper `BigNum` value
///    - validate the limbs sum up to a `Field` value
pub(crate) fn limbs_to_field<let N: u32, let MOD_BITS: u32>(
    _params: &BigNumParams<N, MOD_BITS>,
    limbs: &[u128; N],
) -> Field {
    validate_in_range::<N, MOD_BITS>(limbs);
    // `validate_in_range` bounds `limbs` by `2^MOD_BITS`, so when `MOD_BITS < 254` the value is
    // already known to be smaller than the Grumpkin modulus: the latter's top limb is `0x3064`,
    // hence `GRUMPKIN_MODULUS > 0x3064 * 2^240 > 2^253`. Only `MOD_BITS >= 254` needs the
    // explicit comparison below.
    //
    // The comparison must be *skipped* rather than left in as a redundant check: `validate_gt`
    // range-constrains the top limb of `GRUMPKIN_MODULUS - limbs` to `MOD_BITS - (N - 1) * 120`
    // bits, which for e.g. `MOD_BITS = 253, N = 3` is 13 bits — too tight to hold the Grumpkin
    // modulus' own 14-bit top limb, so every value would fail the range check.
    if (N > 2) & (MOD_BITS >= 254) {
        // validate that the `BigNum` is less than the Grumpkin modulus
        let mut grumpkin_modulus: [u128; N] = [0; N];
        grumpkin_modulus[0] = GRUMPKIN_MODULUS[0];
        grumpkin_modulus[1] = GRUMPKIN_MODULUS[1];
        grumpkin_modulus[2] = GRUMPKIN_MODULUS[2];
        validate_gt::<N, MOD_BITS>(&grumpkin_modulus, limbs);
    }

    if N < 2 {
        limbs[0] as Field
    } else if N == 2 {
        (limbs[0] as Field) + (limbs[1] as Field) * (TWO_POW_120 as Field)
    } else {
        (limbs[0] as Field)
            + (limbs[1] as Field) * (TWO_POW_120 as Field)
            + (limbs[2] as Field) * TWO_POW_240
    }
}

/// Construct a `BigNum` value from a native `Field`
///
/// Decomposes the `Field` value into 120-bit limbs
/// then we have three cases:
///     - MOD_BITS < 254 (grumpkin_mod_bits): it is enough to call for `validate_in_field`, which is basically `val < MOD`
///     - MOD_BITS > 254: we need to verify that the obtained `BigNum` `val < GRUMPKIN_MODULUS`
///     - MOD_BITS = 254: verify that `val < min(MOD, GRUMPKIN_MODULUS)`
/// Next we verify that all the limbs are properly ranged
/// and that the accumulated limbs are equal to the input `Field` value
pub fn from_field<let N: u32, let MOD_BITS: u32>(
    _params: &BigNumParams<N, MOD_BITS>,
    val: Field,
) -> [u128; N] {
    // Safety: we check that the resulting limbs represent the intended field element
    // we check the bit length, the limbs being max 120 bits, and the value in total is less than the field modulus
    let result: [u128; N] = unsafe { __from_field::<N>(val) };

    if !std::runtime::is_unconstrained() {
        // validate the limbs are in range and the value in total is less than 2^254
        if MOD_BITS < 254 {
            // this means that the field modulus is smaller than grumpkin modulus so we have to check if the element fields in the field size
            validate_in_field(_params, &result);
        } else {
            let mut grumpkin_modulus: [u128; N] = [0; N];
            grumpkin_modulus[0] = GRUMPKIN_MODULUS[0];
            grumpkin_modulus[1] = GRUMPKIN_MODULUS[1];
            grumpkin_modulus[2] = GRUMPKIN_MODULUS[2];

            if MOD_BITS > 254 {
                // this means that the field modulus is larger than grumpkin modulus so we have to check if the element fields in the field size are less than the grumpkin modulus.
                // also for correct params N is always larger than 3 here
                validate_gt::<N, MOD_BITS>(&grumpkin_modulus, &result);
            } else {
                // this is the tricky part, when MOD_BITS = 254, we have to compare the limbs of the modulus to the grumpkin modulus limbs
                // any `BigNum` with 254 bits will have 3 limbs

                // if MOD is less than grumpkin modulus, this will be true
                let mut mod_lt_grumpkin: bool = false;
                let mut decided: bool = false;
                for i in 0..3 {
                    if !decided & (_params.modulus[2 - i] != grumpkin_modulus[2 - i]) {
                        mod_lt_grumpkin = _params.modulus[2 - i] < grumpkin_modulus[2 - i];
                        decided = true;
                    }
                }

                let min_modulus: [u128; N] = if mod_lt_grumpkin {
                    _params.modulus
                } else {
                    grumpkin_modulus
                };
                validate_gt::<N, MOD_BITS>(&min_modulus, &result);
            }
        }
        validate_in_range::<N, MOD_BITS>(&result);

        // validate the limbs sum up to the field value
        let field_val: Field = if N < 2 {
            result[0] as Field
        } else if N == 2 {
            (result[0] as Field) + (result[1] as Field) * (TWO_POW_120 as Field)
        } else {
            (result[0] as Field)
                + (result[1] as Field) * (TWO_POW_120 as Field)
                + (result[2] as Field) * TWO_POW_240
        };
        assert_eq(field_val, val);
    }

    result
}

/// Given an input seed, generate a pseudorandom `BigNum` value
///
/// This function *should* produce a uniformly randomly distributed value modulo `MOD`
///
///  First we take the seed and pack it's 31-byte chunks into `Field`s
///  A length separator (SeedBytes) is appended to the seed before hashing
///  to prevent collisions between seeds that differ only in leading zeros.
///
///  We use a hash function that can be modelled as a random oracle
///  We hash the packed seed using Poseidon2 to produce `MOD_BITS * 2` bits of entropy
///
///  From these bits we construct 4(in case N = 2) or 3(N > 2) `BigNum` values:
///  - We fill first `N - 1` limbs and leave the top limb empty
///
///  Then we accumulate the resulting BigNum values using:
///  B = 2^{120 * (N - 1)}
///  res = x3 + B * x2 + B^2 * x1 + B^3 * x0
///
/// ## Note
/// This function will always produce an `x3` `BigNum`
/// If `MOD = 2^{120 * (N - 1)}`
/// It will use only `MOD_BITS - 1` bits of entropy
pub fn derive_from_seed<let N: u32, let MOD_BITS: u32, let SeedBytes: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    seed: [u8; SeedBytes],
) -> [u128; N] {
    // Pack seed bytes into Fields.
    // For the seed of length M, we construct a rolling_hash_field of size ceil(M / 31).
    // i.e.  31 bytes per Field
    // NOTE: the Fields produced are 248 bits in size

    assert(SeedBytes < 256, "derive_from_seed: seed is too big");
    let mut rolling_hash_fields: [Field; (SeedBytes + 31) / 31] = [0; (SeedBytes + 31) / 31];
    let mut seed_ptr: u32 = 0;
    for i in 0..(SeedBytes + 31) / 31 {
        let mut packed: Field = 0;
        for _ in 0..31 {
            if (seed_ptr < SeedBytes) {
                packed *= 256;
                packed += seed[seed_ptr] as Field;
                seed_ptr += 1;
            } else if seed_ptr == SeedBytes {
                packed *= 256;
                packed += SeedBytes as Field;
                seed_ptr += 1;
            }
        }
        rolling_hash_fields[i] = packed;
    }

    let compressed: Field =
        poseidon::poseidon2::Poseidon2::hash(rolling_hash_fields, (SeedBytes + 31) / 31);
    let mut rolling_hash: [Field; 2] = [compressed, 0];

    // 120 bit limb has 15 bytes in it
    // we buffer (N * 15) * 2 bytes for 2N limbs
    let mut hash_buffer: [u8; N * 15 * 2] = [0; N * 15 * 2];

    // We produce 32 bytes (254 bits) per hash iteration
    // We take only 30 bytes, so we need ceil(N * 2 * 15 / 30) hashes to fill them up
    for i in 0..N {
        let hash: Field = poseidon::poseidon2::Poseidon2::hash(rolling_hash, 2);
        let hash: [u8; 32] = hash.to_le_bytes();
        for j in 0..30 {
            hash_buffer[i * 30 + j] = hash[j];
        }
        rolling_hash[1] += 1;
    }

    let num_bits: u32 = MOD_BITS * 2;
    let num_bytes: u32 = (num_bits + 7) / 8;

    // Truncate the final byte that will be used in `BigNum` creation
    let bits_in_last_byte: u8 = (num_bits as u8) % 8;
    if bits_in_last_byte != 0 {
        let last_byte_mask: u8 = ((1 as u8) << bits_in_last_byte) - 1;
        hash_buffer[num_bytes - 1] &= last_byte_mask;
    }

    let num_bigfield_chunks: u32 = if N == 2 { 4 } else { 3 };
    let mut byte_ptr: u32 = 0;

    // We want to convert our hash_buffer into bigfield chunks, with each `BigNum` having at most N - 1 limbs filled
    // We sample only N - 1 limbs mostly because we do not wont to deal with accidental overflows in the top limb
    // In any case the security is preserved
    //
    // For all integer values N > 1, the number of chunks is either 4(for N = 2) or 3(for N > 2) (ceil(2*N / (N - 1)))
    //
    // To determine the exact number of chunks, we need the `!=` or `>` operator which is not available when defining array sizes
    // so we overestimate at 4
    // e.g. if N = 20, then we have 40 limbs we want to reduce, but each bigfield chunk is 19 limbs, so we need 3
    // if N = 2, we have 4 limbs we want to reduce but each bigfield chunk is only 1 limb, so we need 4
    let mut bigfield_chunks: [[u128; N]; 4] = [[0; N]; 4];

    for k in 0..num_bigfield_chunks {
        let mut bigfield_limbs: [u128; N] = [0; N];

        // Before the current limb, we filled out (N - 1) limbs, k times
        // 15 bytes per limb
        // resulting in total of 15 * k * (N - 1)
        let num_filled_bytes: u32 = 15 * k * (N - 1);
        if num_bytes > num_filled_bytes {
            // Static assert for completeness
            assert(num_filled_bytes == byte_ptr);

            let num_remaining_bytes_to_sample: u32 = num_bytes - num_filled_bytes;
            let num_remaining_limbs_to_sample: u32 = (num_remaining_bytes_to_sample + 14) / 15;

            // Sample at most (N - 1) limbs from hash_buffer
            let num_limbs_to_sample: u32 = if num_remaining_limbs_to_sample > (N - 1) {
                N - 1
            } else {
                num_remaining_limbs_to_sample
            };

            for j in 0..num_limbs_to_sample {
                let mut limb: Field = 0;
                // Construct a 120 bit limb
                for _ in 0..15 {
                    if byte_ptr < num_bytes {
                        let byte: u8 = hash_buffer[byte_ptr];
                        limb *= 256;
                        limb += byte as Field;
                        byte_ptr += 1;
                    }
                }
                // crucial for performance
                limb.assert_max_bit_size::<120>();
                // Accumulate limbs from top to bottom
                bigfield_limbs[num_limbs_to_sample - 1 - j] = limb as u128;
            }
            // Accumulate `BigNum` values from top to bottom
            bigfield_chunks[num_bigfield_chunks - 1 - k] = bigfield_limbs;
        }
    }

    // B = 2^{120 * (N - 1)}, we know it is \leq `MOD`, since the top limb
    // have to be at least one
    let mut bigfield_rhs_limbs: [u128; N] = [0; N];
    bigfield_rhs_limbs[N - 1] = 1;

    let mut result: [u128; N] = bigfield_chunks[0];

    for i in 1..num_bigfield_chunks {
        result = mul(*params, result, bigfield_rhs_limbs);
        result = add(params, &result, &bigfield_chunks[i]);
    }

    result
}

// ------------------------------ COMPARISON FUNCTIONS ------------------------------

/// Validate lhs != rhs modulo the normalized BigNum modulus.
/// Asserted complement of the exact equality flag: see `eq` for the operand
/// envelope (value < 2^(MOD_BITS+1), permitted lazy aliases included) and
/// the in-circuit modulus and hint checks. No native-field packing shortcut
/// or subtraction hint is used.
pub fn assert_is_not_equal<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    lhs: &[u128; N],
    rhs: &[u128; N],
) {
    assert(!eq::<N, MOD_BITS>(params, lhs, rhs), "assert_is_not_equal fail");
}

/// Compute modular equality under normalized BigNum parameters.
///
/// Exact over the operand envelope `value < 2^(MOD_BITS+1)` for every
/// supported layout (N >= 1, 1 <= TOP_BITS <= 120): lower limbs are 120-bit
/// and the top limb may carry one bit beyond TOP_BITS, which covers canonical
/// values and the permitted lazy aliases (RuntimeBigNum equality included).
/// The modulus premise (normalized, exactly MOD_BITS significant bits) is
/// checked in-circuit, including for runtime parameters constructed without
/// `BigNumParams::new`.
///
/// The prover supplies `r` (the canonical residue of lhs - rhs mod MOD),
/// a shifted quotient `k = q_shift - 4` and biased chain carries, and the
/// circuit asserts the integer identity `lhs - rhs = k*MOD + r`. The flag is
/// then decided from `r` alone; see `eq_with_hints` for the exactness
/// argument. No native-field packing shortcut or subtraction hint is used.
pub fn eq<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    lhs: &[u128; N],
    rhs: &[u128; N],
) -> bool {
    // Both paths reject the same inputs, before any hint code runs.
    validate_eq_inputs::<N, MOD_BITS>(params, lhs, rhs);
    if std::runtime::is_unconstrained() {
        // Safety: inputs are validated above, so `__eq_mod` returns the same
        // flag the constrained path proves.
        unsafe {
            __eq_mod(&params.modulus, lhs, rhs)
        }
    } else {
        // Safety: all three hints are range-checked and bound to the integer
        // identity lhs - rhs = (q_shift - 4)*MOD + r inside `eq_with_hints`.
        let (q_shift, r, carry_shift) = unsafe { __eq_hints::<N>(&params.modulus, lhs, rhs) };
        eq_with_hints::<N, MOD_BITS>(params, lhs, rhs, q_shift, &r, &carry_shift)
    }
}

/// Validate the inputs accepted by `eq`
///
/// Constrains:
///     - the modulus to be exactly `MOD_BITS` bits long (runtime parameters may be
///       constructed without `BigNumParams::new`), and
///     - each operand to be below `2^(MOD_BITS+1)` with 120-bit lower limbs, which
///       admits the lazy aliases produced by other operations.
fn validate_eq_inputs<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    lhs: &[u128; N],
    rhs: &[u128; N],
) {
    std::static_assert(
        (MOD_BITS > 120 * (N - 1)) & (MOD_BITS <= 120 * N),
        "MOD_BITS must place the top bit in the top limb",
    );
    validate_modulus::<N, MOD_BITS>(&params.modulus);
    validate_in_range::<N, MOD_BITS + 1>(lhs);
    validate_in_range::<N, MOD_BITS + 1>(rhs);
}

/// Constrained core of `eq`, split out so adversarial hints can be tested.
///
/// Assumes `validate_eq_inputs` has been called on `params`, `lhs` and `rhs`.
///
/// Soundness: each per-limb field equation has every term below 2^124 << p
/// (operand limbs and r limbs are range-checked, |k| <= 4 after the 3-bit
/// check on q_shift, |carry| <= 8 after the 4-bit checks), so it holds over
/// the integers; telescoping the chain gives lhs - rhs = k*MOD + r over the
/// integers, hence r == lhs - rhs (mod MOD). The modulus premise gives
/// MOD >= 2^(MOD_BITS-1), so r < 2^MOD_BITS <= 2*MOD and the only values of
/// r congruent to 0 are 0 and MOD: the returned flag is forced to
/// `lhs == rhs (mod MOD)` for every witness satisfying the constraints.
///
/// Completeness: an honest prover always holds the canonical residue r < MOD,
/// a quotient k in -4..=3 (|lhs - rhs| < 2^(MOD_BITS+1) <= 4*MOD and
/// 0 <= r < MOD) and chain carries of magnitude at most 4, so every
/// assertion passes for equal and unequal operands alike.
pub(crate) fn eq_with_hints<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    lhs: &[u128; N],
    rhs: &[u128; N],
    q_shift: u128,
    r: &[u128; N],
    carry_shift: &[u128; N - 1],
) -> bool {
    // Hint envelope: r < 2^MOD_BITS with 120-bit limbs, k = q_shift - 4 in -4..=3.
    validate_in_range::<N, MOD_BITS>(r);
    (q_shift as Field).assert_max_bit_size::<3>();
    let k: Field = (q_shift as Field) - 4;
    let big: Field = TWO_POW_120 as Field;
    let mut carry: Field = 0;
    for i in 0..N - 1 {
        (carry_shift[i] as Field).assert_max_bit_size::<4>();
        let limb = eq_limb_remainder(lhs[i], rhs[i], params.modulus[i], r[i], k, carry);
        let carry_out = (carry_shift[i] as Field) - 8;
        assert(limb == carry_out * big, "eq decomposition fail");
        carry = carry_out;
    }
    let top = eq_limb_remainder(
        lhs[N - 1],
        rhs[N - 1],
        params.modulus[N - 1],
        r[N - 1],
        k,
        carry,
    );
    assert(top == 0, "eq decomposition fail");
    // r is congruent to lhs - rhs and below 2*MOD: equal iff r is 0 or MOD.
    is_zero::<N, MOD_BITS>(params, r)
}

/// One limb of `lhs - rhs - k * MOD - r`, plus the carry in from the limb below.
///
/// `eq_with_hints` constrains this to `carry_out * 2^120` for each lower limb and to
/// zero for the top limb; `__eq_hints` evaluates it to compute the honest carries.
pub(crate) fn eq_limb_remainder(
    lhs: u128,
    rhs: u128,
    modulus: u128,
    r: u128,
    k: Field,
    carry_in: Field,
) -> Field {
    (lhs as Field) - (rhs as Field) + carry_in - k * (modulus as Field) - (r as Field)
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
pub fn assert_is_not_zero_integer<let N: u32>(val: &[u128; N]) {
    assert(!is_zero_integer(val), "assert_is_not_zero_integer fail");
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
pub fn is_zero_integer<let N: u32>(val: &[u128; N]) -> bool {
    let mut limb_sum: Field = 0;
    for i in 0..N {
        limb_sum += val[i].into();
    }
    limb_sum == 0
}

/// Validate that a `BigNum` value is not zero modulo `MOD`.
///
/// Convenience wrapper around `assert_is_not_equal`.
pub fn assert_is_not_zero<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    val: &[u128; N],
) {
    let zero: [u128; N] = [0; N];
    assert_is_not_equal::<N, MOD_BITS>(params, val, &zero);
}

/// Check whether a `BigNum` value is zero modulo `MOD`.
///
/// This treats both the all-zero limb vector and `params.modulus` as
/// representing zero. It assumes that all valid `BigNum` values are
/// range-constrained so that no other representatives of `0 (mod MOD)`
/// can appear.
///
/// ## Note
/// This is cheaper than calling `eq(val, [0; N])`
pub fn is_zero<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    val: &[u128; N],
) -> bool {
    is_zero_integer(val) | (*val == params.modulus)
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
pub fn validate_in_range<let N: u32, let MOD_BITS: u32>(limbs: &[u128; N]) {
    for i in 0..(N - 1) {
        (limbs[i] as Field).assert_max_bit_size::<120>();
    }

    (limbs[N - 1] as Field).assert_max_bit_size::<MOD_BITS - ((N - 1) * 120)>();
}

/// Validate that `modulus` is exactly `MOD_BITS` bits long
///
/// Constrains:
///     - each limb to be in range (see `validate_in_range`), and
///     - the top limb to have its highest bit set, i.e.
///       `0 <= top_limb - 2^(TOP_LIMB_BITS - 1) < 2^(TOP_LIMB_BITS - 1)`
pub(crate) fn validate_modulus<let N: u32, let MOD_BITS: u32>(modulus: &[u128; N]) {
    validate_in_range::<N, MOD_BITS>(modulus);

    let top_limb: Field = modulus[N - 1] as Field;
    let top_limb_bits: u128 = (MOD_BITS - (N - 1) * 120) as u128;
    let min_top_limb: Field = (1u128 << (top_limb_bits - 1)) as Field;
    (top_limb - min_top_limb).assert_max_bit_size::<MOD_BITS - (N - 1) * 120 - 1>();
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
pub(crate) fn validate_quotient_in_range<let N: u32, let MOD_BITS: u32>(limbs: &[u128; N]) {
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
/// This function is complete: it will succeed for any `lhs > rhs` over the integers.
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
/// Since this is an integer comparison, you should validate_in_field the lhs when needed
/// to avoid accepting values that are not in canonical form (i.e. >= MOD).
/// The rhs does not need validation: since lhs > rhs and lhs < MOD, it follows that rhs < MOD.
pub(crate) fn validate_gt<let N: u32, let MOD_BITS: u32>(lhs: &[u128; N], rhs: &[u128; N]) {
    // Safety: borrow_flags are constrained by `assert_sub_no_overflow`:
    // - incorrect flags cause the computed result to fail 128-bit range checks
    // - if lhs < rhs, the subtraction overflows Field and fails range checks
    let borrow_flags: [bool; N - 1] = unsafe { compute_borrow_flags(lhs, rhs) };

    // Compute and validate the result in constrained code
    let result: [u128; N] = assert_sub_no_overflow::<N, MOD_BITS>(lhs, rhs, &borrow_flags);

    // Constrain it to be strict inequality
    assert_is_not_zero_integer(&result);
}

/// Compute the result of lhs - rhs given borrow flags and validate it
///
/// This is the constrained analog of the result computation in the unconstrained helpers.
/// Given borrow_flags, computes result such that:
///     result[0]     = lhs[0]     - rhs[0]     + bf[0] * 2^{120}
///     result[i]     = lhs[i]     - rhs[i]     + bf[i] * 2^{120} - bf[i - 1],  i = 1..N-2
///     result[N - 1] = lhs[N - 1] - rhs[N - 1]                   - bf[N - 2]
///
/// Also validates that the result is a valid BigNum value (each limb in range).
/// If lhs < rhs, the result will have a negative value (wrapped in Field) and fail validation.
fn assert_sub_no_overflow<let N: u32, let MOD_BITS: u32>(
    lhs: &[u128; N],
    rhs: &[u128; N],
    borrow_flags: &[bool; N - 1],
) -> [u128; N] {
    let mut result: [u128; N] = [0; N];

    // Compute first limb
    let limb_0: Field =
        (lhs[0] as Field) - (rhs[0] as Field) + (borrow_flags[0] as Field) * (TWO_POW_120 as Field);
    limb_0.assert_max_bit_size::<128>();
    result[0] = limb_0 as u128;

    // Compute middle limbs
    for i in 1..N - 1 {
        let limb_i: Field = (lhs[i] as Field) - (rhs[i] as Field)
            + (borrow_flags[i] as Field) * (TWO_POW_120 as Field)
            - (borrow_flags[i - 1] as Field);
        limb_i.assert_max_bit_size::<128>();
        result[i] = limb_i as u128;
    }

    // Compute last limb
    let limb_last: Field =
        (lhs[N - 1] as Field) - (rhs[N - 1] as Field) - (borrow_flags[N - 2] as Field);
    limb_last.assert_max_bit_size::<128>();
    result[N - 1] = limb_last as u128;

    // Validate that the result is a valid BigNum value (120-bit limbs, TOP_LIMB_BITS for last)
    validate_in_range::<N, MOD_BITS>(&result);

    result
}

/// Compute the result of modular subtraction given flags and validate it
///
/// Computes `result = lhs - rhs + (underflow ? modulus : 0)` given carry and borrow flags.
/// The formula for each limb is:
///     result[0]     = lhs[0]     - rhs[0]     + addend[0]     + bf[0] * 2^120 - cf[0] * 2^120
///     result[i]     = lhs[i]     - rhs[i]     + addend[i]     + bf[i] * 2^120 - cf[i] * 2^120 - bf[i-1] + cf[i-1],  i = 1..N-2
///     result[N - 1] = lhs[N - 1] - rhs[N - 1] + addend[N - 1]                               - bf[N-2] + cf[N-2]
///
/// Also validates that the result is a valid BigNum value (each limb in range).
fn compute_sub_result<let N: u32, let MOD_BITS: u32>(
    modulus: &[u128; N],
    lhs: &[u128; N],
    rhs: &[u128; N],
    carry_flags: &[bool; N - 1],
    borrow_flags: &[bool; N - 1],
    underflow: bool,
) -> [u128; N] {
    let addend: [u128; N] = if underflow { *modulus } else { [0; N] };

    let mut result: [u128; N] = [0; N];

    // Compute first limb
    let limb_0: Field = (lhs[0] as Field) - (rhs[0] as Field)
        + (addend[0] as Field)
        + (borrow_flags[0] as Field) * (TWO_POW_120 as Field)
        - (carry_flags[0] as Field) * (TWO_POW_120 as Field);
    limb_0.assert_max_bit_size::<128>();
    result[0] = limb_0 as u128;

    // Compute middle limbs
    for i in 1..N - 1 {
        let limb_i: Field = (lhs[i] as Field) - (rhs[i] as Field)
            + (addend[i] as Field)
            + (borrow_flags[i] as Field) * (TWO_POW_120 as Field)
            - (carry_flags[i] as Field) * (TWO_POW_120 as Field)
            - (borrow_flags[i - 1] as Field)
            + (carry_flags[i - 1] as Field);
        limb_i.assert_max_bit_size::<128>();
        result[i] = limb_i as u128;
    }

    // Compute last limb
    let limb_last: Field = (lhs[N - 1] as Field) - (rhs[N - 1] as Field) + (addend[N - 1] as Field)
        - (borrow_flags[N - 2] as Field)
        + (carry_flags[N - 2] as Field);
    limb_last.assert_max_bit_size::<128>();
    result[N - 1] = limb_last as u128;

    // Validate that the result is a valid BigNum value (120-bit limbs, TOP_LIMB_BITS for last)
    validate_in_range::<N, MOD_BITS>(&result);

    result
}

/// Compute the result of modular addition given flags and validate it
///
/// Computes `result = lhs + rhs - (overflow ? modulus : 0)` given carry and borrow flags.
/// The formula for each limb is:
///     result[0]     = lhs[0]     + rhs[0]     - subtrahend[0]     + bf[0] * 2^120 - cf[0] * 2^120
///     result[i]     = lhs[i]     + rhs[i]     - subtrahend[i]     + bf[i] * 2^120 - cf[i] * 2^120 - bf[i-1] + cf[i-1],  i = 1..N-2
///     result[N - 1] = lhs[N - 1] + rhs[N - 1] - subtrahend[N - 1]                               - bf[N-2] + cf[N-2]
///
/// Also validates that the result is a valid BigNum value (each limb in range).
fn compute_add_result<let N: u32, let MOD_BITS: u32>(
    modulus: &[u128; N],
    lhs: &[u128; N],
    rhs: &[u128; N],
    carry_flags: &[bool; N - 1],
    borrow_flags: &[bool; N - 1],
    overflow: bool,
) -> [u128; N] {
    let subtrahend: [u128; N] = if overflow { *modulus } else { [0; N] };

    let mut result: [u128; N] = [0; N];

    // Compute first limb
    let limb_0: Field = (lhs[0] as Field) + (rhs[0] as Field) - (subtrahend[0] as Field)
        + (borrow_flags[0] as Field) * (TWO_POW_120 as Field)
        - (carry_flags[0] as Field) * (TWO_POW_120 as Field);
    limb_0.assert_max_bit_size::<128>();
    result[0] = limb_0 as u128;

    // Compute middle limbs
    for i in 1..N - 1 {
        let limb_i: Field = (lhs[i] as Field) + (rhs[i] as Field)
            - (subtrahend[i] as Field)
            - (borrow_flags[i - 1] as Field)
            + (carry_flags[i - 1] as Field)
            + (borrow_flags[i] as Field) * (TWO_POW_120 as Field)
            - (carry_flags[i] as Field) * (TWO_POW_120 as Field);
        limb_i.assert_max_bit_size::<128>();
        result[i] = limb_i as u128;
    }

    // Compute last limb
    let limb_last: Field = (lhs[N - 1] as Field) + (rhs[N - 1] as Field)
        - (subtrahend[N - 1] as Field)
        - (borrow_flags[N - 2] as Field)
        + (carry_flags[N - 2] as Field);
    limb_last.assert_max_bit_size::<128>();
    result[N - 1] = limb_last as u128;

    // Validate that the result is a valid BigNum value (120-bit limbs, TOP_LIMB_BITS for last)
    validate_in_range::<N, MOD_BITS>(&result);

    result
}

/// Validate that `val` < `MOD`
pub fn validate_in_field<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    val: &[u128; N],
) {
    validate_gt::<N, MOD_BITS>(&params.modulus, val);
}

/// Compare two `BigNum` values, returning their `Ordering`.
///
/// Performs a strict integer comparison over the limb representation,
/// **not** modular ordering.
///
/// ## Safety
/// Both operands **must** be in canonical form (i.e. in `[0, MOD)`).
/// Call `validate_in_field` on each operand before comparing, otherwise
/// non-canonical representations (e.g. `MOD` vs `0`) will produce incorrect results.
pub fn cmp<let N: u32, let MOD_BITS: u32>(lhs: &[u128; N], rhs: &[u128; N]) -> Ordering {
    // Safety: underflow and borrow_flags are constrained by `assert_sub_no_overflow`:
    // - we swap (a, b) based on underflow, then compute a - b
    // - if underflow is wrong, a < b and the subtraction overflows, failing range checks
    // - if borrow_flags are wrong, the computed limbs fail 128-bit range checks
    let (underflow, borrow_flags): (bool, [bool; N - 1]) = unsafe { compute_gte_flags(lhs, rhs) };

    // if underflow is true, swap lhs and rhs so we compute larger - smaller
    let (a, b): ([u128; N], [u128; N]) = if underflow {
        (*rhs, *lhs)
    } else {
        (*lhs, *rhs)
    };

    // Enforce correctness of `underflow` by asserting that the subtraction does not overflow.
    let _: [u128; N] = assert_sub_no_overflow::<N, MOD_BITS>(&a, &b, &borrow_flags);

    if *lhs == *rhs {
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
/// Computes `result = 0 - val (mod MOD)` using constrained subtraction function
///
/// All constraints and soundness details are handled inside `sub`.
pub fn neg<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    val: &[u128; N],
) -> [u128; N] {
    if std::runtime::is_unconstrained() {
        // Safety: unconstrained runtime requires no constraints
        unsafe {
            __neg(&params.modulus, val)
        }
    } else {
        sub(params, &[0; N], val)
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
/// `(bf, cf, overflow_modulus)` is the honest one produced by `compute_add_flags`,
/// these constraints enforce:
///   - a valid limb-wise carry chain for `lhs + rhs`, and
///   - a valid limb-wise subtraction chain for either `lhs + rhs` or
///     `lhs + rhs - MOD`, with no underflow in any limb.
///
/// Under these assumptions the constrained result equals:
///
///     result = lhs + rhs (mod MOD)
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
/// ## Completeness
///
/// For inputs in the range `0 <= lhs, rhs < MOD` and honest flags from
/// `compute_add_flags`, the constraints are complete: every valid `BigNum` sum
/// `lhs + rhs (mod MOD)` admits a satisfying assignment.
///
/// Inputs with `lhs` or `rhs` in `[MOD, 2^{MOD_BITS})` are still representable
/// as limb arrays and may admit satisfying witnesses, but then the operation
/// no longer corresponds to a unique, well-defined addition in the field
/// `Z / MOD Z`. Such uses are outside the intended semantics of this function.
pub fn add<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    lhs: &[u128; N],
    rhs: &[u128; N],
) -> [u128; N] {
    if std::runtime::is_unconstrained() {
        // Safety: unconstrained runtime requires no constraints
        unsafe {
            __add(&params.modulus, lhs, rhs)
        }
    } else {
        let modulus = params.modulus;
        // Safety: flags are constrained by `compute_add_result`:
        // - incorrect flags cause computed limbs to fail 128-bit range checks
        // - wrong overflow causes result to be off by modulus, failing `validate_in_range`
        let (carry_flags, borrow_flags, overflow): ([bool; N - 1], [bool; N - 1], bool) =
            unsafe { compute_add_flags(&modulus, lhs, rhs) };

        // Compute and validate the result in constrained code
        compute_add_result::<N, MOD_BITS>(&modulus, lhs, rhs, &carry_flags, &borrow_flags, overflow)
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
/// `(bf, cf, underflow_modulus)` is the honest one produced by `compute_sub_flags`,
/// these constraints enforce:
///   - a valid limb-wise borrow chain for `lhs - rhs`, and
///   - a valid limb-wise addition chain for either `lhs - rhs` or
///     `lhs - rhs + MOD`, with no underflow in any limb.
///
/// Under these assumptions the constrained result equals:
///
///     result = lhs - rhs (mod MOD)
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
/// ## Completeness
///
/// For inputs in the range `0 <= lhs, rhs < MOD` and honest flags from
/// `compute_sub_flags`, the constraints are complete: every valid `BigNum`
/// difference `lhs - rhs (mod MOD)` admits a satisfying assignment.
///
/// Inputs with `lhs` or `rhs` in `[MOD, 2^{MOD_BITS})` are still representable
/// as limb arrays and may admit satisfying witnesses, but then the operation
/// no longer corresponds to a unique, well-defined subtraction in the field
/// `Z / MOD Z`. Such uses are outside the intended semantics of this function.
pub fn sub<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    lhs: &[u128; N],
    rhs: &[u128; N],
) -> [u128; N] {
    if std::runtime::is_unconstrained() {
        // Safety: unconstrained runtime requires no constraints
        unsafe {
            __sub(&params.modulus, lhs, rhs)
        }
    } else {
        let modulus = params.modulus;
        // Safety: flags are constrained by `compute_sub_result`:
        // - incorrect flags cause computed limbs to fail 128-bit range checks
        // - wrong underflow causes result to be off by modulus, failing `validate_in_range`
        let (carry_flags, borrow_flags, underflow): ([bool; N - 1], [bool; N - 1], bool) =
            unsafe { compute_sub_flags(&modulus, lhs, rhs) };

        // Compute and validate the result in constrained code
        compute_sub_result::<N, MOD_BITS>(
            &modulus,
            lhs,
            rhs,
            &carry_flags,
            &borrow_flags,
            underflow,
        )
    }
}

/// Compute the `BigNum` multiplication
///
/// Computes `result = lhs * rhs (mod MOD)` by:
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
pub fn mul<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    // Safety: we constrain the multiplication result immediately after
    let result: [u128; N] = unsafe { __mul::<N, MOD_BITS>(&params, &lhs, &rhs) };
    if !std::runtime::is_unconstrained() {
        // lhs * rhs - result = 0
        let lhs_terms: [[[u128; N]; 1]; 1] = [[lhs]];
        let lhs_flags: [[bool; 1]; 1] = [[false]];
        let rhs_terms: [[[u128; N]; 1]; 1] = [[rhs]];
        let rhs_flags: [[bool; 1]; 1] = [[false]];
        let linear_terms: [[u128; N]; 1] = [result];
        let linear_flags: [bool; 1] = [true];
        evaluate_quadratic_expression::<N, MOD_BITS, 1, 1, 1, 1>(
            &params,
            &lhs_terms,
            &lhs_flags,
            &rhs_terms,
            &rhs_flags,
            &linear_terms,
            &linear_flags,
        );
    }
    result
}

/// Compute the `BigNum` squaring
///
/// Computes `result = val * val (mod MOD)` by:
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
pub fn sqr<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    val: [u128; N],
) -> [u128; N] {
    // Safety: we constrain the multiplication result immediately after
    let result: [u128; N] = unsafe { __sqr::<_, MOD_BITS>(&params, &val) };
    if !std::runtime::is_unconstrained() {
        // val * val - result = 0
        let lhs_terms: [[[u128; N]; 1]; 1] = [[val]];
        let lhs_flags: [[bool; 1]; 1] = [[false]];
        let rhs_terms: [[[u128; N]; 1]; 1] = [[val]];
        let rhs_flags: [[bool; 1]; 1] = [[false]];
        let linear_terms: [[u128; N]; 1] = [result];
        let linear_flags: [bool; 1] = [true];
        evaluate_quadratic_expression::<N, MOD_BITS, 1, 1, 1, 1>(
            &params,
            &lhs_terms,
            &lhs_flags,
            &rhs_terms,
            &rhs_flags,
            &linear_terms,
            &linear_flags,
        );
    }
    result
}

/// Compute the `BigNum` division
///
/// Computes `result = lhs * rhs^{-1} (mod MOD)` by:
///   1. Computing `result` out of circuit via `__div`.
///   2. Constraining the quadratic relation `result * rhs - lhs = 0` with
///      `evaluate_quadratic_expression`.
///   3. Enforcing `rhs != 0 (mod MOD)`.
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
pub fn div<let N: u32, let MOD_BITS: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs: [u128; N],
    rhs: [u128; N],
) -> [u128; N] {
    assert(
        params.has_multiplicative_inverse,
        "BigNum has no multiplicative inverse. Use udiv for unsigned integer division",
    );
    // Safety: We constrain the result of division immediately after
    let result: [u128; N] = unsafe { __div::<_, MOD_BITS>(&params, &lhs, &rhs) };
    if !std::runtime::is_unconstrained() {
        // result * rhs - lhs = 0
        let lhs_terms: [[[u128; N]; 1]; 1] = [[result]];
        let lhs_flags: [[bool; 1]; 1] = [[false]];
        let rhs_terms: [[[u128; N]; 1]; 1] = [[rhs]];
        let rhs_flags: [[bool; 1]; 1] = [[false]];
        let linear_terms: [[u128; N]; 1] = [lhs];
        let linear_flags: [bool; 1] = [true];
        evaluate_quadratic_expression::<N, MOD_BITS, 1, 1, 1, 1>(
            &params,
            &lhs_terms,
            &lhs_flags,
            &rhs_terms,
            &rhs_flags,
            &linear_terms,
            &linear_flags,
        );
        assert_is_not_zero(&params, &rhs);
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
///      with `validate_udiv_mod_expression`.
///   3. Enforcing `remainder < divisor`.
///
/// ## Soundness
/// Soundness reduces to `validate_udiv_mod_expression` for the relation
///     quotient * divisor + remainder - numerator = 0,
/// together with `remainder < divisor` check enforced via `validate_gt`
/// and `validate_in_field` for divisor to be strictly less than MOD
///
/// Under these checks, any satisfying assignment corresponds to a valid
/// integer division `numerator = quotient * divisor + remainder` with
/// `0 <= remainder < divisor < MOD`
/// `0 <= numerator < MOD`
///
/// ## Note
/// Enforcing `divisor != 0` is not necessary. `remainder < divisor`
/// Already enforces this.
pub fn udiv_mod<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    numerator: &[u128; N],
    divisor: &[u128; N],
) -> ([u128; N], [u128; N]) {
    // Safety: We constrain the result of __udiv_mod immediately after
    let (quotient, remainder): ([u128; N], [u128; N]) = unsafe { __udiv_mod(numerator, divisor) };
    if !std::runtime::is_unconstrained() {
        // quotient * divisor + remainder - numerator = 0
        validate_udiv_mod_expression::<N, MOD_BITS>(numerator, divisor, &quotient, &remainder);
        // remainder < divisor
        validate_gt::<N, MOD_BITS>(divisor, &remainder);
        // divisor is in canonical representation
        validate_in_field(params, divisor);
        // numerator is in canonical representation
        validate_in_field(params, numerator);
    }
    (quotient, remainder)
}

/// Unsafe version of `udiv_mod`.
///
/// Does not call `validate_in_field` on the numerator or divisor.
///
/// ## Safety
/// Both `numerator` and `divisor` **must** already be in canonical form (i.e. in `[0, MOD)`).
/// Use this variant when the inputs have already been validated via `validate_in_field`
/// (e.g. as outputs of other constrained operations) to avoid redundant checks.
pub fn udiv_mod_unsafe<let N: u32, let MOD_BITS: u32>(
    numerator: &[u128; N],
    divisor: &[u128; N],
) -> ([u128; N], [u128; N]) {
    // Safety: We constrain the result of __udiv_mod immediately after
    let (quotient, remainder): ([u128; N], [u128; N]) = unsafe { __udiv_mod(numerator, divisor) };
    if !std::runtime::is_unconstrained() {
        // quotient * divisor + remainder - numerator = 0
        validate_udiv_mod_expression::<N, MOD_BITS>(numerator, divisor, &quotient, &remainder);
        // remainder < divisor
        validate_gt::<N, MOD_BITS>(divisor, &remainder);
    }
    (quotient, remainder)
}

/// Compute the `BigNum` integer division.
///
/// Returns `floor(numerator / divisor)`.
/// All constraints and soundness details are handled inside `udiv_mod`.
pub fn udiv<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    numerator: &[u128; N],
    divisor: &[u128; N],
) -> [u128; N] {
    udiv_mod::<N, MOD_BITS>(params, numerator, divisor).0
}

/// Unsafe version of `udiv`.
///
/// Returns `floor(numerator / divisor)`.
/// All constraints and soundness details are handled inside `udiv_mod_unsafe`.
///
/// ## Safety
/// Both `numerator` and `divisor` **must** already be in canonical form (i.e. in `[0, MOD)`).
pub fn udiv_unsafe<let N: u32, let MOD_BITS: u32>(
    numerator: &[u128; N],
    divisor: &[u128; N],
) -> [u128; N] {
    udiv_mod_unsafe::<N, MOD_BITS>(numerator, divisor).0
}

/// Compute the `BigNum` remainder.
///
/// Returns `numerator % divisor`.
/// All constraints and soundness details are handled inside `udiv_mod`.
pub fn umod<let N: u32, let MOD_BITS: u32>(
    params: &BigNumParams<N, MOD_BITS>,
    numerator: &[u128; N],
    divisor: &[u128; N],
) -> [u128; N] {
    udiv_mod::<N, MOD_BITS>(params, numerator, divisor).1
}

/// Unsafe version of `umod`.
///
/// Returns `numerator % divisor`.
/// All constraints and soundness details are handled inside `udiv_mod_unsafe`.
///
/// ## Safety
/// Both `numerator` and `divisor` **must** already be in canonical form (i.e. in `[0, MOD)`).
pub fn umod_unsafe<let N: u32, let MOD_BITS: u32>(
    numerator: &[u128; N],
    divisor: &[u128; N],
) -> [u128; N] {
    udiv_mod_unsafe::<N, MOD_BITS>(numerator, divisor).1
}
