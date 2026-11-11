//! Tests for the fixed-bias zero check of `evaluate_quadratic_expression`.
//!
//! Dishonest quotients: `__compute_quadratic_expression_quotient` asserts that the
//! remainder is zero, but that assertion only runs during witness generation, so a
//! malicious prover can drop it. The `fixed_bias_*_hint_*` tests therefore compute the
//! quotient with `__compute_quadratic_expression`, which has no such assertion, optionally
//! add an offset to it, and feed it straight into the constrained code that
//! `evaluate_quadratic_expression` uses (`compute_quadratic_expression_with_hint`, then
//! `validate_quadratic_expression_limbs`). The relation is `x * y - z = 0` over BN254 Fq;
//! each rejecting test adds an error to the honest `z`, so the relation is false by that
//! amount modulo MOD.
//!
//! Which check rejects: every term is a range-checked `BigNum` value and the quotient is
//! asserted in range with its own message, so "call to assert_max_bit_size" can come only
//! from the carry range checks of the zero check.
//!   - An error of 1 makes limb 0 of the expression indivisible by 2^120, so the first
//!     carry check (126 bits) rejects it.
//!   - An error of 2^360 with the quotient chosen so that the expression is exactly
//!     -2^360 leaves limbs 0..2 balanced: the three 126-bit carry checks pass (asserted
//!     here with a different message) and the last, 28-bit carry check rejects it.
//!
//! Honest witnesses: the `fixed_bias_guard_boundary_*` and `fixed_bias_width_*` tests run
//! honest relations of the largest shape the guard admits (three products and eight linear
//! terms) with the largest operands, at the narrowest and widest moduli the guard admits.
use crate::bignum::BigNum;
use crate::constants::TWO_POW_120;
use crate::fields::bn254Fq::{BN254_Fq, BN254_Fq_PARAMS};
use crate::fns::unconstrained_helpers::__helper_add;
use crate::params::BigNumParams;
use super::{
    __compute_quadratic_expression, compute_quadratic_expression_with_hint,
    evaluate_quadratic_expression, quadratic_fixed_bias, validate_quadratic_expression_limbs,
};

/// `ceil(2^360 / MOD)` for BN254 Fq. If the expression without the quotient is
/// `-2^360 (mod MOD)`, adding this to its floor quotient makes the whole
/// expression exactly `-2^360`.
global TWO_POW_360_QUOTIENT: u128 = 0x54a47462623a04a7ab074a58681;

global TWO_POW_27: Field = 0x8000000;
global TWO_POW_28: Field = 0x10000000;
global TWO_POW_125: Field = 0x20000000000000000000000000000000;
global TWO_POW_126: Field = 0x40000000000000000000000000000000;

/// `2^360 (mod MOD)`.
fn two_pow_360() -> BN254_Fq {
    let radix = BN254_Fq::from_limbs([0, 1, 0]);
    radix * radix * radix
}

/// The relation `x * y - z = 0` with `error` added to the honest `z`.
fn product_relation(error: BN254_Fq) -> ([[[u128; 3]; 1]; 1], [[[u128; 3]; 1]; 1], [[u128; 3]; 1]) {
    let x = -BN254_Fq::from(5);
    let y = -BN254_Fq::from(11);
    let z = (x * y + error).get_limbs();
    (
        std::hint::black_box([[x.get_limbs()]]), std::hint::black_box([[y.get_limbs()]]),
        std::hint::black_box([z]),
    )
}

/// The floor quotient of `x * y - z` plus `offset`, without checking the remainder.
unconstrained fn __quotient_without_remainder_check(
    x: [[[u128; 3]; 1]; 1],
    y: [[[u128; 3]; 1]; 1],
    z: [[u128; 3]; 1],
    offset: u128,
) -> [u128; 3] {
    let (floor_quotient, _remainder) = __compute_quadratic_expression(
        &BN254_Fq_PARAMS,
        &x,
        &[[false]],
        &y,
        &[[false]],
        &z,
        &[true],
    );
    __helper_add(&floor_quotient, &[offset, 0, 0])
}

/// The expression limbs that `evaluate_quadratic_expression` would pass to its zero
/// check for `x * y - z`, with the quotient replaced by the floor quotient plus `offset`.
fn limbs_with_quotient_offset(
    x: [[[u128; 3]; 1]; 1],
    y: [[[u128; 3]; 1]; 1],
    z: [[u128; 3]; 1],
    offset: u128,
) -> [Field; 5] {
    // Safety: this is the dishonest hint under test; only constraints follow.
    let quotient = unsafe { __quotient_without_remainder_check(x, y, z, offset) };
    // Same bounds as `validate_quotient_in_range`, so that check cannot be the
    // one that rejects.
    assert(
        (quotient[0] < TWO_POW_120) & (quotient[1] < TWO_POW_120) & (quotient[2] < (1 << 20)),
        "quotient hint out of range",
    );
    compute_quadratic_expression_with_hint::<3, 254, 1, 1, 1, 1>(
        &BN254_Fq_PARAMS,
        &x,
        &[[false]],
        &y,
        &[[false]],
        &z,
        &[true],
        quotient,
        [false; 4],
    )
}

fn check_with_quotient_offset(error: BN254_Fq, offset: u128) {
    let (x, y, z) = product_relation(error);
    let limbs = limbs_with_quotient_offset(x, y, z, offset);
    validate_quadratic_expression_limbs::<3, 254, 1, 1, 1, 1>(limbs);
}

#[test]
fn fixed_bias_honest_hint_accepted() {
    assert(quadratic_fixed_bias::<3, 254, 1, 1, 1, 1>());
    check_with_quotient_offset(BN254_Fq::zero(), 0);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn fixed_bias_off_by_one_hint_rejected_with_floor_quotient() {
    check_with_quotient_offset(BN254_Fq::one(), 0);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn fixed_bias_off_by_one_hint_rejected_with_next_quotient() {
    check_with_quotient_offset(BN254_Fq::one(), 1);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn fixed_bias_error_two_pow_360_hint_rejected_by_last_carry_check() {
    let (x, y, z) = product_relation(two_pow_360());
    let mut limbs = limbs_with_quotient_offset(x, y, z, TWO_POW_360_QUOTIENT);
    // Recompute the first three carries and check, with a message of our own,
    // that each passes its 126-bit check, so only the last check can reject.
    let original = limbs;
    for i in 0..3 {
        let carry = limbs[i] / (TWO_POW_120 as Field);
        assert((carry + TWO_POW_125).lt(TWO_POW_126), "lower carry out of range");
        limbs[i + 1] += carry;
    }
    let last_carry = limbs[3] / (TWO_POW_120 as Field);
    assert(!(last_carry + TWO_POW_27).lt(TWO_POW_28), "last carry in range");
    validate_quadratic_expression_limbs::<3, 254, 1, 1, 1, 1>(original);
}

// Completeness at the fixed-bias guard boundary: three products and eight
// linear terms, the most the guard admits, with honest hints. Seven linear
// terms and every product operand are 2^254 - 1, the largest value that passes
// the operand range check; the eighth linear term balances the relation.
// `negate` flips the sign of every product (through its right-hand side) and
// of every linear term.
fn fixed_bias_guard_boundary(negate: bool) {
    let max = BN254_Fq::from_limbs([TWO_POW_120 - 1, TWO_POW_120 - 1, 0x3fff]);
    let square = max * max;
    let balance = -(square + square + square + BN254_Fq::from(7) * max);
    let x = std::hint::black_box(max.get_limbs());
    let mut linear = [x; 8];
    linear[7] = std::hint::black_box(balance.get_limbs());
    evaluate_quadratic_expression::<3, 254, 1, 1, 3, 8>(
        &BN254_Fq_PARAMS,
        &[[x]; 3],
        &[[false]; 3],
        &[[x]; 3],
        &[[negate]; 3],
        &linear,
        &[negate; 8],
    );
}

#[test]
fn fixed_bias_guard_boundary_all_positive() {
    assert(quadratic_fixed_bias::<3, 254, 1, 1, 3, 8>());
    fixed_bias_guard_boundary(false);
}

#[test]
fn fixed_bias_guard_boundary_all_negated() {
    fixed_bias_guard_boundary(true);
}

// Same shape with every term a negated zero, so each product is
// `(2*MOD) * (2*MOD)` and each linear term is `2*MOD` in the padded
// representation: the largest limbs a term can take.
#[test]
fn fixed_bias_guard_boundary_padded_terms() {
    let zero = std::hint::black_box([0; 3]);
    evaluate_quadratic_expression::<3, 254, 1, 1, 3, 8>(
        &BN254_Fq_PARAMS,
        &[[zero]; 3],
        &[[true]; 3],
        &[[zero]; 3],
        &[[true]; 3],
        &[zero; 8],
        &[true; 8],
    );
}

// The guard-boundary shape at other modulus widths, over the runtime modulus
// `MOD = 2^(M - 1)`. The operand `x = 2^M - 1` is the largest that passes the
// range check and is `-1 (mod MOD)`, so with every sign positive the relation
// is `3 * 1 + 7 * (-1) + 4 = 0`, and with every sign negated it is
// `-3 + 7 - 4 = 0`. The last test runs every term as a negated zero.
fn fixed_bias_width_boundary<let M: u32>() {
    let top = 1u128 << ((M - 241) as u128);
    // redc_param = 2^(2M + 6) / MOD = 2^(M + 7).
    let params =
        BigNumParams::<3, M>::new(false, [0, 0, top], [0, 0, 1u128 << ((M - 233) as u128)]);
    let x = std::hint::black_box([TWO_POW_120 - 1, TWO_POW_120 - 1, 2 * top - 1]);
    let mut linear = [x; 8];
    linear[7] = std::hint::black_box([4, 0, 0]);
    for negate in [false, true] {
        evaluate_quadratic_expression::<3, M, 1, 1, 3, 8>(
            &params,
            &[[x]; 3],
            &[[false]; 3],
            &[[x]; 3],
            &[[negate]; 3],
            &linear,
            &[negate; 8],
        );
    }
    let zero = std::hint::black_box([0; 3]);
    evaluate_quadratic_expression::<3, M, 1, 1, 3, 8>(
        &params,
        &[[zero]; 3],
        &[[true]; 3],
        &[[zero]; 3],
        &[[true]; 3],
        &[zero; 8],
        &[true; 8],
    );
}

#[test]
fn fixed_bias_width_241() {
    assert(quadratic_fixed_bias::<3, 241, 1, 1, 3, 8>());
    fixed_bias_width_boundary::<241>();
}

#[test]
fn fixed_bias_width_258() {
    assert(quadratic_fixed_bias::<3, 258, 1, 1, 3, 8>());
    fixed_bias_width_boundary::<258>();
}

// The widest admitted modulus with every limb at its maximum, `MOD = 2^258 - 1`,
// so the modulus limbs, the padded limbs of negated terms and the quotient are
// all as large as the guard allows. Every term is negated and every operand is
// `0` or `MOD` (both zero modulo MOD, so each relation holds), with the three
// expanded products arranged as three products, as one product of a 3-term sum
// and a single term, and as one product of a single term and a 3-term sum.
#[test]
fn fixed_bias_width_258_max_limbs() {
    // redc_param = floor(2^(2*258 + 6) / MOD) = 2^264 + 64.
    let params = BigNumParams::<3, 258>::new(
        false,
        [TWO_POW_120 - 1, TWO_POW_120 - 1, (1 << 18) - 1],
        [64, 0, 1 << 24],
    );
    assert(quadratic_fixed_bias::<3, 258, 1, 1, 3, 8>());
    assert(quadratic_fixed_bias::<3, 258, 3, 1, 1, 8>());
    assert(quadratic_fixed_bias::<3, 258, 1, 3, 1, 8>());
    for operand in [[0; 3], params.modulus] {
        let x = std::hint::black_box(operand);
        evaluate_quadratic_expression::<3, 258, 1, 1, 3, 8>(
            &params,
            &[[x]; 3],
            &[[true]; 3],
            &[[x]; 3],
            &[[true]; 3],
            &[x; 8],
            &[true; 8],
        );
        evaluate_quadratic_expression::<3, 258, 3, 1, 1, 8>(
            &params,
            &[[x; 3]],
            &[[true; 3]],
            &[[x]],
            &[[true]],
            &[x; 8],
            &[true; 8],
        );
        evaluate_quadratic_expression::<3, 258, 1, 3, 1, 8>(
            &params,
            &[[x]],
            &[[true]],
            &[[x; 3]],
            &[[true; 3]],
            &[x; 8],
            &[true; 8],
        );
    }
}

// One bit wider than the guard admits: the same relations use the borrow-flag check.
#[test]
fn fixed_bias_width_259_uses_borrow_flags() {
    assert(!quadratic_fixed_bias::<3, 259, 1, 1, 3, 8>());
    fixed_bias_width_boundary::<259>();
}

#[test]
fn fixed_bias_guard_excludes_other_shapes() {
    // Four limbs.
    assert(!quadratic_fixed_bias::<4, 381, 1, 1, 1, 1>());
    // More than three expanded products, through each count.
    assert(!quadratic_fixed_bias::<3, 254, 2, 2, 1, 1>());
    assert(!quadratic_fixed_bias::<3, 254, 1, 1, 4, 8>());
    // More than eight linear terms.
    assert(!quadratic_fixed_bias::<3, 254, 1, 1, 3, 9>());
}
