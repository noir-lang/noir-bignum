use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;
use crate::utils::u60_representation::U60Repr;

pub struct U256Params {}

impl BigNumParamsGetter<3, 257> for U256Params {
    fn get_params() -> BigNumParams<3, 257> {
        U256_PARAMS
    }
}

global U256_PARAMS: BigNumParams<3, 257> = BigNumParams {
    has_multiplicative_inverse: false,
    modulus: [0x00, 0x00, 0x010000],
    double_modulus: [
        0x01000000000000000000000000000000,
        0xffffffffffffffffffffffffffffff,
        0x01ffff,
    ],
    modulus_u60: U60Repr { limbs: [0x00, 0x00, 0x00, 0x00, 0x010000, 0x00] },
    modulus_u60_x4: U60Repr {
        limbs: [0x00, 0x00, 0x00, 0x00, 0x010000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
    },
    redc_param: [0x00, 0x00, 0x400000],
};
