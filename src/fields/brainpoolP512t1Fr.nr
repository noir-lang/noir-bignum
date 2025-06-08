use crate::bignum::BigNum;
use crate::bignum::derive_bignum_impl;
use crate::params::BigNumParams;

pub global BrainpoolP512t1_Fr_PARAMS: BigNumParams<5, 512> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0xb1d381085ddaddb58796829ca90069,
        0x5c414ca92619418661197fac10471d,
        0xb3b3c9d20ed6639cca70330870553e,
        0xdbe9c48b3fd4e6ae33c9fc07cb308d,
        0xaadd9db8,
    ],
    double_modulus: [
        0x0163a70210bbb5bb6b0f2d05395200d2,
        0x01b88299524c32830cc232ff58208e3a,
        0x01676793a41dacc73994e06610e0aa7b,
        0x01b7d389167fa9cd5c6793f80f96611a,
        0x0155bb3b70,
    ],
    redc_param: [
        0xf0d9015d5c4ce2fafac64db57db370,
        0xc61a235d449ff38f5f59ee47100ea,
        0xcc44ef09666ad8f2f5bf92f7db947,
        0x6daeb8a15d5ea2f03461e1e8373af6,
        0x17f8d7f4ed,
    ],
};

#[derive_bignum_impl(5, 512, quote {BrainpoolP512t1_Fr_PARAMS})]
pub struct BrainpoolP512t1_Fr {
    limbs: [u128; 5],
}
