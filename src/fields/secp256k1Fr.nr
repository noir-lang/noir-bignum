
use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;
pub struct Secp256k1_Fr_Params {}
impl RuntimeBigNumParamsTrait<3> for Secp256k1_Fr_Params {
    fn modulus_bits() -> u32 {
        256
    }
}
impl BigNumParamsTrait<3> for Secp256k1_Fr_Params {
    fn get_instance() -> BigNumInstance<3, Self> {
        Secp256k1_Fr_Instance
    }
    fn modulus_bits() -> u32 {
        256
    }
}
pub global Secp256k1_Fr_Instance: BigNumInstance<3, Secp256k1_Fr_Params> = BigNumInstance {
        modulus: [
            0xaedce6af48a03bbfd25e8cd0364141, 0xfffffffffffffffffffffffffffeba, 0xffff
        ],
        double_modulus: [
            0x015db9cd5e9140777fa4bd19a06c8282, 0x01fffffffffffffffffffffffffffd74, 0x01fffe
        ],
        modulus_u60: U60Repr { limbs: [
            0x0fd25e8cd0364141, 0x0aedce6af48a03bb, 0x0ffffffffffffeba, 0x0fffffffffffffff, 0xffff, 0x00]},
        modulus_u60_x4: U60Repr { limbs: [
            0x0fd25e8cd0364141, 0x0aedce6af48a03bb, 0x0ffffffffffffeba, 0x0fffffffffffffff, 0xffff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
        redc_param: [
            0x1231950b75fc4402da1732fc9bec09, 0x1455, 0x100000
        ]
};
