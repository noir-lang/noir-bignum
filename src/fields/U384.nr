
use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;
pub struct U384Params {}
impl RuntimeBigNumParamsTrait<4> for U384Params {
    fn modulus_bits() -> u32 {
        385
    }
}
impl BigNumParamsTrait<4> for U384Params {
    fn get_instance() -> BigNumInstance<4, Self> {
        U384_Instance
    }
    fn modulus_bits() -> u32 {
        385
    }
}
pub global U384_Instance: BigNumInstance<4, U384Params> = BigNumInstance {
        modulus: [
            0x00, 0x00, 0x00, 0x01000000
        ],
        double_modulus: [
            0x01000000000000000000000000000000, 0xffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffff, 0x01ffffff
        ],
        modulus_u60: U60Repr { limbs: [
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01000000, 0x00]},
        modulus_u60_x4: U60Repr { limbs: [
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01000000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
        redc_param: [
            0x00, 0x00, 0x00, 0x40000000
        ]
};
