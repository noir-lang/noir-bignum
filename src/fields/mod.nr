pub mod bn254Fq;
pub mod bls12_377Fq;
pub mod bls12_377Fr;
pub mod bls12_381Fr;
pub mod bls12_381Fq;
pub mod ed25519Fq;
pub mod ed25519Fr;
pub mod mnt4_753Fq;
pub mod mnt4_753Fr;
pub mod mnt6_753Fq;
pub mod mnt6_753Fr;
pub mod pallasFq;
pub mod pallasFr;
pub mod secp256k1Fq;
pub mod secp256k1Fr;
pub mod secp256r1Fq;
pub mod secp256r1Fr;
pub mod secp384r1Fq;
pub mod secp384r1Fr;
pub mod vestaFq;
pub mod vestaFr;
pub mod U256;
pub mod U384;
pub mod U512;
pub mod U768;
pub mod U1024;
pub mod U2048;
pub mod U4096;
pub mod U8192;

pub use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;

/**
 * @brief Parameter definitions for generic fields of varying bit lengths
 *        (these can be used when defining modular fields where the
 *         modulus is a witness value and cannot be predefined
 *         e.g. 2048-bit RSA)
 **/
pub struct Params512 {}
impl RuntimeBigNumParamsTrait<5> for Params512 {
    fn modulus_bits() -> u32 {
        512
    }
}
pub struct Params768 {}
impl RuntimeBigNumParamsTrait<7> for Params768 {
    fn modulus_bits() -> u32 {
        768
    }
}
pub struct Params1024 {}
impl RuntimeBigNumParamsTrait<9> for Params1024 {
    fn modulus_bits() -> u32 {
        1024
    }
}
pub struct Params2048 {}
impl RuntimeBigNumParamsTrait<18> for Params2048 {
    fn modulus_bits() -> u32 {
        2048
    }
}
pub struct Params4096 {}
impl RuntimeBigNumParamsTrait<35> for Params4096 {
    fn modulus_bits() -> u32 {
        4096
    }
}
