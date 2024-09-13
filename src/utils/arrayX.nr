use dep::std;
use crate::utils::split_bits;

/**
 * @brief Array abstraction, whose size is a known multiplier `SizeMultiplier` of an initial size `N`
 *
 * @note ArrayX is a workaround for the lack of arithmetic over generics.
 *       e.g. [Field; N * 2] is not currently possible
 *       This abstraction can be removed once Noir supports arithmetic on generics.
**/
struct ArrayX<T, let N: u32, let SizeMultiplier: u32> {
    segments: [[T; N]; SizeMultiplier]
}

impl<T, let N: u32, let SizeMultiplier: u32> std::convert::From<[T; N]> for ArrayX<T, N, SizeMultiplier> where T: std::default::Default {
    fn from(input: [T; N]) -> Self {
        assert(N == 1);
        let mut result = ArrayX::new();
        result.segments[0] = input;
        result
    }
}

impl<T, let N: u32, let SizeMultiplier: u32> std::convert::From<[[T; N]; SizeMultiplier]> for ArrayX<T, N, SizeMultiplier> where T: std::default::Default {
    fn from(input: [[T; N]; SizeMultiplier]) -> Self {
        ArrayX { segments: input }
    }
}

impl<T, let N: u32, let SizeMultiplier: u32> std::cmp::Eq for ArrayX<T, N, SizeMultiplier> where T: std::cmp::Eq {
    fn eq(self, other: Self) -> bool {
        let mut result: bool = true;
        for i in 0..SizeMultiplier {
            for j in 0..N {
                result = result & (self.segments[i][j] == other.segments[i][j]);
            }
        }
        result
    }
}

impl<T, let N: u32, let SizeMultiplier: u32> ArrayX<T, N, SizeMultiplier> {

    fn new() -> Self where T: std::default::Default {
        ArrayX { segments: [[T::default(); N]; SizeMultiplier] }
    }

    fn mul_assign(&mut self, i: u32, rhs: T) where T: std::ops::Mul {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index] *= rhs;
    }

    fn add_assign(&mut self, i: u32, rhs: T) where T: std::ops::Add {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index] += rhs;
    }

    fn sub_assign(&mut self, i: u32, rhs: T) where T: std::ops::Sub {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index] -= rhs;
    }

    fn set(&mut self, i: u32, x: T) {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index] = x;
    }

    fn get(self, i: u32) -> T {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index]
    }
}

impl<let N: u32, let SizeMultiplier: u32> ArrayX<Field, N, SizeMultiplier> {

    unconstrained fn __normalize_limbs(self, range: u32) -> Self {
        let mut normalized: Self = ArrayX::new();
        let mut inp = self;
        // (9 limb mul = 17 product terms)

        // a2 a1 a0
        // b2 b1 b0

        // a0b0
        // a1b0 a0b1
        // a2b0 a1b1 a0b2
        // a2b1 a1b2
        // a2b2

        // r0 lo
        // r0 hi + r1 lo
        // r1 hi + r2 lo
        // r2 hi + r3 lo
        // r3 hi + r4 lo
        // r4 hi = 6?
        for i in 0..(range - 1) {
            let (lo, hi) = split_bits::split_120_bits(inp.get(i));

            normalized.set(i, lo);
            inp.set(i + 1, inp.get(i + 1) + hi);
        }
        {
            let (lo, hi) = split_bits::split_120_bits(inp.get(range - 1));
            normalized.set(range - 1, lo);
            assert(hi == 0);
        }
        normalized
    }
}
