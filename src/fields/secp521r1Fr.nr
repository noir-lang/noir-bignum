use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global Secp521r1_Fr_PARAMS: BigNumParams<5, 521> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0xb5c9b8899c47aebb6fb71e91386409,
        0x8783bf2f966b7fcc0148f709a5d03b,
        0xfffffffffffffffffffffffffa5186,
        0xffffffffffffffffffffffffffffff,
        0x01ffffffffff,
    ],
    double_modulus: [
        0x016b937113388f5d76df6e3d2270c812,
        0x010f077e5f2cd6ff980291ee134ba076,
        0x01fffffffffffffffffffffffff4a30c,
        0x01fffffffffffffffffffffffffffffe,
        0x03fffffffffe,
    ],
    redc_param: [
        0xa36477663b851449048e16ec79bf70,
        0x87c40d069948033feb708f65a2fc44,
        0x5ae797,
        0x0,
        0x200000000000,
    ],
};

#[derive_bignum(5, 521, quote {Secp521r1_Fr_PARAMS})]
pub struct Secp521r1_Fr {
    limbs: [u128; 5],
}
