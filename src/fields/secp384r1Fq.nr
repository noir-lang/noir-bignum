use crate::params::BigNumParamsGetter;
use crate::params::BigNumParams;
use crate::utils::u60_representation::U60Repr;

global Secp384r1_Fq_PARAMS: BigNumParams<4> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus_bits_getter: || 384,
    modulus: [
        0xffffff0000000000000000ffffffff, 0xfffffffffffffffffffffffffffeff, 0xffffffffffffffffffffffffffffff, 0xffffff
    ],
    double_modulus: [
        0x01fffffe0000000000000001fffffffe, 0x01fffffffffffffffffffffffffffdfe, 0x01fffffffffffffffffffffffffffffe, 0x01fffffe
    ],
    modulus_u60: U60Repr { limbs: [
        0xffffffff, 0x0ffffff000000000, 0x0ffffffffffffeff, 0x0fffffffffffffff, 0x0fffffffffffffff, 0x0fffffffffffffff, 0xffffff, 0x00]},
    modulus_u60_x4: U60Repr { limbs: [
        0xffffffff, 0x0ffffff000000000, 0x0ffffffffffffeff, 0x0fffffffffffffff, 0x0fffffffffffffff, 0x0fffffffffffffff, 0xffffff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
    redc_param: [
        0xffffffffffffffff00000001, 0x0100, 0x00, 0x01000000
    ]
};

pub struct  Secp384r1_Fq_Params {}

impl BigNumParamsGetter<4> for Secp384r1_Fq_Params {
    fn get_params() -> BigNumParams<4> {
        Secp384r1_Fq_PARAMS
    }
}

