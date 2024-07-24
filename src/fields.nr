mod bn254Fq;
mod bls12381Fr;

use crate::BigNum;
use crate::runtime_bignum::BigNumInstance;
use crate::fields::bn254Fq::BNParams;
use crate::fields::bls12381Fr::Bls12_381_Fr_Params;

// example typedef when using a defined bignum instance
type Fq = BigNum<3, BNParams>;


pub fn BLS12381Instance() -> BigNumInstance<3, Bls12_381_Fr_Params> {
    let modulus = [0xbda402fffe5bfeffffffff00000001, 0xa753299d7d483339d80809a1d80553, 0x0073ed];
    let redc_param = [0x410fad2f92eb5c509cde80830358e4, 0x253b7fb78ddf0e2d772dc1f823b4d9, 0x008d54];

    BigNumInstance::new(modulus, redc_param)
}
