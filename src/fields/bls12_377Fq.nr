//! Blurb sourced from https://github.com/arkworks-rs
//! This library implements the base field of the BLS12_377 curve generated in [[BCGMMW20, "Zexe"]]((https://eprint.iacr.org/2018/962).
//! The name denotes that it is a Barreto--Lynn--Scott curve of embedding degree
//! 12, defined over a 377-bit (prime) field. The main feature of this curve is
//! that both the scalar field and the base field are highly 2-adic.
//! (This is in contrast to the BLS12_381 curve for which only the scalar field
//! is highly 2-adic.)
//!
//!
//! Curve information:
//! * Base field: q = 258664426012969094010652733694893533536393512754914660539884262666720468348340822774968888139573360124440321458177
//! * Scalar field: r =
//!   8444461749428370424248824938781546531375899335154063827935233455917409239041
//! * valuation(q - 1, 2) = 46
//! * valuation(r - 1, 2) = 47
//! * G1 curve equation: y^2 = x^3 + 1
//! * G2 curve equation: y^2 = x^3 + B, where
//!    * B = Fq2(0, 155198655607781456406391640216936120121836107652948796323930557600032281009004493664981332883744016074664192874906)
use crate::BigNumParamsTrait;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::utils::u60_representation::U60Repr;
pub struct BLS12_377_Fq_Params {}
impl RuntimeBigNumParamsTrait<4> for BLS12_377_Fq_Params {
    fn modulus_bits() -> u32 {
        377
    }
}
impl BigNumParamsTrait<4> for BLS12_377_Fq_Params {
    fn get_instance() -> BigNumInstance<4, Self> {
        BLS12_377_Fq_Instance
    }
    fn modulus_bits() -> u32 {
        377
    }
}
pub global BLS12_377_Fq_Instance: BigNumInstance<4, BLS12_377_Fq_Params> = BigNumInstance {
        modulus: [
            0x0b5d44300000008508c00000000001, 0xd9f300f5138f1ef3622fba09480017, 0x4617c510eac63b05c06ca1493b1a22, 0x01ae3a
        ],
        double_modulus: [
            0x0116ba88600000010a11800000000002, 0x01b3e601ea271e3de6c45f741290002d, 0x018c2f8a21d58c760b80d94292763444, 0x035c73
        ],
        modulus_u60: U60Repr { limbs: [
            0x0508c00000000001, 0xb5d44300000008, 0x03622fba09480017, 0x0d9f300f5138f1ef, 0x05c06ca1493b1a22, 0x04617c510eac63b0, 0x01ae3a, 0x00]},
        modulus_u60_x4: U60Repr { limbs: [
            0x0508c00000000001, 0xb5d44300000008, 0x03622fba09480017, 0x0d9f300f5138f1ef, 0x05c06ca1493b1a22, 0x04617c510eac63b0, 0x01ae3a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
        redc_param: [
            0xd687789c42a591f9fd58c5e4daffcc, 0x0de6776b1a06af2d488d85a6d02d0e, 0xd0cc4060e976c3ca0582ef4f73bbad, 0x261508
        ]
};
