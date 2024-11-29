use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;
use crate::utils::u60_representation::U60Repr;

pub struct Secp256r1_Fq_Params {}

impl BigNumParamsGetter<3, 256> for Secp256r1_Fq_Params {
    fn get_params() -> BigNumParams<3, 256> {
        Secp256r1_Fq_PARAMS
    }
}

global Secp256r1_Fq_PARAMS: BigNumParams<3, 256> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xffffffffffffffffffffffff, 0xffff00000001000000000000000000, 0xffff],
    double_modulus: [
        0x01000001fffffffffffffffffffffffe,
        0x01fffe00000001ffffffffffffffffff,
        0x01fffe,
    ],
    modulus_u60: U60Repr {
        limbs: [0x0fffffffffffffff, 0x0fffffffff, 0x00, 0x0ffff00000001000, 0xffff, 0x00],
    },
    modulus_u60_x4: U60Repr {
        limbs: [
            0x0fffffffffffffff,
            0x0fffffffff,
            0x00,
            0x0ffff00000001000,
            0xffff,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
        ],
    },
    redc_param: [0xffffeffffffff00000000000000030, 0x0fffffffffffffffefffffffefff, 0x100000],
};
