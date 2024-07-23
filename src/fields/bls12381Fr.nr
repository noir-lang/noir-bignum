use crate::BigNum;
use crate::BigNumParamsTrait;

struct Bls12_381_Fr_Params {}

impl BigNumParamsTrait<3> for Bls12_381_Fr_Params {
    fn k() -> u64 {
        255
    }
    fn modulus_bits() -> u64 {
        255
    }
}
