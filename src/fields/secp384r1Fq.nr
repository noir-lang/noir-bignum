
use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;
pub struct Secp384r1_Fq_Params {}
impl RuntimeBigNumParamsTrait<4> for Secp384r1_Fq_Params {
    fn modulus_bits() -> u32 {
        384
    }
}
impl BigNumParamsTrait<4> for Secp384r1_Fq_Params {
    fn get_instance() -> BigNumInstance<4, Self> {
        Secp384r1_Fq_Instance
    }
    fn modulus_bits() -> u32 {
        384
    }
}
pub global Secp384r1_Fq_Instance: BigNumInstance<4, Secp384r1_Fq_Params> = BigNumInstance {
        modulus: [
            0xffffff0000000000000000ffffffff, 0xfffffffffffffffffffffffffffeff, 0xffffffffffffffffffffffffffffff, 0xffffff
        ],
        double_modulus: [
            0x01fffffe0000000000000001fffffffe, 0x01fffffffffffffffffffffffffffdfe, 0x01fffffffffffffffffffffffffffffe, 0x01fffffe
        ],
        modulus_u60: U60Repr { limbs: [
            0xffffffff, 0x0ffffff000000000, 0x0ffffffffffffeff, 0x0fffffffffffffff, 0x0fffffffffffffff, 0x0fffffffffffffff, 0xffffff, 0x00]},
        modulus_u60_x4: U60Repr { limbs: [
            0xffffffff, 0x0ffffff000000000, 0x0ffffffffffffeff, 0x0fffffffffffffff, 0x0fffffffffffffff, 0x0fffffffffffffff, 0xffffff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
        redc_param: [
            0x0ffffffffffffffff000000010, 0x1000, 0x00, 0x10000000
        ]
};
