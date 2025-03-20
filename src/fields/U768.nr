use crate::bignum::BigNum;
use crate::bignum::make_bignum_impls;
use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;

pub struct U768Params {}

// pub type U768 = BigNum<7, 769, U768Params>;

impl BigNumParamsGetter<7, 769> for U768Params {
    fn get_params() -> BigNumParams<7, 769> {
        U768_PARAMS
    }
}

pub global U768_PARAMS: BigNumParams<7, 769> = BigNumParams {
    has_multiplicative_inverse: false,
    modulus: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01000000000000],
    double_modulus: [
        0x01000000000000000000000000000000,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0x01ffffffffffff,
    ],
    redc_param: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40000000000000],
};

pub struct U768 {
    limbs: [u128; 7],
}

#[make_bignum_impls(7, 769, quote {U768}, quote {U768Params})]
pub mod U768_impls {
    use crate::bignum::BigNumTrait;
}
