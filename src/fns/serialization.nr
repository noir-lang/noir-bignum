unconstrained fn __field_to_u128(input: Field) -> u128 {
    input as u128
}

fn field_to_u128(input: Field) -> u128 {
    // Safety: convert to u128 and validate equality
    let r = unsafe { __field_to_u128(input) };
    assert_eq(r as Field, input);
    r
}
/**
* @brief construct a BigNum instance out of an array of bytes in BIG ENDIAN format
* @description: each 120-bit limb represents 15 bytes, we require that the size of the byte array
*               is precisely large enough to cover MOD_BITS
* @param x: input byte array
**/
pub(crate) fn from_be_bytes<let N: u32, let MOD_BITS: u32>(
    x: [u8; (MOD_BITS + 7) / 8],
) -> [u128; N] {
    let num_bits = (MOD_BITS + 7) / 8 * 8;
    assert(num_bits >= MOD_BITS);
    assert(num_bits - MOD_BITS < 8);
    let mut result: [u128; N] = [0; N];

    let excess_bytes = N * 15 - (MOD_BITS + 7) / 8;
    let final_limb_bytes = 15 - excess_bytes;
    let mut limb: Field = 0;
    let mut k = 0;
    for _j in 0..final_limb_bytes {
        limb *= 256;
        limb += x[k] as Field;
        k += 1;
    }
    result[N - 1] = field_to_u128(limb);

    for i in 1..N {
        let mut limb: Field = 0;
        for _j in 0..15 {
            limb *= 256;
            limb += x[k] as Field;
            k += 1;
        }
        result[N - i - 1] = field_to_u128(limb);
    }

    let most_significant_byte: Field = x[0] as Field;

    most_significant_byte.assert_max_bit_size::<8 - ((MOD_BITS + 7) / 8 * 8 - MOD_BITS)>();
    result
}

pub(crate) fn to_be_bytes<let N: u32, let MOD_BITS: u32>(
    val: [u128; N],
) -> [u8; (MOD_BITS + 7) / 8] {
    let mut result: [u8; (MOD_BITS + 7) / 8] = [0; (MOD_BITS + 7) / 8];
    // the last limb will not have all the 15 bytes so we deal with the full limbs first
    for i in 0..N - 1 {
        let index = N - i - 2;
        let limb_bytes: [u8; 15] = (val[index] as Field).to_be_bytes();
        for j in 0..15 {
            // we leave the space for the first byte empty, which would take (MOD_BITS+7)/8 - MOD_BITS/8 bytes
            result[i * 15 + j + (MOD_BITS + 7) / 8 - (N - 1) * 15] = limb_bytes[j];
        }
    }
    // now we deal with the last limb
    let last_limb_bytes: [u8; ((MOD_BITS + 7) / 8 - (N - 1) * 15)] =
        (val[N - 1] as Field).to_be_bytes();
    println(f"last_limb_bytes: {last_limb_bytes}");
    for i in 0..((MOD_BITS + 7) / 8 - (N - 1) * 15) {
        result[i] = last_limb_bytes[i];
    }
    result
}

pub(crate) fn to_le_bytes<let N: u32, let MOD_BITS: u32>(
    val: [u128; N],
) -> [u8; (MOD_BITS + 7) / 8] {
    let mut result: [u8; (MOD_BITS + 7) / 8] = [0; (MOD_BITS + 7) / 8];
    for i in 0..N - 1 {
        let limb_bytes: [u8; 15] = (val[i] as Field).to_le_bytes();
        for j in 0..15 {
            result[i * 15 + j] = limb_bytes[j];
        }
    }
    let last_limb_bytes: [u8; 15] = (val[N - 1] as Field).to_le_bytes();
    let num_last_bytes = ((MOD_BITS + 7) / 8 - (N - 1) * 15);
    for i in 0..num_last_bytes {
        result[(N - 1) * 15 + i] = last_limb_bytes[i];
    }
    result
}

pub(crate) fn from_le_bytes<let N: u32, let MOD_BITS: u32>(
    x: [u8; (MOD_BITS + 7) / 8],
) -> [u128; N] {
    let mut result: [u128; N] = [0; N];
    // first we deal with the full limbs
    for i in 0..N - 1 {
        let mut limb: u128 = 0;
        for j in 0..15 {
            limb *= 256;
            limb += x[(i + 1) * 15 - j - 1] as u128;
        }
        result[i] = limb;
    }
    // now we deal with the not full limb
    let num_bytes = (MOD_BITS + 7) / 8;
    let excess_bytes = N * 15 - num_bytes;
    let final_limb_bytes = 15 - excess_bytes;
    let mut limb: u128 = 0;
    for j in 0..final_limb_bytes {
        limb *= 256;
        limb += x[(N - 1) * 15 + final_limb_bytes - j - 1] as u128;
    }
    result[N - 1] = limb;
    let most_significant_byte: Field = x[(MOD_BITS + 7) / 8 - 1] as Field;
    // the most significant byte should have at most ((MOD_BITS+7)/8 * 8 - MOD_BITS) bits
    most_significant_byte.assert_max_bit_size::<8 - ((MOD_BITS + 7) / 8 * 8 - MOD_BITS)>();
    result
}

#[test]
fn test_from_to_le_bytes() {
    let val = [2; 32];
    let result: [u128; 3] = from_le_bytes::<3, 254>(val);
    let bytes: [u8; 32] = to_le_bytes::<3, 254>(result);
    assert(bytes == val);
}
