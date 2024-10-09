use crate::params::BigNumParamsGetter;
use crate::params::BigNumParams;
use crate::utils::u60_representation::U60Repr;

global Secp384r1_Fr_PARAMS: BigNumParams<4> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus_bits_getter: || 384,
    modulus: [
        0x1a0db248b0a77aecec196accc52973, 0xffffffffffffc7634d81f4372ddf58, 0xffffffffffffffffffffffffffffff, 0xffffff
    ],
    double_modulus: [
        0x01341b6491614ef5d9d832d5998a52e6, 0x01ffffffffffff8ec69b03e86e5bbeaf, 0x01fffffffffffffffffffffffffffffe, 0x01fffffe
    ],
    modulus_u60: U60Repr { limbs: [
        0x0cec196accc52973, 0x01a0db248b0a77ae, 0x034d81f4372ddf58, 0x0ffffffffffffc76, 0x0fffffffffffffff, 0x0fffffffffffffff, 0xffffff, 0x00]},
    modulus_u60_x4: U60Repr { limbs: [
        0x0cec196accc52973, 0x01a0db248b0a77ae, 0x034d81f4372ddf58, 0x0ffffffffffffc76, 0x0fffffffffffffff, 0x0fffffffffffffff, 0xffffff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
    redc_param: [
        0xe5f24db74f58851313e695333ad68d, 0x389cb27e0bc8d220a7, 0x00, 0x01000000
    ]
};

pub struct  Secp384r1_Fr_Params {}

impl BigNumParamsGetter<4> for Secp384r1_Fr_Params {
    fn get_params() -> BigNumParams<4> {
        Secp384r1_Fr_PARAMS
    }
}

