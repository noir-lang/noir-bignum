use crate::utils::map::invert_array;

// Conversions between big endian and little endian byte arrays and BigNum instances
// the byte serialization should have `(MOD_BITS + 7) / 8` bytes.
// each 120-bit limb is represented by 15 bytes, and there are fewer bytes for covering the most significant limb

/// Construct a `BigNum` value from a big-endian byte array.
///
/// The input encodes an integer in base 256, which we split into `N` 120-bit limbs.
///
/// ## Note
/// We only enforce that the value is < 2^MOD_BITS via a range constraint on the
/// most significant byte (when `MOD_BITS % 8 != 0`). We do not enforce that it is
/// reduced modulo the field modulus.
///
/// This does not prove `x < modulus`, but it is acceptable here: by construction
/// the value can differ from the modulus by at most one multiple of it, which is
/// compatible with the rest of this library
///
/// Consistency between `N` and `MOD_BITS` is expected:
///     - `N * 15 >= num_bytes`
///     - `num_bytes > (N - 1) * 15`
///     - `num_bits >= MOD_BITS`
///     - `num_bits - MOD_BITS < 8`
pub(crate) fn from_be_bytes<let N: u32, let MOD_BITS: u32>(
    x: [u8; (MOD_BITS + 7) / 8],
) -> [u128; N] {
    let num_bytes: u32 = (MOD_BITS + 7) / 8;
    let num_bits: u32 = num_bytes * 8;

    assert(num_bits >= MOD_BITS);
    assert(num_bits - MOD_BITS < 8);

    let mut result: [u128; N] = [0; N];

    let excess_bytes: u32 = N * 15 - num_bytes;
    let final_limb_bytes: u32 = 15 - excess_bytes;

    let mut limb: Field = 0;
    let mut byte_ptr: u32 = 0;
    for _ in 0..final_limb_bytes {
        limb *= 256;
        limb += x[byte_ptr] as Field;
        byte_ptr += 1;
    }
    result[N - 1] = limb as u128;

    for i in 1..N {
        let mut limb: Field = 0;
        for _ in 0..15 {
            limb *= 256;
            limb += x[byte_ptr] as Field;
            byte_ptr += 1;
        }
        result[N - i - 1] = limb as u128;
    }

    let most_significant_byte: Field = x[0] as Field;
    if MOD_BITS % 8 != 0 {
        most_significant_byte.assert_max_bit_size::<MOD_BITS % 8>();
    }

    result
}

/// Construct a big-endian byte array from a `BigNum` value.
///
/// The output contains `(MOD_BITS + 7) / 8` bytes. We serialize the most
/// significant limb first, which may occupy fewer than 15 bytes, followed by
/// the remaining full 15-byte limbs in big-endian order.
///
/// Consistency between `N` and `MOD_BITS` is expected:
///     - the most significant limb contributes `((MOD_BITS + 7) / 8) - (N - 1) * 15` bytes;
///     - all other limbs are serialized as full 15-byte chunks.
///
/// No range checks are applied here; limbs are assumed to be valid `BigNum`
/// representations.
pub(crate) fn to_be_bytes<let N: u32, let MOD_BITS: u32>(
    val: [u128; N],
) -> [u8; (MOD_BITS + 7) / 8] {
    let mut result: [u8; (MOD_BITS + 7) / 8] = [0; (MOD_BITS + 7) / 8];
    let mut byte_ptr: u32 = 0;

    // First we deal with the last limb
    let last_limb_num_bytes: u32 = (MOD_BITS + 7) / 8 - (N - 1) * 15;

    let last_limb_bytes: [u8; ((MOD_BITS + 7) / 8 - (N - 1) * 15)] =
        (val[N - 1] as Field).to_be_bytes();

    for i in 0..last_limb_num_bytes {
        result[byte_ptr] = last_limb_bytes[i];
        byte_ptr += 1;
    }

    // Now we deal with the full limbs
    for i in 0..N - 1 {
        let idx = (N - 1) - i - 1;
        let limb_bytes: [u8; 15] = (val[idx] as Field).to_be_bytes();
        for j in 0..15 {
            result[byte_ptr] = limb_bytes[j];
            byte_ptr += 1;
        }
    }
    result
}

/// Construct a `BigNum` value from little endian byte array
pub(crate) fn from_le_bytes<let N: u32, let MOD_BITS: u32>(
    x: [u8; (MOD_BITS + 7) / 8],
) -> [u128; N] {
    let be_x: [u8; (MOD_BITS + 7) / 8] = invert_array(x);
    from_be_bytes(be_x)
}

/// Construct a little endian byte array from a `BigNum` value
pub(crate) fn to_le_bytes<let N: u32, let MOD_BITS: u32>(
    val: [u128; N],
) -> [u8; (MOD_BITS + 7) / 8] {
    let result_be: [u8; (MOD_BITS + 7) / 8] = to_be_bytes(val);
    invert_array(result_be)
}
