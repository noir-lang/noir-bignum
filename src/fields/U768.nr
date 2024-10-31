use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;
use crate::utils::u60_representation::U60Repr;

pub struct U768Params {}

impl BigNumParamsGetter<7, 769> for U768Params {
    fn get_params() -> BigNumParams<7, 769> {
        U768_PARAMS
    }
}

global U768_PARAMS: BigNumParams<7, 769> = BigNumParams {
    has_multiplicative_inverse: false,
    modulus: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01000000000000],
    double_modulus: [
        0x01000000000000000000000000000000,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0x01ffffffffffff,
    ],
    modulus_u60: U60Repr {
        limbs: [
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x01000000000000,
            0x00,
        ],
    },
    modulus_u60_x4: U60Repr {
        limbs: [
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x01000000000000,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
        ],
    },
    redc_param: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40000000000000],
};
