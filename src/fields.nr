mod bn254Fq;
mod bls12381Fr;

use crate::BigNum;
use crate::runtime_bignum::BigNumInstance;
use crate::fields::bn254Fq::BNParams;
use crate::fields::bls12381Fr::Bls12_381_Fr_Params;

// example typedef when using a defined bignum instance
type Fq = BigNum<3, BNParams>;

pub fn BN254Instance() -> BigNumInstance<3, BNParams> {
    let modulus = [
        0x0000000000000000000000000000000000816a916871ca8d3c208c16d87cfd47, 0x00000000000000000000000000000000004e72e131a029b85045b68181585d97, 0x0000000000000000000000000000000000000000000000000000000000003064
    ];
    let redc_param = [
        0x000000000000000000000000000000000059785d9f353021bcebb62866fe4394, 0x0000000000000000000000000000000000d18988e8129eac1d2961a01cc04eba, 0x0000000000000000000000000000000000000000000000000000000000015291
    ];

    BigNumInstance::new(modulus, redc_param)
}

pub fn BLS12381Instance() -> BigNumInstance<3, Bls12_381_Fr_Params> {
    let modulus = [0xbda402fffe5bfeffffffff00000001, 0xa753299d7d483339d80809a1d80553, 0x0073ed];
    let redc_param = [0x410fad2f92eb5c509cde80830358e4, 0x253b7fb78ddf0e2d772dc1f823b4d9, 0x008d54];

    BigNumInstance::new(modulus, redc_param)
}
