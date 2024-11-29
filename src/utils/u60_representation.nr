use crate::utils::msb::get_msb64;
use crate::utils::split_bits;

/**
 * @brief U60Repr represents a BigNum element as a sequence of 60-bit unsigned integers.
 *
 * @description: used in unconstrained functions when computing witness values.
 * It is helpful to use u60 types when evaluating addition operations that can overflow the field modulus,
 * as well as when performing bit shifts.
 */
pub struct U60Repr<let N: u32, let NumSegments: u32> {
    pub(crate) limbs: [u64; N * NumSegments],
}

impl<let N: u32, let NumSegments: u32> std::ops::Add for U60Repr<N, NumSegments> {
    fn add(self, b: Self) -> Self {
        let mut result: Self = U60Repr { limbs: [0; N * NumSegments] };

        let mut carry: u64 = 0;
        for i in 0..N * NumSegments {
            let mut add: u64 = self.limbs[i] + b.limbs[i] + carry;
            carry = add >> 60;
            add = add - (carry << 60);
            result.limbs[i] = add;
        }
        result
    }
}

impl<let N: u32, let NumSegments: u32> std::ops::Sub for U60Repr<N, NumSegments> {
    fn sub(self, b: Self) -> Self {
        let mut result: Self = U60Repr { limbs: [0; N * NumSegments] };

        let mut borrow: u64 = 0;
        let mut borrow_in: u64 = 0;

        for i in 0..N * NumSegments {
            borrow = ((b.limbs[i] + borrow_in) > self.limbs[i]) as u64;
            let sub = (borrow << 60) + self.limbs[i] - b.limbs[i] - borrow_in;
            result.limbs[i] = sub;
            borrow_in = borrow;
        }

        result
    }
}

impl<let N: u32, let NumSegments: u32> std::convert::From<[Field; N]> for U60Repr<N, NumSegments> {
    fn from(input: [Field; N]) -> Self {
        let mut result: Self = U60Repr { limbs: [0; N * NumSegments] };
        for i in 0..(N) {
            let (lo, hi) = unsafe { split_bits::split_60_bits(input[i]) };
            result.limbs[2 * i] = lo;
            result.limbs[2 * i + 1] = hi;
        }
        result
    }
}

impl<let N: u32, let NumSegments: u32> std::convert::Into<[Field; N]> for U60Repr<N, NumSegments> {
    fn into(x: U60Repr<N, NumSegments>) -> [Field; N] {
        let mut result: [Field; N] = [0; N];
        let two_pow_60: Field = 0x1000000000000000;
        for i in 0..N {
            result[i] = x.limbs[2 * i] as Field + (x.limbs[2 * i + 1] as Field * two_pow_60);
        }
        result
    }
}

impl<let N: u32, let NumSegments: u32> std::cmp::Eq for U60Repr<N, NumSegments> {
    fn eq(self, other: Self) -> bool {
        self.limbs == other.limbs
    }
}

impl<let N: u32, let NumSegments: u32> U60Repr<N, NumSegments> {

    pub(crate) unconstrained fn new<let NumFieldSegments: u32>(
        x: [Field; N * NumFieldSegments],
    ) -> Self {
        let mut result: Self = U60Repr { limbs: [0; N * NumSegments] };
        for i in 0..(N * NumFieldSegments) {
            let (lo, hi) = split_bits::split_60_bits(x[i]);
            result.limbs[2 * i] = lo;
            result.limbs[2 * i + 1] = hi;
        }
        result
    }

    pub(crate) unconstrained fn one() -> Self {
        let mut result: Self = U60Repr { limbs: [0; N * NumSegments] };
        result.limbs[0] = 1;
        result
    }

    pub(crate) unconstrained fn into_field_array(
        x: U60Repr<N, NumSegments>,
    ) -> [Field; N * NumSegments / 2] {
        let mut result: [Field; N * NumSegments / 2] = [0; N * NumSegments / 2];
        let two_pow_60: Field = 0x1000000000000000;
        for i in 0..(N * NumSegments / 2) {
            result[i] = x.limbs[2 * i] as Field + (x.limbs[2 * i + 1] as Field * two_pow_60);
        }
        result
    }

    pub(crate) unconstrained fn gte(self, b: Self) -> bool {
        let mut result = false;
        let mut early_exit = false;
        for i in 0..(N * NumSegments) {
            if (b.limbs[(N * NumSegments) - 1 - i] < self.limbs[((N * NumSegments) - 1 - i)]) {
                result = true;
                early_exit = true;
                break;
            } else if (
                b.limbs[(N * NumSegments) - 1 - i] != self.limbs[((N * NumSegments) - 1 - i)]
            ) {
                result = false;
                early_exit = true;
                break;
            }
        }
        if (early_exit == false) {
            result = (self.limbs[0] == b.limbs[0]);
        }
        result
    }

    pub(crate) fn get_bit(self, bit: u32) -> bool {
        let segment_index = bit / 60;
        let uint_index = bit % 60;

        let limb: u64 = self.limbs[segment_index];
        let value = (limb >> uint_index as u8) & 1;
        value == 1
    }

    // note: shr cannot satisfy `Shr` Trait due to `shift` parameter being u64 and not u8 (shift value might be greater than 255)
    pub(crate) fn shr(self, shift: u32) -> Self {
        let mut result: Self = U60Repr { limbs: [0; N * NumSegments] };

        let num_shifted_limbs = shift / 60;
        let limb_shift = shift % 60;
        let remainder_shift = 60 - limb_shift;
        let mask: u64 = (((1 as u64) << limb_shift as u8) - 1) << remainder_shift as u8;
        result.limbs[0] = (self.limbs[0 + num_shifted_limbs] >> limb_shift as u8);

        for i in 1..((N * NumSegments) - num_shifted_limbs) {
            let value = self.limbs[i + num_shifted_limbs];
            result.limbs[i] = (value >> limb_shift as u8);
            let remainder: u64 = (value << remainder_shift as u8) & mask;
            result.limbs[i - 1] = result.limbs[i - 1] + remainder;
        }
        result
    }

    // note: shr cannot satisfy `Shr` Trait due to `shift` parameter being u64 and not u8 (shift value might be greater than 255)
    pub(crate) fn shr1(&mut self) {
        let value = self.limbs[NumSegments * N - 1];
        self.limbs[NumSegments * N - 1] = value >> 1;

        let mut remainder = (value & 1) << 59;

        for i in 0..N * NumSegments {
            let value = self.limbs[N * NumSegments - 1 - i];
            self.limbs[N * NumSegments - 1 - i] = (value >> 1) + remainder;
            remainder = (value << 59) & 0x800000000000000;
        }
    }

    // note: shr cannot satisfy `Shr` Trait due to `shift` parameter being u64 and not u8 (shift value might be greater than 255)
    pub(crate) fn shl(self, shift: u32) -> Self {
        let mut result: Self = U60Repr { limbs: [0; NumSegments * N] };

        let num_shifted_limbs = shift / 60;
        let limb_shift = (shift % 60) as u8;
        let remainder_shift: u8 = 60 - limb_shift as u8;

        // 83
        // limb shift = 1
        // inside shift = 19 bits to the left
        // meaning we have 19 carry bits and 41 remainder bits
        let mask: u64 = (1 as u64 << 60) - 1;
        //   let mask: u64 = (((1 as u64) << limb_shift as u8) - 1) << remainder_shift as u8;
        let value = self.limbs[0];

        let mut remainder = (value >> remainder_shift);
        result.limbs[num_shifted_limbs] = (value << (limb_shift as u8)) & mask;

        // shift 84. num shifted = 1
        for i in 1..((N * NumSegments) - num_shifted_limbs) {
            let value = self.limbs[i];
            let upshift = ((value << (limb_shift as u8)) + remainder) & mask;
            result.limbs[i + num_shifted_limbs] = upshift;
            remainder = (value >> remainder_shift);
            // let remainder: u64 = (self.limbs.get(i + num_shifted_limbs as u64) << remainder_shift as u8) & mask;
            // result.limbs.set(i - 1, result.limbs.get(i - 1) + remainder);
        }
        result
    }

    pub(crate) fn increment(&mut self) {
        let mut carry: u64 = 0;

        let mut add: u64 = self.limbs[0] + 1;
        carry = add >> 60;
        add = add - (carry << 60);
        self.limbs[0] = add;

        for i in 1..NumSegments * N {
            let mut add: u64 = self.limbs[i] + carry;
            carry = add >> 60;
            add = add - (carry << 60);
            self.limbs[i] = add;
        }
    }

    pub(crate) unconstrained fn get_msb(val: Self) -> u32 {
        let mut count = 0;
        for i in 0..N * NumSegments {
            let v = val.limbs[((N * NumSegments) - 1 - i)];
            if (v > 0) {
                count = 60 * ((N * NumSegments) - 1 - i) + get_msb64(v);
                break;
            }
        }
        count
    }
}
