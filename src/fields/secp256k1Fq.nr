use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;
use crate::utils::u60_representation::U60Repr;

pub struct Secp256k1_Fq_Params {}

impl BigNumParamsGetter<3, 256> for Secp256k1_Fq_Params {
    fn get_params() -> BigNumParams<3, 256> {
        Secp256k1_Fq_PARAMS
    }
}

global Secp256k1_Fq_PARAMS: BigNumParams<3, 256> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xfffffffffffffffffffffefffffc2f, 0xffffffffffffffffffffffffffffff, 0xffff],
    double_modulus: [
        0x01fffffffffffffffffffffdfffff85e,
        0x01fffffffffffffffffffffffffffffe,
        0x01fffe,
    ],
    modulus_u60: U60Repr {
        limbs: [
            0x0ffffffefffffc2f,
            0x0fffffffffffffff,
            0x0fffffffffffffff,
            0x0fffffffffffffff,
            0xffff,
            0x00,
        ],
    },
    modulus_u60_x4: U60Repr {
        limbs: [
            0x0ffffffefffffc2f,
            0x0fffffffffffffff,
            0x0fffffffffffffff,
            0x0fffffffffffffff,
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
    redc_param: [0x1000003d10, 0x00, 0x100000],
};
