global TWO_POW_56: u64 = 0x100000000000000;
global TWO_POW_60: u64 = 0x1000000000000000;
global TWO_POW_64: Field = 0x10000000000000000;

// Decomposes a single field into two 120 bit fields
pub unconstrained fn split_120_bits(mut x: Field) -> (Field, Field) {
    // Here we're taking advantage of truncating 64 bit limbs from the input field
    // and then subtracting them from the input such that the field division is equivalent to integer division.
    let low_lower_64 = (x as u64) as Field;
    x = (x - low_lower_64) / TWO_POW_64;
    let low_upper_56 = ((x as u64) % TWO_POW_56) as Field;

    let low = low_lower_64 + TWO_POW_64 * low_upper_56;
    let high = (x - low_upper_56) / TWO_POW_56 as Field;

    (low, high)
}

/**
 * @brief Decomposes a single field into two 60 bit fields
 *
 * @description Expects the input limb to be in the range [0, ..., 2^{120 - 1}]
 **/
pub unconstrained fn split_60_bits(x: Field) -> (u64, u64) {
    // Here we're taking advantage of truncating 64 bit limbs from the input field
    // and then subtracting them from the input such that the field division is equivalent to integer division.
    let x_lower_64 = (x as u64);
    let low = x_lower_64 % TWO_POW_60;
    let high = ((x - (low as Field)) / TWO_POW_60 as Field) as u64;

    (low, high)
}

pub(crate) unconstrained fn __normalize_limbs<let N: u32>(
    input: [Field; N],
    range: u32,
) -> [Field; N] {
    let mut normalized: [Field; N] = [0; N];
    let mut inp: _ = input;
    for i in 0..(range - 1) {
        let (lo, hi) = split_120_bits(inp[i]);

        normalized[i] = lo;
        inp[i + 1] += hi;
    }
    {
        let (lo, hi) = split_120_bits(inp[range - 1]);
        normalized[range - 1] = lo;
        assert(hi == 0);
    }
    normalized
}
