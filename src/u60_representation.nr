use dep::std;

use crate::arrayX::ArrayX;
use crate::split_bits;

/**
 * @brief U60Repr represents a BigNum element as a sequence of 60-bit unsigned integers.
 *
 * @description: used in unconstrained functions when computing witness values.
 * It is helpful to use u60 types when evaluating addition operations that can overflow the field modulus,
 * as well as when performing bit shifts.
 */
struct U60Repr<N, NumSegments>
{
    limbs: ArrayX<u64, N, NumSegments>
}

impl<N, NumSegments> std::ops::Add for U60Repr<N, NumSegments> {
    fn add(self, b: Self) -> Self {
        let a = self;
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };

        let mut carry: u64 = 0;
        for i in 0..(N * NumSegments) {
            let mut add: u64 = a.limbs.get(i) + b.limbs.get(i) + carry;
            carry = add >> 60;
            add = add - (carry << 60);
            result.limbs.set(i, add);
        }
        result
    }
}

impl<N, NumSegments> std::ops::Sub for U60Repr<N, NumSegments> {
    fn sub(self, b: Self) -> Self {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };

        let mut borrow: u64 = 0;
        let mut borrow_in: u64 = 0;
        for i in 0..(N * NumSegments) {
            borrow = ((b.limbs.get(i) + borrow_in) > self.limbs.get(i)) as u64;
            let sub = (borrow << 60) + self.limbs.get(i) - b.limbs.get(i) - borrow_in;
            result.limbs.set(i, sub);
            borrow_in = borrow;
        }
        result
    }
}

impl<N, NumSegments> U60Repr<N, NumSegments> {

    unconstrained fn new<NumFieldSegments>(x: ArrayX<Field, N, NumFieldSegments>) -> Self {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };
        for i in 0..(N * NumFieldSegments) {
            let (lo, hi) = split_bits::split_60_bits(x.get(i));
            result.limbs.set(2 * i, lo);
            result.limbs.set(2 * i + 1, hi);
        }
        result
    }

    unconstrained fn from_array(x: [Field; N]) -> Self {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };
        for i in 0..(N) {
            let (lo, hi) = split_bits::split_60_bits(x[i]);
            result.limbs.set(2 * i, lo);
            result.limbs.set(2 * i + 1, hi);
        }
        result
    }

    unconstrained fn into_arrayX<NumFieldSegments>(x: U60Repr<N, NumSegments>) -> ArrayX<Field, N, NumFieldSegments> {
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

    unconstrained fn into_array(x: U60Repr<N, NumSegments>) -> [Field; N] {
        let mut result: [Field; N] = [0; N];
        let two_pow_60: Field = 0x1000000000000000;
        for i in 0..N {
            result[i] = x.limbs.get(2 * i) as Field + (x.limbs.get(2 * i + 1) as Field * two_pow_60);
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

    fn get_bit(self, bit: u64) -> bool {
        let segment_index = bit / 60;
        let uint_index = bit % 60;

        let limb: u64 = self.limbs.get(segment_index);
        let value = (limb >> uint_index as u8) & 1;
        value == 1
    }

    // note: shr cannot satisfy `Shr` Trait due to `shift` parameter being u64 and not u8 (shift value might be greater than 255)
    fn shr(self, shift: u64) -> Self {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };

        let num_shifted_limbs: u64 = shift / 60;
        let limb_shift = shift % 60;
        let remainder_shift = 60 - limb_shift;
        // if (limb_shift == 0) {
        //     for i in 0..(N * NumSegments) as u64 {
        //         result.limbs.set(i, self.limbs.get(i + num_shifted_limbs as u64));
        //     }
        // } else {
        let mask: u64 = (((1 as u64) << limb_shift as u8) - 1) << remainder_shift as u8;
        result.limbs.set(
            0,
            (self.limbs.get(0 + num_shifted_limbs as u64) >> limb_shift as u8)
        );

        for i in 1..((N * NumSegments) - num_shifted_limbs) as u64 {
            result.limbs.set(
                i,
                (self.limbs.get(i + num_shifted_limbs as u64) >> limb_shift as u8)
            );
            //    if (i > 0) {
            let remainder: u64 = (self.limbs.get(i + num_shifted_limbs as u64) << remainder_shift as u8) & mask;
            result.limbs.set(i - 1, result.limbs.get(i - 1) + remainder);
            //    }
        }
        //    }
        result
    }
}
