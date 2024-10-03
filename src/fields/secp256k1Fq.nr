use crate::params::BigNumParamsTrait;
use crate::params::BigNumParams;
use crate::utils::u60_representation::U60Repr;

global Secp256k1_Fq_PARAMS: BigNumParams<3> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus_bits_getter: || 256,
    modulus: [
        0xfffffffffffffffffffffefffffc2f, 0xffffffffffffffffffffffffffffff, 0xffff
    ],
    double_modulus: [
        0x01fffffffffffffffffffffdfffff85e, 0x01fffffffffffffffffffffffffffffe, 0x01fffe
    ],
    modulus_u60: U60Repr { limbs: [
        0x0ffffffefffffc2f, 0x0fffffffffffffff, 0x0fffffffffffffff, 0x0fffffffffffffff, 0xffff, 0x00]},
    modulus_u60_x4: U60Repr { limbs: [
        0x0ffffffefffffc2f, 0x0fffffffffffffff, 0x0fffffffffffffff, 0x0fffffffffffffff, 0xffff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
    redc_param: [
        0x01000003d1, 0x00, 0x010000
    ]
};

struct  Secp256k1_Fq_Params {}

impl BigNumParamsTrait<3> for Secp256k1_Fq_Params {
    fn get_params() -> BigNumParams<3> {
        Secp256k1_Fq_PARAMS
    }
}

