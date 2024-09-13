use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;
use crate::utils::arrayX::ArrayX;

struct U256Params {}
impl RuntimeBigNumParamsTrait<3> for U256Params {
    fn modulus_bits() -> u32 {
        257
    }
    fn has_multiplicative_inverse() -> bool {
        false
    }
}
impl BigNumParamsTrait<3> for U256Params {
    fn get_instance() -> BigNumInstance<3, Self> {
        U256_Instance
    }
    fn modulus_bits() -> u32 {
        257
    }
    fn has_multiplicative_inverse() -> bool {
        false
    }
}
global U256_Instance: BigNumInstance<3, U256Params> = BigNumInstance {
        modulus: [
            0x00, 0x00, 0x010000
        ],
        double_modulus: [
            0x01000000000000000000000000000000, 0xffffffffffffffffffffffffffffff, 0x01ffff
        ],
        modulus_u60: U60Repr { limbs: ArrayX { segments: [[
            0x00, 0x00, 0x00], [0x00, 0x010000, 0x00]] } },
        modulus_u60_x4: U60Repr { limbs: ArrayX { segments: [[
            0x00, 0x00, 0x00], [0x00, 0x010000, 0x00], [0x00, 0x00, 0x00], [0x00, 0x00, 0x00]] } },
        redc_param: [
            0x00, 0x00, 0x040000
        ]
};
