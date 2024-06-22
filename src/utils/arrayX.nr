use dep::std;

/**
 * @brief Array abstraction, whose size is a known multiplier `SizeMultiplier` of an initial size `N`
 *
 * @note ArrayX is a workaround for the lack of arithmetic over generics.
 *       e.g. [Field; N * 2] is not currently possible
 *       This abstraction can be removed once Noir supports arithmetic on generics.
**/
struct ArrayX<T, N, SizeMultiplier> {
    segments: [[T; N]; SizeMultiplier]
}

impl<T, N, SizeMultiplier> std::convert::From<[T; N]> for ArrayX<T, N, SizeMultiplier> where T: std::default::Default { 
    fn from(input: [T; N]) -> Self {
        assert(N == 1);
        let mut result = ArrayX::new();
        result.segments[0] = input;
        result
    }
}

impl<T, N, SizeMultiplier> std::convert::From<[[T; N]; SizeMultiplier]> for ArrayX<T, N, SizeMultiplier> where T: std::default::Default { 
    fn from(input: [[T; N]; SizeMultiplier]) -> Self {
        ArrayX{ segments: input }
    }
}

impl<T, N, SizeMultiplier> std::cmp::Eq for ArrayX<T, N, SizeMultiplier> where T: std::cmp::Eq { 
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

impl<T, N, SizeMultiplier> ArrayX<T, N, SizeMultiplier> {

    fn new() -> Self where T: std::default::Default {
        ArrayX { segments: [[T::default(); N]; SizeMultiplier] }
    }

    fn mul_assign(&mut self, i: u64, rhs: T) where T: std::ops::Mul {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index] *= rhs;
    }

    fn add_assign(&mut self, i: u64, rhs: T) where T: std::ops::Add {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index] += rhs;
    }

    fn sub_assign(&mut self, i: u64, rhs: T) where T: std::ops::Sub {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index] -= rhs;
    }

    fn set(&mut self, i: u64, x: T) {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index] = x;
    }

    fn get(self, i: u64) -> T {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index]
    }
}
