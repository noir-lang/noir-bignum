use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;
use crate::utils::u60_representation::U60Repr;

pub struct Secp256k1_Fr_Params {}

impl BigNumParamsGetter<3, 256> for Secp256k1_Fr_Params {
    fn get_params() -> BigNumParams<3, 256> {
        Secp256k1_Fr_PARAMS
    }
}

global Secp256k1_Fr_PARAMS: BigNumParams<3, 256> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xaedce6af48a03bbfd25e8cd0364141, 0xfffffffffffffffffffffffffffeba, 0xffff],
    double_modulus: [
        0x015db9cd5e9140777fa4bd19a06c8282,
        0x01fffffffffffffffffffffffffffd74,
        0x01fffe,
    ],
    modulus_u60: U60Repr {
        limbs: [
            0x0fd25e8cd0364141,
            0x0aedce6af48a03bb,
            0x0ffffffffffffeba,
            0x0fffffffffffffff,
            0xffff,
            0x00,
        ],
    },
    modulus_u60_x4: U60Repr {
        limbs: [
            0x0fd25e8cd0364141,
            0x0aedce6af48a03bb,
            0x0ffffffffffffeba,
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
    redc_param: [0x1231950b75fc4402da1732fc9bec09, 0x1455, 0x100000],
};
