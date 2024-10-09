
use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;
pub struct U512Params {}
impl RuntimeBigNumParamsTrait<5> for U512Params {
    fn modulus_bits() -> u32 {
        513
    }
}
impl BigNumParamsTrait<5> for U512Params {
    fn get_instance() -> BigNumInstance<5, Self> {
        U512_Instance
    }
    fn modulus_bits() -> u32 {
        513
    }
}
pub global U512_Instance: BigNumInstance<5, U512Params> = BigNumInstance {
        modulus: [
            0x00, 0x00, 0x00, 0x00, 0x0100000000
        ],
        double_modulus: [
            0x01000000000000000000000000000000, 0xffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffff, 0x01ffffffff
        ],
        modulus_u60: U60Repr { limbs: [
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0100000000, 0x00]},
        modulus_u60_x4: U60Repr { limbs: [
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0100000000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
        redc_param: [
            0x00, 0x00, 0x00, 0x00, 0x4000000000
        ]
};
