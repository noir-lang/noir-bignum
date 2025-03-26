use crate::bignum::BigNumTrait;
use crate::bignum::make_bignum_impls;
use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;

pub struct Secp256k1_Fr_Params {}

impl BigNumParamsGetter<3, 256> for Secp256k1_Fr_Params {
    fn get_params() -> BigNumParams<3, 256> {
        Secp256k1_Fr_PARAMS
    }
}

pub global Secp256k1_Fr_PARAMS: BigNumParams<3, 256> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xaedce6af48a03bbfd25e8cd0364141, 0xfffffffffffffffffffffffffffeba, 0xffff],
    double_modulus: [
        0x015db9cd5e9140777fa4bd19a06c8282,
        0x01fffffffffffffffffffffffffffd74,
        0x01fffe,
    ],
    redc_param: [0x1231950b75fc4402da1732fc9bec09, 0x1455, 0x100000],
};

#[make_bignum_impls(3, 256, quote {Secp256k1_Fr_PARAMS})]
pub struct Secp256k1_Fr {
    limbs: [u128; 3],
}
