use crate::utils::u60_representation::U60Repr;

pub struct BigNumParams<let N: u32, let MOD_BITS: u32> {
    pub has_multiplicative_inverse: bool,

    // @brief modulus: all BigNum operations are evaluated modulo this value
    pub modulus: [Field; N],

    // @brief modulus but represented in a U60Repr form
    pub modulus_u60: U60Repr<N, 2>,
    pub modulus_u60_x4: U60Repr<N, 4>,

    // @brief double_modulus: used when performing negations and subtractions
    pub double_modulus: [Field; N],

    // @brief redc_param used for __barrett_reduction. See https://en.wikipedia.org/wiki/Barrett_reduction
    pub redc_param: [Field; N],
}

// To be implemented by the user for any BigNum they define, or within the predefined BigNums in the `fields/` dir.
pub trait BigNumParamsGetter<let N: u32, let MOD_BITS: u32> {
    pub fn get_params() -> BigNumParams<N, MOD_BITS>;
}

impl<let N: u32, let MOD_BITS: u32> BigNumParams<N, MOD_BITS> {
    pub fn new(
        has_multiplicative_inverse: bool,
        modulus: [Field; N],
        redc_param: [Field; N],
    ) -> Self {
        Self {
            has_multiplicative_inverse,
            modulus,
            modulus_u60: U60Repr::from(modulus),
            modulus_u60_x4: U60Repr::from(modulus),
            double_modulus: get_double_modulus(modulus),
            redc_param,
        }
    }
}

impl<let N: u32, let MOD_BITS: u32> std::cmp::Eq for BigNumParams<N, MOD_BITS> {
    fn eq(self, other: Self) -> bool {
        (self.has_multiplicative_inverse == other.has_multiplicative_inverse)
            & (self.modulus == other.modulus)
            & (self.modulus_u60 == other.modulus_u60)
            & (self.modulus_u60_x4 == other.modulus_u60_x4)
            & (self.double_modulus == other.double_modulus)
            & (self.redc_param == other.redc_param)
    }
}

fn get_double_modulus<let N: u32>(modulus: [Field; N]) -> [Field; N] {
    let TWO_POW_120: Field = 0x1000000000000000000000000000000;
    let m: U60Repr<N, 2> = U60Repr::from(modulus);
    let mut result: [Field; N] = U60Repr::into(m + m);

    result[0] += TWO_POW_120;
    for i in 1..N - 1 {
        result[i] += (TWO_POW_120 - 1);
    }
    result[N - 1] -= 1;
    result
}
