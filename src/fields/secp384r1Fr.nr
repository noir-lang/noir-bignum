
use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;
pub struct Secp384r1_Fr_Params {}
impl RuntimeBigNumParamsTrait<4> for Secp384r1_Fr_Params {
    fn modulus_bits() -> u32 {
        384
    }
}
impl BigNumParamsTrait<4> for Secp384r1_Fr_Params {
    fn get_instance() -> BigNumInstance<4, Self> {
        Secp384r1_Fr_Instance
    }
    fn modulus_bits() -> u32 {
        384
    }
}
pub global Secp384r1_Fr_Instance: BigNumInstance<4, Secp384r1_Fr_Params> = BigNumInstance {
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
            0x5f24db74f58851313e695333ad68d0, 0x0389cb27e0bc8d220a7e, 0x00, 0x10000000
        ]
};
