use crate::bignum::BigNum;
use crate::bignum::derive_bignum_impl;
use crate::params::BigNumParams;

pub global BrainpoolP256t1_Fq_PARAMS: BigNumParams<3, 256> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0x3bf623d52620282013481d1f6e5377, 0x57dba1eea9bc3e660a909d838d726e, 0xa9fb],
    double_modulus: [
        0x0177ec47aa4c40504026903a3edca6ee,
        0x01afb743dd53787ccc15213b071ae4db,
        0x0153f5,
    ],
    redc_param: [0xf54a0ff6a2fa9b62ae6301180dd0c0, 0x131a1c55b7ebb73aba8322a7bf29b4, 0x1818c1],
};

#[derive_bignum_impl(3, 256, quote {BrainpoolP256t1_Fq_PARAMS})]
pub struct BrainpoolP256t1_Fq {
    limbs: [u128; 3],
}
