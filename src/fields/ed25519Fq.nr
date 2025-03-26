use crate::bignum::BigNumTrait;
use crate::bignum::make_bignum_impls;
use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;
pub struct ED25519_Fq_Params {}

impl BigNumParamsGetter<3, 255> for ED25519_Fq_Params {
    fn get_params() -> BigNumParams<3, 255> {
        ED25519_Fq_PARAMS
    }
}

pub global ED25519_Fq_PARAMS: BigNumParams<3, 255> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xffffffffffffffffffffffffffffed, 0xffffffffffffffffffffffffffffff, 0x7fff],
    double_modulus: [
        0x01ffffffffffffffffffffffffffffda,
        0x01fffffffffffffffffffffffffffffe,
        0xfffe,
    ],
    redc_param: [0x0130, 0x00, 0x080000],
};

#[make_bignum_impls(3, 255, quote {ED25519_Fq_PARAMS})]
pub struct ED25519_Fq {
    limbs: [u128; 3],
}
