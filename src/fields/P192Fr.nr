use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global P192Fr_PARAMS: BigNumParams<2, 192> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xffffff99def836146bc9b1b4d22831, 0xffffffffffffffffff],
    double_modulus: [0x01ffffff33bdf06c28d7936369a45062, 0x01fffffffffffffffffe],
    redc_param: [0x0662107c9eb94364e4b2dd7cf2, 0x10000000000000000000],
};

#[derive_bignum(2, 192, quote { P192Fr_PARAMS })]
pub struct P192Fr {
    limbs: [u128; 2],
}
