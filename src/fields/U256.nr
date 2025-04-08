use crate::bignum::BigNumTrait;
use crate::bignum::derive_bignum_impl;
use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;

pub struct U256Params {}

impl BigNumParamsGetter<3, 257> for U256Params {
    fn get_params() -> BigNumParams<3, 257> {
        U256_PARAMS
    }
}

pub global U256_PARAMS: BigNumParams<3, 257> = BigNumParams {
    has_multiplicative_inverse: false,
    modulus: [0x00, 0x00, 0x010000],
    double_modulus: [
        0x01000000000000000000000000000000,
        0xffffffffffffffffffffffffffffff,
        0x01ffff,
    ],
    redc_param: [0x00, 0x00, 0x400000],
};

#[derive_bignum_impl(3, 257, quote {U256_PARAMS})]
pub struct U256 {
    limbs: [u128; 3],
}
