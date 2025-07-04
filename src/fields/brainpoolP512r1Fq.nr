use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global BrainpoolP512r1_Fq_PARAMS: BigNumParams<5, 512> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0x81ff2f2d82c68528aa6056583a48f3,
        0x9b009bc66842aecda12ae6a380e628,
        0xb3b3c9d20ed6639cca703308717d4d,
        0xdbe9c48b3fd4e6ae33c9fc07cb308d,
        0xaadd9db8,
    ],
    double_modulus: [
        0x0103fe5e5b058d0a5154c0acb07491e6,
        0x013601378cd0855d9b4255cd4701cc50,
        0x01676793a41dacc73994e06610e2fa9a,
        0x01b7d389167fa9cd5c6793f80f96611a,
        0x0155bb3b70,
    ],
    redc_param: [
        0x621c4603556d117e2cf84e911e8d90,
        0xb38823152c5e47d93034e73ea8c71d,
        0xcc44ef09666ad8f2f5bf92f542ff2,
        0x6daeb8a15d5ea2f03461e1e8373af6,
        0x17f8d7f4ed,
    ],
};

#[derive_bignum(5, 512, quote {BrainpoolP512r1_Fq_PARAMS})]
pub struct BrainpoolP512r1_Fq {
    limbs: [u128; 5],
}
