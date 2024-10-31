use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;
use crate::utils::u60_representation::U60Repr;

pub struct ED25519_Fq_Params {}

impl BigNumParamsGetter<3, 255> for ED25519_Fq_Params {
    fn get_params() -> BigNumParams<3, 255> {
        ED25519_Fq_PARAMS
    }
}

global ED25519_Fq_PARAMS: BigNumParams<3, 255> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [0xffffffffffffffffffffffffffffed, 0xffffffffffffffffffffffffffffff, 0x7fff],
    double_modulus: [
        0x01ffffffffffffffffffffffffffffda,
        0x01fffffffffffffffffffffffffffffe,
        0xfffe,
    ],
    modulus_u60: U60Repr {
        limbs: [
            0x0fffffffffffffed,
            0x0fffffffffffffff,
            0x0fffffffffffffff,
            0x0fffffffffffffff,
            0x7fff,
            0x00,
        ],
    },
    modulus_u60_x4: U60Repr {
        limbs: [
            0x0fffffffffffffed,
            0x0fffffffffffffff,
            0x0fffffffffffffff,
            0x0fffffffffffffff,
            0x7fff,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
        ],
    },
    redc_param: [0x0130, 0x00, 0x080000],
};
