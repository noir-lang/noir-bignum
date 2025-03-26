use crate::bignum::BigNumTrait;
use crate::bignum::make_bignum_impls;
use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;

pub struct Secp256k1_Fq_Params {}

impl BigNumParamsGetter<3, 256> for Secp256k1_Fq_Params {
    fn get_params() -> BigNumParams<3, 256> {
        Secp256k1_Fq_PARAMS
    }
}

pub global Secp256k1_Fq_PARAMS: BigNumParams<3, 256> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xfffffffffffffffffffffefffffc2f, 0xffffffffffffffffffffffffffffff, 0xffff],
    double_modulus: [
        0x01fffffffffffffffffffffdfffff85e,
        0x01fffffffffffffffffffffffffffffe,
        0x01fffe,
    ],
    redc_param: [0x1000003d10, 0x00, 0x100000],
};

#[make_bignum_impls(3, 256, quote {Secp256k1_Fq_PARAMS})]
pub struct Secp256k1_Fq {
    limbs: [u128; 3],
}
