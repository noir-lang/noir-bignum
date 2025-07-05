use crate::bignum::BigNum;
 use crate::bignum::derive_bignum_impl;
 use crate::params::BigNumParams;

 pub global Secp192r1_Fq_PARAMS: BigNumParams<2, 192> = BigNumParams {
     has_multiplicative_inverse: true,
     modulus: [0xfffffffffffffeffffffffffffffff, 0xffffffffffffffffff],
     double_modulus: [0x01fffffffffffffdfffffffffffffffe, 0x01fffffffffffffffffe],
     redc_param: [0x100000000000000010, 0x10000000000000000000],
 };

 #[derive_bignum_impl(2, 192, quote {Secp192r1_Fq_PARAMS})]
 pub struct Secp192r1_Fq {
     limbs: [u128; 2],
 }