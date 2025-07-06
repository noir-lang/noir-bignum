use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global BrainpoolP192t1_Fr_PARAMS: BigNumParams<2, 192> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xa3462f9e9e916b5be8f1029ac4acc1, 0xc302f41d932a36cda7],
    double_modulus: [0x01468c5f3d3d22d6b7d1e20535895982, 0x018605e83b26546d9b4e],
    redc_param: [0xbc2ff68d2f9a83a6745785e71f108c, 0x1500fea39ff1728c8675],
};

#[derive_bignum(2, 192, quote { BrainpoolP192t1_Fr_PARAMS })]
pub struct BrainpoolP192t1_Fr {
    limbs: [u128; 2],
}
