use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global BrainpoolP384t1_Fr_PARAMS: BigNumParams<4, 384> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0x3ab6af6b7fc3103b883202e9046565,
        0x7109ed5456b31f166e6cac0425a7cf,
        0x82a3386d280f5d6f7e50e641df152f,
        0x8cb91e,
    ],
    double_modulus: [
        0x01756d5ed6ff862077106405d208caca,
        0x01e213daa8ad663e2cdcd958084b4f9d,
        0x01054670da501ebadefca1cc83be2a5d,
        0x0119723c,
    ],
    redc_param: [
        0xfdb467a652109600adcccf8a71f8a0,
        0x449cae56ee1c506f2fe165031e7189,
        0x16d8ec6b8ff25adfd3cc6fa65dda2c,
        0x1d1b575b,
    ],
};

#[derive_bignum(4, 384, quote {BrainpoolP384t1_Fr_PARAMS})]
pub struct BrainpoolP384t1_Fr {
    limbs: [u128; 4],
}
