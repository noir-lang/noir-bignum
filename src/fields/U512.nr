use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global U512_PARAMS: BigNumParams<5, 513> = BigNumParams {
    has_multiplicative_inverse: false,
    modulus: [0x00, 0x00, 0x00, 0x00, 0x0100000000],
    double_modulus: [
        0x01000000000000000000000000000000,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0x01ffffffff,
    ],
    redc_param: [0x00, 0x00, 0x00, 0x00, 0x4000000000],
};

#[derive_bignum(5, 513, quote {U512_PARAMS})]
pub struct U512 {
    limbs: [u128; 5],
}
