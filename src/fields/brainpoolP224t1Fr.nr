use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global BrainpoolP224t1_Fr_PARAMS: BigNumParams<2, 224> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xd0fb98d116bc4b6ddebca3a5a7939f, 0xd7c134aa264366862a18302575],
    double_modulus: [0x01a1f731a22d7896dbbd79474b4f273e, 0x01af8269544c86cd0c5430604aea],
    redc_param: [0xf1e9fbee15bc3590a94d31c8a5ba15, 0x12fc099f78fd222994e1d543f603],
};

#[derive_bignum(2, 224, quote { BrainpoolP224t1_Fr_PARAMS })]
pub struct BrainpoolP224t1_Fr {
    limbs: [u128; 2],
}
