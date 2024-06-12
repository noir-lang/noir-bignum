unconstrained fn get_msb64(x: u64) -> u64 {
    let MUL_DE_BRUIJN_BIT: [u64; 128] = [
        0,// change to 1 if you want bitSize(0) = 1
        48, -1, -1, 31, -1, 15, 51, -1, 63, 5, -1, -1, -1, 19, -1,
        23, 28, -1, -1, -1, 40, 36, 46, -1, 13, -1, -1, -1, 34, -1, 58,
        -1, 60, 2, 43, 55, -1, -1, -1, 50, 62, 4, -1, 18, 27, -1, 39,
        45, -1, -1, 33, 57, -1, 1, 54, -1, 49, -1, 17, -1, -1, 32, -1,
        53, -1, 16, -1, -1, 52, -1, -1, -1, 64, 6, 7, 8, -1, 9, -1,
        -1, -1, 20, 10, -1, -1, 24, -1, 29, -1, -1, 21, -1, 11, -1, -1,
        41, -1, 25, 37, -1, 47, -1, 30, 14, -1, -1, -1, -1, 22, -1, -1,
        35, 12, -1, -1, -1, 59, 42, -1, -1, 61, 3, 26, 38, 44, -1, 56
    ];
    let mut v = x;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v |= v >> 32;
    MUL_DE_BRUIJN_BIT[(v * 0x6c04f118e9966f6b) >> 57]
}

unconstrained fn gt<N>(a: [Field; N], b: [Field; N]) -> bool {
    let mut result = false;
    for i in 0..N {
        if (b[N - 1 - i].lt(a[N - 1 - i])) {
            result = true;
            break;
        } else if (b[N - 1 - i] != (a[N - 1 - i])) {
            result = false;
            break;
        }
    }
    result
}

unconstrained fn get_msb_for_field(x: Field) -> u64 {
    let x_bytes = x.to_le_bytes(32);
    let mut count: u64 = 0;
    for i in 0..32 {
        let byte: u8 = x_bytes[31 - i];
        if (byte > 0) {
            let mut bytebits: u64 = 0;
            if (byte & 128 == 1) {
                bytebits = 7;
            } else if (byte & 64 == 1) {
                bytebits = 6;
            } else if (byte & 32 == 1) {
                bytebits = 5;
            } else if (byte & 16 == 1) {
                bytebits = 4;
            } else if (byte & 8 == 1) {
                bytebits = 3;
            } else if (byte & 4 == 1) {
                bytebits = 2;
            } else if (byte & 2 == 1) {
                bytebits = 1;
            }
            count = (i * 8) + bytebits;
            break;
        }
    }
    count
}

unconstrained fn get_msb<N>(a: [Field; N]) -> u64 {
    let mut count: u64 = 0;
    let mut counts: [u64; N] = [0; N];
    for i in 0..N {
        if ((0 as Field).lt(a[N - 1 - i])) {
            counts[i] = (i * 120) + get_msb_for_field(a[N - 1 - i]);
        }
    }

    // the limbs in `A` can overlap when this function is called, need to factor this in
    for i in 1..N {
        if (counts[N - 1 - i] > counts[N - 2 - i]) {
            count = counts[N - 1 - i];
            break;
        } else if (counts[N - 2 - i] > 0) {
            count = counts[N - 2 - i];
            break;
        }
    }
    count
}

// Decomposes a single field into two 120 bit fields and a carry
unconstrained fn compute_decomposition(x: Field) -> (Field, Field, Field) {
    let x_bytes = x.to_le_bytes(32);

    let mut low: Field = 0;
    let mut high: Field = 0;

    let offsets: [Field; 15] = [
        1, 0x100, 0x10000, 0x1000000, 0x100000000, 0x10000000000, 0x1000000000000, 0x100000000000000, 0x10000000000000000, 0x1000000000000000000, 0x100000000000000000000, 0x10000000000000000000000, 0x1000000000000000000000000, 0x100000000000000000000000000, 0x10000000000000000000000000000
    ];
    for i in 0..15 {
        low += (x_bytes[i] as Field) * offsets[i];
        high += (x_bytes[i + 15] as Field) * offsets[i];
    }
    (low, high, x_bytes[31] as Field)
}

/*

    unconstrained fn get_msb(self) -> u64 {
        let mut count: u64 = 0;
        for i in 0..N {
            if (self.limbs[N - 1 - i] > 0) {
                count = 60 * i + get_msb64(self.limbs[N - 1 - i]);
                break;
            }
        }
        count
    }
    */
