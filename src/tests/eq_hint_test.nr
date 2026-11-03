//! Adversarial-hint tests for the exact modular equality decomposition.
//!
//! `eq_with_hints` is the constrained core of `eq`: the prover-supplied
//! residue, quotient and chain carries are ordinary witnesses, so these tests
//! feed poisoned values straight into the constrained path and check that
//! every dishonest choice is rejected, while the two valid residue
//! representatives of an equal pair (0 and MOD) both yield `true`.

use crate::fields::bn254Fq::BN254_Fq_PARAMS;
use crate::fns::constrained_ops::eq_with_hints;
use crate::tests::eq_fixtures::BN254_MODULUS;
use std::hint::black_box;

// Biased encodings: q_shift = k + 4, carry_shift[i] = carry + 8 (last unused).
global Q_ZERO: u128 = 4;
global CARRIES_ZERO: [u128; 3] = [8, 8, 8];

#[test]
fn test_eq_hint_zero_residue_accepted() {
    let a = black_box([0x1, 0x0, 0x0]);
    assert(
        eq_with_hints(
            &BN254_Fq_PARAMS,
            &a,
            &a,
            Q_ZERO,
            &black_box([0; 3]),
            &CARRIES_ZERO,
        ),
    );
}

#[test]
fn test_eq_hint_modulus_residue_accepted() {
    // Equal operands, residue presented as MOD with k = -1: a - a = -MOD + MOD.
    // The decomposition admits exactly the two representatives 0 and MOD of
    // the zero class below 2^MOD_BITS; both must report "equal".
    let a = black_box([0x1, 0x0, 0x0]);
    assert(eq_with_hints(
        &BN254_Fq_PARAMS,
        &a,
        &a,
        black_box(3),
        &black_box(BN254_MODULUS),
        &CARRIES_ZERO,
    ));
}

#[test(should_fail_with = "eq decomposition fail")]
fn test_eq_hint_wrong_residue_class_rejects() {
    // lhs - rhs = 2, but the prover claims residue 3 with k = 0.
    let _ = eq_with_hints(
        &BN254_Fq_PARAMS,
        &black_box([0x2, 0x0, 0x0]),
        &black_box([0x0, 0x0, 0x0]),
        Q_ZERO,
        &black_box([0x3, 0x0, 0x0]),
        &CARRIES_ZERO,
    );
}

#[test(should_fail_with = "eq decomposition fail")]
fn test_eq_hint_unequal_forced_equal_rejects() {
    // Unequal operands with a zero residue claim: no in-range quotient or
    // carries can satisfy the chain, so the flag cannot be steered to "equal".
    let _ = eq_with_hints(
        &BN254_Fq_PARAMS,
        &black_box([0x1, 0x0, 0x0]),
        &black_box([0x0, 0x0, 0x0]),
        Q_ZERO,
        &black_box([0x0, 0x0, 0x0]),
        &CARRIES_ZERO,
    );
}

#[test(should_fail_with = "eq decomposition fail")]
fn test_eq_hint_fudged_carry_rejects() {
    // Same forged claim, now with a non-zero first carry trying to absorb the
    // difference: 1 != carry * 2^120 for any in-range carry.
    let _ = eq_with_hints(
        &BN254_Fq_PARAMS,
        &black_box([0x1, 0x0, 0x0]),
        &black_box([0x0, 0x0, 0x0]),
        Q_ZERO,
        &black_box([0x0, 0x0, 0x0]),
        &black_box([9, 8, 8]),
    );
}

#[test(should_fail_with = "eq decomposition fail")]
fn test_eq_hint_top_limb_forced_equal_rejects() {
    // lhs - rhs = 2^240 differs only in the top limb, with a zero residue
    // claim: every lower-limb equation balances, so only the top-limb equation
    // stops the flag being steered to "equal" for unequal operands.
    let _ = eq_with_hints(
        &BN254_Fq_PARAMS,
        &black_box([0x0, 0x0, 0x1]),
        &black_box([0x0, 0x0, 0x0]),
        Q_ZERO,
        &black_box([0x0, 0x0, 0x0]),
        &CARRIES_ZERO,
    );
}

#[test(should_fail_with = "eq decomposition fail")]
fn test_eq_hint_top_limb_forced_unequal_rejects() {
    // Equal operands with a forged residue 2^240 in the top limb only: the
    // lower-limb equations balance, so only the top-limb equation stops the
    // flag being steered to "not equal" (which would let
    // `assert_is_not_equal(a, a)` pass).
    let a = black_box([0x7, 0x0, 0x0]);
    let _ = eq_with_hints(
        &BN254_Fq_PARAMS,
        &a,
        &a,
        Q_ZERO,
        &black_box([0x0, 0x0, 0x1]),
        &CARRIES_ZERO,
    );
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_eq_hint_oversized_quotient_rejects() {
    // q_shift must fit 3 bits (k in -4..=3).
    let a = black_box([0x0, 0x0, 0x0]);
    let _ = eq_with_hints(
        &BN254_Fq_PARAMS,
        &a,
        &a,
        black_box(8),
        &black_box([0; 3]),
        &CARRIES_ZERO,
    );
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_eq_hint_oversized_carry_rejects() {
    // Each carry_shift must fit 4 bits.
    let a = black_box([0x0, 0x0, 0x0]);
    let _ = eq_with_hints(
        &BN254_Fq_PARAMS,
        &a,
        &a,
        Q_ZERO,
        &black_box([0; 3]),
        &black_box([16, 8, 8]),
    );
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_eq_hint_oversized_residue_rejects() {
    // Residue 2*MOD is consistent with the chain for equal operands (k = -2),
    // but exceeds 2^MOD_BITS: without the residue range check it would let a
    // third representative of zero through, so it must be rejected.
    let mut two_q: [u128; 3] = [0; 3];
    for i in 0..3 {
        two_q[i] = 2 * BN254_MODULUS[i];
    }
    let a = black_box([0x0, 0x0, 0x0]);
    let _ = eq_with_hints(
        &BN254_Fq_PARAMS,
        &a,
        &a,
        black_box(2),
        &black_box(two_q),
        &CARRIES_ZERO,
    );
}
