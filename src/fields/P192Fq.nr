use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global P192_PARAMS: BigNumParams<2, 192> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xfffffffffffffeffffffffffffffff, 0xffffffffffffffffff],
    double_modulus: [0x01fffffffffffffdfffffffffffffffe, 0x01fffffffffffffffffe],
    redc_param: [0x100000000000000010, 0x10000000000000000000],
};

#[derive_bignum(2, 192, quote {P192_PARAMS})]
pub struct P192 {
    limbs: [u128; 2],
}
