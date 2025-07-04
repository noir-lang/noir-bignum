use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global Secp521r1_Fq_PARAMS: BigNumParams<5, 521> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0x01ffffffffff,
    ],
    double_modulus: [
        0x01fffffffffffffffffffffffffffffe,
        0x01fffffffffffffffffffffffffffffe,
        0x01fffffffffffffffffffffffffffffe,
        0x01fffffffffffffffffffffffffffffe,
        0x03fffffffffe,
    ],
    redc_param: [0x10, 0x0, 0x0, 0x0, 0x200000000000],
};

#[derive_bignum(5, 521, quote {Secp521r1_Fq_PARAMS})]
pub struct Secp521r1_Fq {
    limbs: [u128; 5],
}
