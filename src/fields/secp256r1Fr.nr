use crate::bignum::BigNum;
use crate::bignum::make_bignum_impls;
use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;
pub struct Secp256r1_Fr_Params {}

// pub type Secp256r1_Fr = BigNum<3, 256, Secp256r1_Fr_Params>;

impl BigNumParamsGetter<3, 256> for Secp256r1_Fr_Params {
    fn get_params() -> BigNumParams<3, 256> {
        Secp256r1_Fr_PARAMS
    }
}

pub global Secp256r1_Fr_PARAMS: BigNumParams<3, 256> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xe6faada7179e84f3b9cac2fc632551, 0xffff00000000ffffffffffffffffbc, 0xffff],
    double_modulus: [
        0x01cdf55b4e2f3d09e7739585f8c64aa2,
        0x01fffe00000001ffffffffffffffff78,
        0x01fffe,
    ],
    redc_param: [0x90552df1a6c21012ffd85eedf9bfe6, 0x0fffffffffffffffeffffffff431, 0x100000],
};

pub struct Secp256r1_Fr {
    limbs: [u128; 3],
}

impl BigNumParamsGetter<3, 256> for Secp256r1_Fr {
    fn get_params() -> BigNumParams<3, 256> {
        Secp256r1_Fr_PARAMS
    }
}

#[make_bignum_impls(3, 256, quote {Secp256r1_Fr}, quote {Secp256r1_Fr_Params})]
pub mod Secp256r1_Fr_impls {
    use crate::bignum::BigNumTrait;
    use super::{Secp256r1_Fr, Secp256r1_Fr_Params};
}
