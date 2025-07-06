use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global Secp224r1_Fq_PARAMS: BigNumParams<2, 224> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xffffff000000000000000000000001, 0xffffffffffffffffffffffffff],
    double_modulus: [0x01fffffe000000000000000000000002, 0x01fffffffffffffffffffffffffe],
    redc_param: [0x0ffffffffffffffffffffffff0, 0x1000000000000000000000000000],
};

#[derive_bignum(2, 224, quote { Secp224r1_Fq_PARAMS })]
pub struct Secp224r1_Fq {
    limbs: [u128; 2],
}
