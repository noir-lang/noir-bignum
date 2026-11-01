use crate::{BigNum, BN254_Fq};
use std::hint::black_box;

#[test]
fn test_neq_canonical_native_collision() {
    let a = black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0]));
    let b = black_box(
        BN254_Fq::from_limbs([0x4d8248eeb859fbf83e9682e87cfd46, 0x6f, 0x0]),
    );
    a.assert_is_not_equal(&b);
    b.assert_is_not_equal(&a);
}
#[test]
fn test_neq_native_alias() {
    let a = black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0]));
    let b = black_box(BN254_Fq::from_limbs([
        0x33e84879b9709143e1f593f0000001,
        0x4e72e131a029b85045b68181585d28,
        0x3064,
    ]));
    a.assert_is_not_equal(&b);
    b.assert_is_not_equal(&a);
}
#[test]
fn test_neq_lazy_boundary() {
    let a = black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0]));
    let b = black_box(BN254_Fq::from_limbs([
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0x3fff,
    ]));
    a.assert_is_not_equal(&b);
    b.assert_is_not_equal(&a);
}
#[test]
fn test_neq_low_carry() {
    let a = black_box(
        BN254_Fq::from_limbs([0xffffffffffffffffffffffffffffff, 0x0, 0x0]),
    );
    let b = black_box(BN254_Fq::from_limbs([0x0, 0x1, 0x0]));
    a.assert_is_not_equal(&b);
    b.assert_is_not_equal(&a);
}
#[test(should_fail)]
fn test_neq_same_rejects() {
    black_box(BN254_Fq::from_limbs([0x1, 0x0, 0x0])).assert_is_not_equal(
        &black_box(BN254_Fq::from_limbs([0x1, 0x0, 0x0])),
    );
}
#[test(should_fail)]
fn test_neq_modulus_alias_rejects() {
    black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0])).assert_is_not_equal(
        &black_box(BN254_Fq::from_limbs([
            0x816a916871ca8d3c208c16d87cfd47,
            0x4e72e131a029b85045b68181585d97,
            0x3064,
        ])),
    );
}
#[test(should_fail)]
fn test_neq_lazy_alias_rejects() {
    black_box(BN254_Fq::from_limbs([0x1, 0x0, 0x0])).assert_is_not_equal(
        &black_box(BN254_Fq::from_limbs([
            0x816a916871ca8d3c208c16d87cfd48,
            0x4e72e131a029b85045b68181585d97,
            0x3064,
        ])),
    );
}

#[test(should_fail)]
fn test_neq_oversized_top_rejects() {
    crate::internal::assert_is_not_equal(
        &crate::fields::bn254Fq::BN254_Fq_PARAMS,
        &black_box([0u128, 0, 0x8000]),
        &black_box([0; 3]),
    );
}

#[test]
fn test_neq_generic_canonical_native_alias() {
    let alias = black_box(crate::BLS12_381_Fq::from_limbs([
        0x33e84879b9709143e1f593f0000001,
        0x4e72e131a029b85045b68181585d28,
        0x3064,
        0,
    ]));
    alias.validate_in_field();
    let zero = black_box(crate::BLS12_381_Fq::zero());
    alias.assert_is_not_equal(&zero);
    zero.assert_is_not_equal(&alias);
    alias.assert_is_not_zero();
}
#[test(should_fail_with = "assert_is_not_equal fail")]
fn test_neq_generic_three_modulus_alias_rejected() {
    let params = crate::params::BigNumParams::<4, 361> {
        has_multiplicative_inverse: false,
        modulus: black_box([0, 0, 0, 1]),
        double_modulus: [0; 4],
        redc_param: [0; 4],
    };
    crate::internal::assert_is_not_equal(&params, &black_box([0; 4]), &black_box([0, 0, 0, 3]));
}
#[test(should_fail_with = "assert_is_not_equal fail")]
fn test_neq_generic_two_modulus_nonzero_rejected() {
    let params = crate::params::BigNumParams::<4, 361> {
        has_multiplicative_inverse: false,
        modulus: black_box([0, 0, 0, 1]),
        double_modulus: [0; 4],
        redc_param: [0; 4],
    };
    crate::internal::assert_is_not_zero(&params, &black_box([0, 0, 0, 2]));
}
