use crate::BigNum;
use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;
use crate::utils::arrayX::ArrayX;

struct Secp256k1_Fq_Params {}
impl RuntimeBigNumParamsTrait<3> for Secp256k1_Fq_Params {
    fn modulus_bits() -> u64 {
        256
    }
}
impl BigNumParamsTrait<3> for Secp256k1_Fq_Params {
    fn get_instance() -> BigNumInstance<3, Self> {
        Secp256k1_Fq_Instance
    }
    fn modulus_bits() -> u64 {
        256
    }
}
global Secp256k1_Fq_Instance: BigNumInstance<3, Secp256k1_Fq_Params> = BigNumInstance {
        modulus: [
            0xfffffffffffffffffffffefffffc2f, 0xffffffffffffffffffffffffffffff, 0xffff
        ],
        double_modulus: [
            0x01fffffffffffffffffffffdfffff85e, 0x01fffffffffffffffffffffffffffffe, 0x01fffe
        ],
        modulus_u60: U60Repr { limbs: ArrayX { segments: [[
            0x0ffffffefffffc2f, 0x0fffffffffffffff, 0x0fffffffffffffff], [0x0fffffffffffffff, 0xffff, 0x00]] } },
        modulus_u60_x4: U60Repr { limbs: ArrayX { segments: [[
            0x0ffffffefffffc2f, 0x0fffffffffffffff, 0x0fffffffffffffff], [0x0fffffffffffffff, 0xffff, 0x00], [0x00, 0x00, 0x00], [0x00, 0x00, 0x00]] } },
        redc_param: [
            0x01000003d1, 0x00, 0x010000
        ]
};

