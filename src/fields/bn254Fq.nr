use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;

struct  BNParams {}
impl RuntimeBigNumParamsTrait<3> for BNParams {
    fn modulus_bits() -> u32 {
        254
    }
}

global BN254INSTANCE: BigNumInstance<3, BNParams> = BigNumInstance {
        modulus: [
            0x816a916871ca8d3c208c16d87cfd47, 0x4e72e131a029b85045b68181585d97, 0x3064
        ],
        double_modulus: [
            0x0102d522d0e3951a7841182db0f9fa8e, 0x019ce5c263405370a08b6d0302b0bb2e, 0x60c7
        ],
        modulus_u60: U60Repr { limbs: [
            0x0c208c16d87cfd47, 0x0816a916871ca8d3, 0x45b68181585d97, 0x04e72e131a029b85, 0x3064, 0x00]},
        modulus_u60_x4: U60Repr { limbs: [
            0x0c208c16d87cfd47, 0x0816a916871ca8d3, 0x45b68181585d97, 0x04e72e131a029b85, 0x3064, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
        redc_param: [
            0x965e1767cd4c086f3aed8a19bf90e5, 0x7462623a04a7ab074a5868073013ae, 0x54a4
        ]
};

impl BigNumParamsTrait<3> for BNParams {
    fn get_instance() -> BigNumInstance<3, Self> {
        BN254INSTANCE
    }
    fn modulus_bits() -> u32 {
        254
    }
}
