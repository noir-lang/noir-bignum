//! Blurb sourced from https://github.com/arkworks-rs
//! This library implements the base field of the MNT6_753 curve generated in
//! [[BCTV14]](https://eprint.iacr.org/2014/595). The name denotes that it is a
//! Miyaji--Nakabayashi--Takano curve of embedding degree 6, defined over a
//! 753-bit (prime) field. The main feature of this curve is that its scalar
//! field and base field respectively equal the base field and scalar field of
//! MNT4_753.
//!
//! Curve information:
//! * Base field: q = 0x01C4C62D92C41110229022EEE2CDADB7F997505B8FAFED5EB7E8F96C97D87307FDB925E8A0ED8D99D124D9A15AF79DB26C5C28C859A99B3EEBCA9429212636B9DFF97634993AA4D6C381BC3F0057974EA099170FA13A4FD90776E240000001
//! * Scalar field: r = 0x01C4C62D92C41110229022EEE2CDADB7F997505B8FAFED5EB7E8F96C97D87307FDB925E8A0ED8D99D124D9A15AF79DB117E776F218059DB80F0DA5CB537E38685ACCE9767254A4638810719AC425F0E39D54522CDD119F5E9063DE245E8001
//! * valuation(q - 1, 2) = 30
//! * valuation(r - 1, 2) = 15
//! * G1 curve equation: y^2 = x^3 + ax + b, where
//!    * a = 11
//!    * b = 0x7DA285E70863C79D56446237CE2E1468D14AE9BB64B2BB01B10E60A5D5DFE0A25714B7985993F62F03B22A9A3C737A1A1E0FCF2C43D7BF847957C34CCA1E3585F9A80A95F401867C4E80F4747FDE5ABA7505BA6FCF2485540B13DFC8468A
//! * G2 curve equation: y^2 = x^3 + Ax + B, where
//!    * A = Fq3(0, 0, a)
//!    * B = Fq3(b * NON_RESIDUE, 0, 0)
//!    * NON_RESIDUE = 11 is the cubic non-residue used to conpub struct  the
//!      extension field Fq3
use crate::bignum::BigNum;
use crate::bignum::derive_bignum;
use crate::params::BigNumParams;

pub global MNT6_753_Fq_PARAMS: BigNumParams<7, 753> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0xa099170fa13a4fd90776e240000001,
        0xf97634993aa4d6c381bc3f0057974e,
        0x28c859a99b3eebca9429212636b9df,
        0xe8a0ed8d99d124d9a15af79db26c5c,
        0x8fafed5eb7e8f96c97d87307fdb925,
        0xc41110229022eee2cdadb7f997505b,
        0x01c4c62d92,
    ],
    double_modulus: [
        0x0141322e1f42749fb20eedc480000002,
        0x01f2ec69327549ad8703787e00af2e9c,
        0x015190b353367dd7952852424c6d73be,
        0x01d141db1b33a249b342b5ef3b64d8b7,
        0x011f5fdabd6fd1f2d92fb0e60ffb724a,
        0x01882220452045ddc59b5b6ff32ea0b6,
        0x03898c5b24,
    ],
    redc_param: [
        0x2dae11d15867718ec70f5ff059bba2,
        0x76d65fe7e00ba391da260f2623ff9a,
        0x140a086edaa60c58eb476bdedcb352,
        0x300e0ede1965cbf72f0aa9bee81208,
        0x7fb932cae2aba9a5d17c1ff73538ba,
        0x82727c6eaef38056aaa0aaedb05746,
        0x242f916cfa,
    ],
};

#[derive_bignum(7, 753, quote {MNT6_753_Fq_PARAMS})]
pub struct MNT6_753_Fq {
    limbs: [u128; 7],
}
