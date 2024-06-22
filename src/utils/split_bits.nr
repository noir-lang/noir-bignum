
// Decomposes a single field into two 120 bit fields and a carry
unconstrained pub fn split_120_bits(x: Field) -> (Field, Field) {
    let x_bytes: [u8] = x.to_le_bytes(32);

    let mut low: Field = 0;
    let mut high: Field = 0;

    let offsets: [Field; 16] = [
        1, 0x100, 0x10000, 0x1000000, 0x100000000, 0x10000000000, 0x1000000000000, 0x100000000000000, 0x10000000000000000, 0x1000000000000000000, 0x100000000000000000000, 0x10000000000000000000000, 0x1000000000000000000000000, 0x100000000000000000000000000, 0x10000000000000000000000000000, 0x1000000000000000000000000000000
    ];

    for i in 0..15 {
        low += (x_bytes[i] as Field) * offsets[i];
        high += (x_bytes[i + 15] as Field) * offsets[i];
    }
    high += (x_bytes[30] as Field) * offsets[15];
    assert(x_bytes[31] == 0);
    (low, high)
}

/**
 * @brief Decomposes a single field into two 60 bit fields
 *
 * @description Expects the input limb to be in the range [0, ..., 2^{120 - 1}]
 **/
unconstrained pub fn split_60_bits(x: Field) -> (u64, u64) {
    let x_bytes = x.to_le_bytes(32);

    let mut low: u64 = 0;
    let mut high: u64 = 0;

    let offsets: [u64; 8] = [1, 0x100, 0x10000, 0x1000000, 0x100000000, 0x10000000000, 0x1000000000000, 0x100000000000000];
    for i in 0..8 {
        low += (x_bytes[i] as u64) * offsets[i];
        high += (x_bytes[i + 8] as u64) * offsets[i];
    }
    let t1 = low >> 60;
    let mask = ((1 as u64) << 60 as u8) - 1;
    low = low & mask;
    high = (high << 4) | t1;
    (low, high)
}
