use crate::BigNum;
use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;
use crate::utils::arrayX::ArrayX;

struct BNParams {}
impl RuntimeBigNumParamsTrait<3> for BNParams {
    fn k() -> u64 {
        255
    }
    fn modulus_bits() -> u64 {
        254
    }
}

global BN254INSTANCE: BigNumInstance<3, BNParams> = BigNumInstance {
    redc_param: [
        0x000000000000000000000000000000000059785d9f353021bcebb62866fe4394, 0x0000000000000000000000000000000000d18988e8129eac1d2961a01cc04eba, 0x0000000000000000000000000000000000000000000000000000000000015291
    ],
    modulus: [
        0x0000000000000000000000000000000000816a916871ca8d3c208c16d87cfd47, 0x00000000000000000000000000000000004e72e131a029b85045b68181585d97, 0x0000000000000000000000000000000000000000000000000000000000003064
    ],
    modulus_u60: U60Repr { limbs: ArrayX { segments: [[873852357459115335, 582839116012234963, 19622440730123671], [353301755347508101, 12388, 0]] } },
    modulus_u60_x4: U60Repr { limbs: ArrayX { segments: [[873852357459115335, 582839116012234963, 19622440730123671], [353301755347508101, 12388, 0], [0, 0, 0], [0, 0, 0]] } },
    double_modulus: [
        0x000000000000000000000000000000000102d522d0e3951a7841182db0f9fa8e, 0x00000000000000000000000000000000019ce5c263405370a08b6d0302b0bb2e, 0x00000000000000000000000000000000000000000000000000000000000060c7
    ]
};
impl BigNumParamsTrait<3> for BNParams {
    fn get_instance() -> BigNumInstance<3, Self> {
        BN254INSTANCE
    }
    fn k() -> u64 {
        255
    }
    fn modulus_bits() -> u64 {
        254
    }
}
impl BNParams {
    fn k() -> u64 {
        255
    }
    fn modulus_bits() -> u64 {
        254
    }
}
