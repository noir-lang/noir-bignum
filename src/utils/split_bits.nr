global TWO_POW_56: u64 = 0x100000000000000;
pub(crate) global TWO_POW_60: u64 = 0x1000000000000000;
global TWO_POW_64: Field = 0x10000000000000000;

//fields to u60rep conversion
// field elements are 254 bits
// so there will be 5 limbs
pub(crate) unconstrained fn field_to_u60rep(mut x: Field) -> (u64, u64, u64, u64, u64) {
    // get the first 60 bits by casting to u64 and then taking the lower 60 bits
    // we use the fact that this casting drops everything above 64 bits
    let x_first_u64 = (x as u64);
    let first: u64 = x_first_u64 % TWO_POW_60;
    // this becomes the same as a integer division because we're removing the remainder
    x = (x - (first as Field)) / (TWO_POW_60 as Field);
    let x_second_u64 = (x as u64);
    let second = x_second_u64 % TWO_POW_60;
    x = (x - (second as Field)) / (TWO_POW_60 as Field);
    let x_third_u64 = (x as u64);
    let third = x_third_u64 % TWO_POW_60;
    x = (x - (third as Field)) / (TWO_POW_60 as Field);
    let x_fourth_u64 = (x as u64);
    let fourth = x_fourth_u64 % TWO_POW_60;
    x = (x - (fourth as Field)) / (TWO_POW_60 as Field);
    let x_fifth_u64 = (x as u64);
    let fifth = x_fifth_u64 % TWO_POW_60;
    (first, second, third, fourth, fifth)
}

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

/// Decomposes a single field into two 60 bit fields
///
/// Expects the input limb to be in the range [0, ..., 2^{120 - 1}]
unconstrained fn __split_60_bits(x: Field) -> (u64, u64) {
    // Here we're taking advantage of truncating 64 bit limbs from the input field
    // and then subtracting them from the input such that the field division is equivalent to integer division.
    let x_lower_64 = (x as u64);
    let low = x_lower_64 % TWO_POW_60;
    let high = ((x - (low as Field)) / TWO_POW_60 as Field) as u64;

    (low, high)
}

/// Decomposes a single field into two 60 bit fields
///
/// Expects the input limb to be in the range [0, ..., 2^{120 - 1}]
pub fn split_60_bits(x: Field) -> (u64, u64) {
    // We assert that the two returned limbs fit within 60 bits each
    // and reconstruct `x` when added together.
    let (lo, hi) = unsafe { __split_60_bits(x) };
    if !std::runtime::is_unconstrained() {
        let lo_field = lo as Field;
        let hi_field = hi as Field;
        lo_field.assert_max_bit_size::<60>();
        hi_field.assert_max_bit_size::<60>();
        assert_eq(lo_field + (TWO_POW_60 as Field) * hi_field, x);
    }

    (lo, hi)
}

pub(crate) unconstrained fn __normalize_limbs<let N: u32>(
    input: [Field; N],
    range: u32,
) -> [Field; N] {
    let mut normalized: [Field; N] = [0; N];
    let mut next: Field = input[0];
    for i in 0..(range - 1) {
        let (lo, hi) = split_120_bits(next);

        normalized[i] = lo;
        next = input[i + 1] + hi;
    }
    {
        let (lo, hi) = split_120_bits(next);
        normalized[range - 1] = lo;
        assert(hi == 0);
    }
    normalized
}
