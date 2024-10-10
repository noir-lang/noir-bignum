//! Blurb sourced from https://github.com/arkworks-rs
//! This library implements the scalar field of the BLS12_377 curve generated in [BCGMMW20, "Zexe"](https://eprint.iacr.org/2018/962).
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
pub struct BLS12_377_Fr_Params {}
impl RuntimeBigNumParamsTrait<3> for BLS12_377_Fr_Params {
    fn modulus_bits() -> u32 {
        253
    }
}
impl BigNumParamsTrait<3> for BLS12_377_Fr_Params {
    fn get_instance() -> BigNumInstance<3, Self> {
        BLS12_377_Fr_Instance
    }
    fn modulus_bits() -> u32 {
        253
    }
}
pub global BLS12_377_Fr_Instance: BigNumInstance<3, BLS12_377_Fr_Params> = BigNumInstance {
        modulus: [
            0xaa76fed00000010a11800000000001, 0x655e9a2ca55660b44d1e5c37b00159, 0x12ab
        ],
        double_modulus: [
            0x0154edfda00000021423000000000002, 0x01cabd34594aacc1689a3cb86f6002b2, 0x2555
        ],
        modulus_u60: U60Repr { limbs: [
            0x0a11800000000001, 0x0aa76fed00000010, 0x044d1e5c37b00159, 0x0655e9a2ca55660b, 0x12ab, 0x00]},
        modulus_u60_x4: U60Repr { limbs: [
            0x0a11800000000001, 0x0aa76fed00000010, 0x044d1e5c37b00159, 0x0655e9a2ca55660b, 0x12ab, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] },
        redc_param: [
            0xa180b8d69e258f5204c21151e79ea1, 0x91ec40b2c9ee4e51e49faa80548fd0, 0x036d94
        ]
};
