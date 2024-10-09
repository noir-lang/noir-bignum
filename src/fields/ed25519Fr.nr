
use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;
pub struct ED25519_Fr_Params {}
impl RuntimeBigNumParamsTrait<3> for ED25519_Fr_Params {
    fn modulus_bits() -> u32 {
        253
    }
}
impl BigNumParamsTrait<3> for ED25519_Fr_Params {
    fn get_instance() -> BigNumInstance<3, Self> {
        ED25519_Fr_Instance
    }
    fn modulus_bits() -> u32 {
        253
    }
}
pub global ED25519_Fr_Instance: BigNumInstance<3, ED25519_Fr_Params> = BigNumInstance {
        modulus: [
            0xdef9dea2f79cd65812631a5cf5d3ed, 0x14, 0x1000
        ],
        double_modulus: [
            0x01bdf3bd45ef39acb024c634b9eba7da, 0x01000000000000000000000000000028, 0x1fff
        ],
        modulus_u60: U60Repr { limbs: [
            0x0812631a5cf5d3ed, 0x0def9dea2f79cd65, 0x14, 0x00, 0x1000, 0x00]},
        modulus_u60_x4: U60Repr { limbs: [
            0x0812631a5cf5d3ed, 0x0def9dea2f79cd65, 0x14, 0x00, 0x1000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
        redc_param: [
            0x4188574218ca69fb673968c28b04c6, 0xfffffffffffffffffffffffffffac8, 0x03ffff
        ]
};
