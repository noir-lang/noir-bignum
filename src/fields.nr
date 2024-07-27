mod bn254Fq;
mod bls12_377Fq;
mod bls12_377Fr;
mod bls12_381Fr;
mod bls12_381Fq;
mod ed25519Fq;
mod ed25519Fr;
mod mnt4_753Fq;
mod mnt4_753Fr;
mod mnt6_753Fq;
mod mnt6_753Fr;
mod pallasFq;
mod pallasFr;
mod secp256k1Fq;
mod secp256k1Fr;
mod secp256r1Fq;
mod secp256r1Fr;
mod secp384r1Fq;
mod secp384r1Fr;
mod vestaFq;
mod vestaFr;

use crate::BigNum;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::fields::bn254Fq::BNParams;

/**
 * @brief Parameter definitions for generic fields of varying bit lengths
 *        (these can be used when defining modular fields where the
 *         modulus is a witness value and cannot be predefined
 *         e.g. 2048-bit RSA)
 **/
struct Params512 {}
impl RuntimeBigNumParamsTrait<5> for Params512 {
    fn modulus_bits() -> u64 {
        512
    }
}
struct Params768 {}
impl RuntimeBigNumParamsTrait<7> for Params768 {
    fn modulus_bits() -> u64 {
        768
    }
}
struct Params1024 {}
impl RuntimeBigNumParamsTrait<9> for Params1024 {
    fn modulus_bits() -> u64 {
        1024
    }
}
struct Params2048 {}
impl RuntimeBigNumParamsTrait<18> for Params2048 {
    fn modulus_bits() -> u64 {
        2048
    }
}
struct Params4096 {}
impl RuntimeBigNumParamsTrait<35> for Params4096 {
    fn modulus_bits() -> u64 {
        4096
    }
}

// example typedef when using a defined bignum instance
type Fq = BigNum<3, BNParams>;

