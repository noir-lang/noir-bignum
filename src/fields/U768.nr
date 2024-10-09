
use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;
pub struct U768Params {}
impl RuntimeBigNumParamsTrait<7> for U768Params {
    fn modulus_bits() -> u32 {
        769
    }
}
impl BigNumParamsTrait<7> for U768Params {
    fn get_instance() -> BigNumInstance<7, Self> {
        U768_Instance
    }
    fn modulus_bits() -> u32 {
        769
    }
}
pub global U768_Instance: BigNumInstance<7, U768Params> = BigNumInstance {
        modulus: [
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01000000000000
        ],
        double_modulus: [
            0x01000000000000000000000000000000, 0xffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffff, 0x01ffffffffffff
        ],
        modulus_u60: U60Repr { limbs: [
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01000000000000, 0x00]},
        modulus_u60_x4: U60Repr { limbs: [
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01000000000000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
        redc_param: [
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40000000000000
        ]
};
