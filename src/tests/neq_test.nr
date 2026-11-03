use crate::bignum::BigNum;
use crate::constants::GRUMPKIN_MODULUS;
use crate::fns::constrained_ops::{assert_is_not_equal, assert_is_not_zero};
use crate::tests::eq_fixtures::{
    BN254_LAZY_MAX, BN254_MODULUS, BN254_MODULUS_PLUS_ONE, LIMB_MAX, unchecked_params,
};

use crate::fields::bls12_381Fq::BLS12_381_Fq;
use crate::fields::bn254Fq::{BN254_Fq, BN254_Fq_PARAMS};

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
    let b = black_box(BN254_Fq::from_limbs(GRUMPKIN_MODULUS));
    a.assert_is_not_equal(&b);
    b.assert_is_not_equal(&a);
}
#[test]
fn test_neq_lazy_boundary() {
    let a = black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0]));
    let b = black_box(BN254_Fq::from_limbs(BN254_LAZY_MAX));
    a.assert_is_not_equal(&b);
    b.assert_is_not_equal(&a);
}
#[test]
fn test_neq_low_carry() {
    let a = black_box(BN254_Fq::from_limbs([LIMB_MAX, 0x0, 0x0]));
    let b = black_box(BN254_Fq::from_limbs([0x0, 0x1, 0x0]));
    a.assert_is_not_equal(&b);
    b.assert_is_not_equal(&a);
}
#[test(should_fail_with = "assert_is_not_equal fail")]
fn test_neq_same_rejects() {
    black_box(BN254_Fq::from_limbs([0x1, 0x0, 0x0])).assert_is_not_equal(
        &black_box(BN254_Fq::from_limbs([0x1, 0x0, 0x0])),
    );
}

#[test(should_fail_with = "assert_is_not_equal fail")]
unconstrained fn test_neq_same_rejects_unconstrained() {
    black_box(BN254_Fq::from_limbs([0x1, 0x0, 0x0])).assert_is_not_equal(
        &black_box(BN254_Fq::from_limbs([0x1, 0x0, 0x0])),
    );
}
#[test(should_fail_with = "assert_is_not_equal fail")]
fn test_neq_modulus_alias_rejects() {
    black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0])).assert_is_not_equal(
        &black_box(BN254_Fq::from_limbs(BN254_MODULUS)),
    );
}

#[test(should_fail_with = "assert_is_not_equal fail")]
unconstrained fn test_neq_modulus_alias_rejects_unconstrained() {
    black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0])).assert_is_not_equal(
        &black_box(BN254_Fq::from_limbs(BN254_MODULUS)),
    );
}
#[test(should_fail_with = "assert_is_not_equal fail")]
fn test_neq_lazy_alias_rejects() {
    black_box(BN254_Fq::from_limbs([0x1, 0x0, 0x0])).assert_is_not_equal(
        &black_box(BN254_Fq::from_limbs(BN254_MODULUS_PLUS_ONE)),
    );
}

#[test(should_fail_with = "assert_is_not_equal fail")]
unconstrained fn test_neq_lazy_alias_rejects_unconstrained() {
    black_box(BN254_Fq::from_limbs([0x1, 0x0, 0x0])).assert_is_not_equal(
        &black_box(BN254_Fq::from_limbs(BN254_MODULUS_PLUS_ONE)),
    );
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_neq_oversized_top_rejects() {
    assert_is_not_equal(
        &BN254_Fq_PARAMS,
        &black_box([0u128, 0, 0x8000]),
        &black_box([0; 3]),
    );
}

#[test(should_fail_with = "call to assert_max_bit_size")]
unconstrained fn test_neq_oversized_top_rejects_unconstrained() {
    assert_is_not_equal(
        &BN254_Fq_PARAMS,
        &black_box([0u128, 0, 0x8000]),
        &black_box([0; 3]),
    );
}

#[test]
fn test_neq_generic_canonical_native_alias() {
    let alias = black_box(BLS12_381_Fq::from_limbs([
        GRUMPKIN_MODULUS[0],
        GRUMPKIN_MODULUS[1],
        GRUMPKIN_MODULUS[2],
        0,
    ]));
    alias.validate_in_field();
    let zero = black_box(BLS12_381_Fq::zero());
    alias.assert_is_not_equal(&zero);
    zero.assert_is_not_equal(&alias);
    alias.assert_is_not_zero();
}
#[test(should_fail_with = "assert_is_not_equal fail")]
fn test_neq_generic_three_modulus_alias_rejected() {
    let params = unchecked_params::<4, 361>(black_box([0, 0, 0, 1]));
    assert_is_not_equal(&params, &black_box([0; 4]), &black_box([0, 0, 0, 3]));
}

#[test(should_fail_with = "assert_is_not_equal fail")]
unconstrained fn test_neq_generic_three_modulus_alias_rejected_unconstrained() {
    let params = unchecked_params::<4, 361>(black_box([0, 0, 0, 1]));
    assert_is_not_equal(&params, &black_box([0; 4]), &black_box([0, 0, 0, 3]));
}
#[test(should_fail_with = "assert_is_not_equal fail")]
fn test_neq_generic_two_modulus_nonzero_rejected() {
    let params = unchecked_params::<4, 361>(black_box([0, 0, 0, 1]));
    assert_is_not_zero(&params, &black_box([0, 0, 0, 2]));
}

#[test(should_fail_with = "assert_is_not_equal fail")]
unconstrained fn test_neq_generic_two_modulus_nonzero_rejected_unconstrained() {
    let params = unchecked_params::<4, 361>(black_box([0, 0, 0, 1]));
    assert_is_not_zero(&params, &black_box([0, 0, 0, 2]));
}
