use dep::std;

use crate::utils::arrayX::ArrayX;
use crate::utils::split_bits;
use crate::utils::msb::get_msb64;

/**
 * @brief U60Repr represents a BigNum element as a sequence of 60-bit unsigned integers.
 *
 * @description: used in unconstrained functions when computing witness values.
 * It is helpful to use u60 types when evaluating addition operations that can overflow the field modulus,
 * as well as when performing bit shifts.
 */
pub struct U60Repr<let N: u32, let NumSegments: u32>
{
    limbs: ArrayX<u64, N, NumSegments>
}

impl<let N: u32, let NumSegments: u32> std::ops::Add for U60Repr<N, NumSegments> {
    fn add(self, b: Self) -> Self {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };

        let mut carry: u64 = 0;
        for j in 0..NumSegments {
            for i in 0..N {
                let mut add: u64 = self.limbs.segments[j][i] + b.limbs.segments[j][i] + carry;
                carry = add >> 60;
                add = add - (carry << 60);
                result.limbs.segments[j][i] = add;
            }
        }

        result
    }
}

impl<let N: u32, let NumSegments: u32> std::ops::Sub for U60Repr<N, NumSegments> {
    fn sub(self, b: Self) -> Self {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };

        let mut borrow: u64 = 0;
        let mut borrow_in: u64 = 0;

        for j in 0..NumSegments {
            for i in 0..N {
                borrow = ((b.limbs.segments[j][i] + borrow_in) > self.limbs.segments[j][i]) as u64;
                let sub = (borrow << 60) + self.limbs.segments[j][i] - b.limbs.segments[j][i] - borrow_in;
                result.limbs.segments[j][i] = sub;
                borrow_in = borrow;
            }
        }
        result
    }
}

impl<let N: u32, let NumSegments: u32> std::convert::From<[Field; N]> for U60Repr<N, NumSegments> {
    fn from(input: [Field; N]) -> Self {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };
        for i in 0..(N) {
            let (lo, hi) = split_bits::split_60_bits(input[i]);
            result.limbs.set(2 * i, lo);
            result.limbs.set(2 * i + 1, hi);
        }
        result
    }
}

impl<let N: u32, let NumSegments: u32> std::convert::Into<[Field; N]> for U60Repr<N, NumSegments> {
    fn into(x: U60Repr<N, NumSegments>) -> [Field; N] {
        let mut result: [Field; N] = [0; N];
        let two_pow_60: Field = 0x1000000000000000;
        for i in 0..N {
            result[i] = x.limbs.get(2 * i) as Field + (x.limbs.get(2 * i + 1) as Field * two_pow_60);
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

    unconstrained fn new<let NumFieldSegments: u32>(x: ArrayX<Field, N, NumFieldSegments>) -> Self {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };
        for i in 0..(N * NumFieldSegments) {
            let (lo, hi) = split_bits::split_60_bits(x.get(i));
            result.limbs.set(2 * i, lo);
            result.limbs.set(2 * i + 1, hi);
        }
        result
    }

    unconstrained fn one() -> Self {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };
        result.limbs.set(0, 1);
        result
    }

    unconstrained fn into_arrayX<let NumFieldSegments: u32>(x: U60Repr<N, NumSegments>) -> ArrayX<Field, N, NumFieldSegments> {
        let mut result: ArrayX<Field, N, NumFieldSegments> = ArrayX { segments: [[0; N]; NumFieldSegments] };
        let two_pow_60: Field = 0x1000000000000000;
        for i in 0..(N * NumFieldSegments) {
            result.set(
                i,
                x.limbs.get(2 * i) as Field + (x.limbs.get(2 * i + 1) as Field * two_pow_60)
            );
        }
        result
    }

    unconstrained fn gte(self, b: Self) -> bool {
        let mut result = false;
        let mut early_exit = false;
        for i in 0..(N * NumSegments) {
            if (b.limbs.get((N * NumSegments) - 1 - i) < (self.limbs.get((N * NumSegments) - 1 - i))) {
                result = true;
                early_exit = true;
                break;
            } else if (b.limbs.get((N * NumSegments) - 1 - i) != (self.limbs.get((N * NumSegments) - 1 - i))) {
                result = false;
                early_exit = true;
                break;
            }
        }
        if (early_exit == false) {
            result = (self.limbs.get(0) == b.limbs.get(0));
        }
        result
    }

    fn get_bit(self, bit: u32) -> bool {
        let segment_index = bit / 60;
        let uint_index = bit % 60;

        let limb: u64 = self.limbs.get(segment_index);
        let value = (limb >> uint_index as u8) & 1;
        value == 1
    }

    // note: shr cannot satisfy `Shr` Trait due to `shift` parameter being u64 and not u8 (shift value might be greater than 255)
    fn shr(self, shift: u32) -> Self {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };

        let num_shifted_limbs = shift / 60;
        let limb_shift = shift % 60;
        let remainder_shift = 60 - limb_shift;
        let mask: u64 = (((1 as u64) << limb_shift as u8) - 1) << remainder_shift as u8;
        result.limbs.set(
            0,
            (self.limbs.get(0 + num_shifted_limbs) >> limb_shift as u8)
        );

        for i in 1..((N * NumSegments) - num_shifted_limbs) {
            let value = self.limbs.get(i + num_shifted_limbs);
            result.limbs.set(i, (value >> limb_shift as u8));
            let remainder: u64 = (value << remainder_shift as u8) & mask;
            result.limbs.set(i - 1, result.limbs.get(i - 1) + remainder);
        }
        result
    }

    // note: shr cannot satisfy `Shr` Trait due to `shift` parameter being u64 and not u8 (shift value might be greater than 255)
    fn shr1(&mut self) {
        let value = self.limbs.segments[NumSegments - 1][N - 1];
        self.limbs.segments[NumSegments - 1][N - 1] = value >> 1;

        let mut remainder = (value & 1) << 59;

        for j in 0..NumSegments {
            for i in 0..N {
                let value = self.limbs.segments[NumSegments - 1 - j][N - 1 - i];
                self.limbs.segments[NumSegments - 1 - j][N - 1 - i] = (value >> 1) + remainder;
                remainder = (value << 59) & 0x800000000000000;
            }
        }
    }

    // note: shr cannot satisfy `Shr` Trait due to `shift` parameter being u64 and not u8 (shift value might be greater than 255)
    fn shl(self, shift: u32) -> Self {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };

        let num_shifted_limbs = shift / 60;
        let limb_shift = (shift % 60) as u8;
        let remainder_shift: u8 = 60 - limb_shift as u8;

        // 83
        // limb shift = 1
        // inside shift = 19 bits to the left
        // meaning we have 19 carry bits and 41 remainder bits
        let mask: u64 = (1 as u64 << 60) - 1;
        //   let mask: u64 = (((1 as u64) << limb_shift as u8) - 1) << remainder_shift as u8;
        let value = self.limbs.get(0);

        let mut remainder = (value >> remainder_shift);
        result.limbs.set(num_shifted_limbs, (value << (limb_shift as u8)) & mask);

        // shift 84. num shifted = 1

        for i in 1..((N * NumSegments) - num_shifted_limbs) {
            let value = self.limbs.get(i);
            let upshift = ((value << (limb_shift as u8)) + remainder) & mask;
            result.limbs.set(i + num_shifted_limbs, upshift);
            remainder = (value >> remainder_shift);
            // let remainder: u64 = (self.limbs.get(i + num_shifted_limbs as u64) << remainder_shift as u8) & mask;
            // result.limbs.set(i - 1, result.limbs.get(i - 1) + remainder);
        }
        result
    }

    fn increment(&mut self) {
        let mut carry: u64 = 0;

        let mut add: u64 = self.limbs.segments[0][0] + 1;
        carry = add >> 60;
        add = add - (carry << 60);
        self.limbs.segments[0][0] = add;
        for i in 1..N {
            let mut add: u64 = self.limbs.segments[0][i] + carry;
            carry = add >> 60;
            add = add - (carry << 60);
            self.limbs.segments[0][i] = add;
        }
        for j in 1..NumSegments {
            for i in 0..N {
                let mut add: u64 = self.limbs.segments[j][i] + carry;
                carry = add >> 60;
                add = add - (carry << 60);
                self.limbs.segments[j][i] = add;
            }
        }
    }

    unconstrained  fn get_msb(val: Self) -> u32 {
        let mut count = 0;
        for i in 0..N * NumSegments {
            let v = val.limbs.get((N * NumSegments) - 1 - i);
            if (v > 0) {
                count = 60 * ((N * NumSegments) - 1 - i) + get_msb64(v);
                break;
            }
        }
        count
    }
}
