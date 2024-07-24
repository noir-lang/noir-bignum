use crate::BigNum;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::BigNumParamsTrait as BigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;

struct Bls12_381_Fr_Params {}

impl RuntimeBigNumParamsTrait<3> for Bls12_381_Fr_Params {
    fn k() -> u64 {
        255
    }
    fn modulus_bits() -> u64 {
        255
    }
}

impl BigNumParamsTrait<3> for Bls12_381_Fr_Params {
    fn get_instance() -> BigNumInstance<3, Self> {
        let modulus = [0xbda402fffe5bfeffffffff00000001, 0xa753299d7d483339d80809a1d80553, 0x0073ed];
        let redc_param = [0x410fad2f92eb5c509cde80830358e4, 0x253b7fb78ddf0e2d772dc1f823b4d9, 0x008d54];
        BigNumInstance::new(modulus, redc_param)
    }
    fn k() -> u64 {
        255
    }
    fn modulus_bits() -> u64 {
        255
    }
}
