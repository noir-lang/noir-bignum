use crate::bignum::BigNum;
use crate::bignum::derive_bignum_impl;
use crate::params::BigNumParams;

pub global BrainpoolP256t1_Fr_PARAMS: BigNumParams<3, 256> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0x397aa3b561a6f7901e0e82974856a7, 0x57dba1eea9bc3e660a909d838d718c, 0xa9fb],
    double_modulus: [
        0x0172f5476ac34def203c1d052e90ad4e,
        0x01afb743dd53787ccc15213b071ae317,
        0x0153f5,
    ],
    redc_param: [0x88c5fdf55ea50d73b46ccd107160, 0x131a1c55b7ebb73aba8322a7bf49bf, 0x1818c1],
};

#[derive_bignum_impl(3, 256, quote {BrainpoolP256t1_Fr_PARAMS})]
pub struct BrainpoolP256t1_Fr {
    limbs: [u128; 3],
}
