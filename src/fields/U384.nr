use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;
use crate::utils::u60_representation::U60Repr;

pub struct U384_Params {}

impl BigNumParamsGetter<4, 385> for U384_Params {
    fn get_params() -> BigNumParams<4, 385> {
        U384_PARAMS
    }
}

global U384_PARAMS: BigNumParams<4, 385> = BigNumParams {
    has_multiplicative_inverse: false,
    modulus: [0x00, 0x00, 0x00, 0x01000000],
    double_modulus: [
        0x01000000000000000000000000000000,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0x01ffffff,
    ],
    modulus_u60: U60Repr { limbs: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01000000, 0x00] },
    modulus_u60_x4: U60Repr {
        limbs: [
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01000000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
        ],
    },
    redc_param: [0x00, 0x00, 0x00, 0x40000000],
};
