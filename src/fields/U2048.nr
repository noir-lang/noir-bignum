use crate::bignum::BigNum;
use crate::bignum::make_bignum_impls;
use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;
pub struct U2048Params {}

pub type U2048 = BigNum<18, 2049, U2048Params>;

impl BigNumParamsGetter<18, 2049> for U2048Params {
    fn get_params() -> BigNumParams<18, 2049> {
        U2048_PARAMS
    }
}

pub global U2048_PARAMS: BigNumParams<18, 2049> = BigNumParams {
    has_multiplicative_inverse: false,
    modulus: [
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x0100,
    ],
    double_modulus: [
        0x01000000000000000000000000000000,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0x01ff,
    ],
    redc_param: [
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x4000,
    ],
};

pub struct U2048 {
    limbs: [u128; 18],
}

#[make_bignum_impls(18, 2049, quote {U2048}, quote {U2048Params})]
pub mod U2048_impls {
    use crate::bignum::BigNumTrait;
}
