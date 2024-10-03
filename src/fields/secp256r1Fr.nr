use crate::params::BigNumParamsTrait;
use crate::params::BigNumParams;
use crate::utils::u60_representation::U60Repr;

global Secp256r1_Fr_PARAMS: BigNumParams<3> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus_bits_getter: || 256,
    modulus: [
        0xe6faada7179e84f3b9cac2fc632551, 0xffff00000000ffffffffffffffffbc, 0xffff
    ],
    double_modulus: [
        0x01cdf55b4e2f3d09e7739585f8c64aa2, 0x01fffe00000001ffffffffffffffff78, 0x01fffe
    ],
    modulus_u60: U60Repr { limbs: [
        0x03b9cac2fc632551, 0x0e6faada7179e84f, 0x0fffffffffffffbc, 0x0ffff00000000fff, 0xffff, 0x00]},
    modulus_u60_x4: U60Repr { limbs: [
        0x03b9cac2fc632551, 0x0e6faada7179e84f, 0x0fffffffffffffbc, 0x0ffff00000000fff, 0xffff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
    redc_param: [
        0x190552df1a6c21012ffd85eedf9bfe, 0xfffffffffffffffeffffffff43, 0x010000
    ]
};

struct  Secp256r1_Fr_Params {}

impl BigNumParamsTrait<3> for Secp256r1_Fr_Params {
    fn get_params() -> BigNumParams<3> {
        Secp256r1_Fr_PARAMS
    }
}

