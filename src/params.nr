use crate::utils::u60_representation::U60Repr;

pub(crate) struct BigNumParams<let N: u32, let MOD: u32> {
    has_multiplicative_inverse: bool,

    // @brief modulus_bits = log2(modulus) rounded up
    // This needs to be a comptime const, so that it can be used as an argument to std::field::assert_constant()
    // modulus_bits_getter: fn () -> u32,

    // @brief modulus: all BigNum operations are evaluated modulo this value
    modulus: [Field; N],

    // @brief modulus but represented in a U60Repr form
    modulus_u60: U60Repr<N, 2>,
    modulus_u60_x4: U60Repr<N, 4>,

    // @brief double_modulus: used when performing negations and subtractions
    double_modulus: [Field; N],

    // @brief redc_param used for __barrett_reduction. See https://en.wikipedia.org/wiki/Barrett_reduction
    redc_param: [Field; N],
}

// To be implemented by the user, or within the prebuilt options in the `fields/` dir.
pub(crate) trait BigNumParamsGetter<let N: u32, let MOD: u32> {
    fn get_params() -> BigNumParams<N, MOD>;
}

// // To be implemented by the user, or within the prebuilt options in the `fields/` dir.
// pub(crate) trait HasGetModulusBits {
//     comptime fn get_modulus_bits() -> u32; // This needs to be a comptime const, so that it can be used as an argument to std::field::assert_constant()
// }

// impl<let N: u32> HasGetModulusBits<N> for BigNumParams<N> {}
// impl<let N: u32> RuntimeBigNumParamsTrait<N> for BigNumParams<N> {}

impl<let N: u32, let MOD: u32> BigNumParams<N, MOD> {
    fn new(
        has_multiplicative_inverse: bool,
        // modulus_bits_getter: fn() -> u32,
        modulus: [Field; N],
        redc_param: [Field; N]
    ) -> Self {
        Self {
            has_multiplicative_inverse,
            // modulus_bits_getter,
            modulus,
            modulus_u60: U60Repr::from(modulus),
            modulus_u60_x4: U60Repr::from(modulus),
            double_modulus: get_double_modulus(modulus),
            redc_param
        }
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

// /**
//  * @brief BigNumParamsGetter defines a "field" with which to parametrise BigNum.
//  * @description The "field" does not need to be prime, any value *should* work (TODO: test!)
// **/
// trait BigNumParamsGetter<let N: u32> {
//     fn has_multiplicative_inverse() -> bool;
//     // @brief modulus_bits = log2(modulus) rounded up
//     fn modulus_bits() -> u32;
//     fn modulus() -> [Field; N];
//     fn modulus_u60() -> U60Repr<N, 2>;
//     fn modulus_u60_x4() -> U60Repr<N, 4>;
//     // @brief double_modulus: used when performing negations and subtractions
//     fn double_modulus() -> [Field; N];
//     // redc_param used for __barrett_reduction. See https://en.wikipedia.org/wiki/Barrett_reduction
//     redc_param: [Field; N],
// }

