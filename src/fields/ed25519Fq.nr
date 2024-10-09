
use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;
pub struct ED25519_Fq_Params {}
impl RuntimeBigNumParamsTrait<3> for ED25519_Fq_Params {
    fn modulus_bits() -> u32 {
        255
    }
}
impl BigNumParamsTrait<3> for ED25519_Fq_Params {
    fn get_instance() -> BigNumInstance<3, Self> {
        ED25519_Fq_Instance
    }
    fn modulus_bits() -> u32 {
        255
    }
}
pub global ED25519_Fq_Instance: BigNumInstance<3, ED25519_Fq_Params> = BigNumInstance {
        modulus: [
            0xffffffffffffffffffffffffffffed, 0xffffffffffffffffffffffffffffff, 0x7fff
        ],
        double_modulus: [
            0x01ffffffffffffffffffffffffffffda, 0x01fffffffffffffffffffffffffffffe, 0xfffe
        ],
        modulus_u60: U60Repr { limbs: [
            0x0fffffffffffffed, 0x0fffffffffffffff, 0x0fffffffffffffff, 0x0fffffffffffffff, 0x7fff, 0x00]},
        modulus_u60_x4: U60Repr { limbs: [
            0x0fffffffffffffed, 0x0fffffffffffffff, 0x0fffffffffffffff, 0x0fffffffffffffff, 0x7fff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
        redc_param: [
            0x0130, 0x00, 0x080000
        ]
};
