//! Blurb sourced from https://github.com/arkworks-rs
//! This library implements the base field of the BLS12_381 curve generated by [Sean Bowe](https://electriccoin.co/blog/new-snark-curve/).
//! The name denotes that it is a Barreto--Lynn--Scott curve of embedding degree
//! 12, defined over a 381-bit (prime) field.
//! This curve was intended to replace the BN254 curve to provide a higher
//! security level without incurring a large performance overhead.
//!
//!
//! Curve information:
//! * Base field: q = 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787
//! * Scalar field: r =
//!   52435875175126190479447740508185965837690552500527637822603658699938581184513
//! * valuation(q - 1, 2) = 1
//! * valuation(r - 1, 2) = 32
//! * G1 curve equation: y^2 = x^3 + 4
//! * G2 curve equation: y^2 = x^3 + Fq2(4, 4)
use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global BLS12_381_Fq_PARAMS: BigNumParams<4, 381> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0xabfffeb153ffffb9feffffffffaaab,
        0x4b84f38512bf6730d2a0f6b0f6241e,
        0xea397fe69a4b1ba7b6434bacd76477,
        0x1a0111,
    ],
    double_modulus: [
        0x0157fffd62a7ffff73fdffffffff5556,
        0x019709e70a257ece61a541ed61ec483c,
        0x01d472ffcd3496374f6c869759aec8ed,
        0x340222,
    ],
    redc_param: [
        0x5c59e8163c701ec4f881fd59646e8b,
        0x9d07fda82a52f7d1dc780a19de74e6,
        0xbcf32791738a0406c331e9ae8a46e0,
        0x02760d74,
    ],
};

#[derive_bignum(4, 381, quote {BLS12_381_Fq_PARAMS})]
pub struct BLS12_381_Fq {
    limbs: [u128; 4],
}
