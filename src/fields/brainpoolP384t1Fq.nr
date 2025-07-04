use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global BrainpoolP384t1_Fq_PARAMS: BigNumParams<4, 384> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0xd3a729901d1a71874700133107ec53,
        0x7109ed5456b412b1da197fb71123ac,
        0x82a3386d280f5d6f7e50e641df152f,
        0x8cb91e,
    ],
    double_modulus: [
        0x01a74e53203a34e30e8e0026620fd8a6,
        0x01e213daa8ad682563b432ff6e224758,
        0x01054670da501ebadefca1cc83be2a5d,
        0x0119723c,
    ],
    redc_param: [
        0x7bce07a71566f10a03bf684a267160,
        0x449cae56ede9ed590cef1c4d721904,
        0x16d8ec6b8ff25adfd3cc6fa65dda2c,
        0x1d1b575b,
    ],
};

#[derive_bignum(4, 384, quote {BrainpoolP384t1_Fq_PARAMS})]
pub struct BrainpoolP384t1_Fq {
    limbs: [u128; 4],
}
