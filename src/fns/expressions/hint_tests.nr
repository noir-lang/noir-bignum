//! Constrained rejection with adversarial hints.
//!
//! `__compute_quadratic_expression_with_borrow_flags` asserts that the integer
//! remainder is zero. That assertion runs only during witness generation, so a
//! malicious prover can drop it. These tests keep hint generation and the
//! constrained relation apart: `__hint_without_remainder_check` is the honest
//! helper without that assertion, and its output goes straight into the same
//! constrained code that `evaluate_quadratic_expression` uses
//! (`compute_quadratic_expression_with_hint`, then
//! `validate_quadratic_expression_limbs`).
//!
//! The 16-product shape is a Groth16-style certificate block (16 one-by-one
//! products and one negative linear residual over BN254 Fq), which takes the
//! 28-bit narrow-tail path. The 1-product shape is the fixed-bias path that
//! `mul` and most BN254 Fq operations use. A "poisoned" residual is the honest
//! one with 1 added to limb 0: a one-unit perturbation of the arithmetic
//! relation.
//!
//! Isolation: in each rejecting test every term is in range (the honest terms
//! are accepted, and `block` and `product` assert that the poisoned limb 0
//! stays below 2^120 with a different message) and the quotient hint passes
//! `validate_quotient_in_range`, so "call to assert_max_bit_size" can come
//! only from the carry range checks of the final zero check. A quotient that
//! is off by one is also rejected. Only these two nearest quotients are run;
//! the general argument is in `evaluate_quadratic_expression`: the range
//! checks make the limb identity an integer identity, so no quotient or borrow
//! choice satisfies an expression that is nonzero mod p.
use crate::bignum::BigNum;
use crate::fields::bn254Fq::{BN254_Fq, BN254_Fq_PARAMS};
use crate::fns::constrained_ops::validate_in_range;
use crate::fns::unconstrained_helpers::__barrett_reduction;
use crate::utils::split_bits;
use super::{
    __compute_borrow_flags, __compute_quadratic_expression_product,
    compute_quadratic_expression_with_hint, evaluate_quadratic_expression, quadratic_tail_bits,
    validate_quadratic_expression_limbs,
};

/// The honest hint helper without its remainder assertion; `offset` is added
/// to quotient limb 0.
unconstrained fn __hint_without_remainder_check<let NUM_PRODUCTS: u32, let ADD_N: u32>(
    lhs: [[[u128; 3]; 1]; NUM_PRODUCTS],
    lhs_flags: [[bool; 1]; NUM_PRODUCTS],
    rhs: [[[u128; 3]; 1]; NUM_PRODUCTS],
    rhs_flags: [[bool; 1]; NUM_PRODUCTS],
    linear: [[u128; 3]; ADD_N],
    linear_flags: [bool; ADD_N],
    offset: u128,
) -> ([u128; 3], [bool; 4]) {
    let params = BN254_Fq_PARAMS;
    let mulout_p: [Field; 6] = __compute_quadratic_expression_product::<3, 254, 1, 1, NUM_PRODUCTS, ADD_N>(
        &params,
        &lhs,
        &lhs_flags,
        &rhs,
        &rhs_flags,
        &linear,
        &linear_flags,
    );
    let relation: [u128; 6] = split_bits::__normalize_limbs(mulout_p);
    let (mut quotient, _remainder): ([u128; 3], [u128; 3]) =
        __barrett_reduction(&relation, &params.redc_param, 254, &params.modulus);
    quotient[0] += offset;
    let mut mulout_n: [Field; 6] = [0; 6];
    for i in 0..3 {
        for j in 0..3 {
            mulout_n[i + j] += (quotient[i] as Field) * (params.modulus[j] as Field);
        }
    }
    let flags: [bool; 5] = __compute_borrow_flags(
        mulout_p,
        mulout_n,
        quadratic_tail_bits::<3, 254, 1, 1, NUM_PRODUCTS, ADD_N>(),
    );
    ([quotient[0], quotient[1], quotient[2]], [flags[0], flags[1], flags[2], flags[3]])
}

/// `evaluate_quadratic_expression` with the hint call replaced by a supplied hint.
fn check_with_bypassed_helper<let NUM_PRODUCTS: u32, let ADD_N: u32>(
    lhs: [[[u128; 3]; 1]; NUM_PRODUCTS],
    lhs_flags: [[bool; 1]; NUM_PRODUCTS],
    rhs: [[[u128; 3]; 1]; NUM_PRODUCTS],
    rhs_flags: [[bool; 1]; NUM_PRODUCTS],
    linear: [[u128; 3]; ADD_N],
    linear_flags: [bool; ADD_N],
    offset: u128,
) {
    let params = BN254_Fq_PARAMS;
    for k in 0..NUM_PRODUCTS {
        validate_in_range::<3, 254>(&lhs[k][0]);
        validate_in_range::<3, 254>(&rhs[k][0]);
    }
    for k in 0..ADD_N {
        validate_in_range::<3, 254>(&linear[k]);
    }
    // Safety: this is the adversarial hint under test; only constraints follow.
    let (quotient, borrow_flags) = unsafe {
        __hint_without_remainder_check(lhs, lhs_flags, rhs, rhs_flags, linear, linear_flags, offset)
    };
    let limbs = compute_quadratic_expression_with_hint::<3, 254, 1, 1, NUM_PRODUCTS, ADD_N>(
        &params,
        &lhs,
        &lhs_flags,
        &rhs,
        &rhs_flags,
        &linear,
        &linear_flags,
        quotient,
        borrow_flags,
    );
    validate_quadratic_expression_limbs::<3, 254, 1, 1, NUM_PRODUCTS, ADD_N>(limbs);
}

/// Certificate block shape: R = sum_j a_j*b_j - sum_j c_j*d_j over 8 + 8
/// products, checked as sum - R = 0. Operands are near p so the quotient is large.
fn block(
    poison: u128,
    ) -> ([[[u128; 3]; 1]; 16], [[bool; 1]; 16], [[[u128; 3]; 1]; 16], [[bool; 1]; 16], [[u128; 3]; 1]) {
    let mut lhs = [[[0; 3]]; 16];
    let mut rhs = [[[0; 3]]; 16];
    let mut signs = [[false]; 16];
    let mut residual = BN254_Fq::zero();
    for j in 0..16 {
        let a = -BN254_Fq::from((j + 1) as Field);
        let b = -BN254_Fq::from((3 * j + 7) as Field);
        lhs[j] = [a.get_limbs()];
        rhs[j] = [b.get_limbs()];
        if j % 2 == 1 {
            signs[j] = [true];
            residual = residual - a * b;
        } else {
            residual = residual + a * b;
        }
    }
    let mut r = residual.get_limbs();
    r[0] += poison;
    // Keeps the poisoned term in range, so only the zero check can reject it.
    assert(r[0] < (1 << 120), "poisoned limb out of range");
    (
        std::hint::black_box(lhs), [[false]; 16], std::hint::black_box(rhs), signs,
        std::hint::black_box([r]),
    )
}

/// Fixed-bias shape: x*y - z = 0.
fn product(poison: u128) -> ([[[u128; 3]; 1]; 1], [[[u128; 3]; 1]; 1], [[u128; 3]; 1]) {
    let x = -BN254_Fq::from(5);
    let y = -BN254_Fq::from(11);
    let mut z = (x * y).get_limbs();
    z[0] += poison;
    // Keeps the poisoned term in range, so only the zero check can reject it.
    assert(z[0] < (1 << 120), "poisoned limb out of range");
    (
        std::hint::black_box([[x.get_limbs()]]), std::hint::black_box([[y.get_limbs()]]),
        std::hint::black_box([z]),
    )
}

#[test]
fn block_honest_residual_accepts_with_bypassed_helper() {
    let (lhs, lf, rhs, rf, lin) = block(0);
    check_with_bypassed_helper(lhs, lf, rhs, rf, lin, [true], 0);
}

#[test]
fn block_honest_residual_accepts_through_evaluate() {
    let (lhs, lf, rhs, rf, lin) = block(0);
    evaluate_quadratic_expression::<3, 254, 1, 1, 16, 1>(
        &BN254_Fq_PARAMS,
        &lhs,
        &lf,
        &rhs,
        &rf,
        &lin,
        &[true],
    );
}

// Hint generation alone: the honest helper's unconstrained assertion fails.
// This is not evidence of a constraint rejection; see the two tests below.
#[test(should_fail)]
fn block_poisoned_residual_fails_hint_generation() {
    let (lhs, lf, rhs, rf, lin) = block(1);
    evaluate_quadratic_expression::<3, 254, 1, 1, 16, 1>(
        &BN254_Fq_PARAMS,
        &lhs,
        &lf,
        &rhs,
        &rf,
        &lin,
        &[true],
    );
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn block_poisoned_residual_rejected_by_constraints() {
    let (lhs, lf, rhs, rf, lin) = block(1);
    check_with_bypassed_helper(lhs, lf, rhs, rf, lin, [true], 0);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn block_poisoned_residual_rejected_with_next_quotient() {
    let (lhs, lf, rhs, rf, lin) = block(1);
    check_with_bypassed_helper(lhs, lf, rhs, rf, lin, [true], 1);
}

#[test]
fn product_honest_accepts_with_bypassed_helper() {
    let (x, y, z) = product(0);
    check_with_bypassed_helper(x, [[false]], y, [[false]], z, [true], 0);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn product_poisoned_rejected_by_constraints() {
    let (x, y, z) = product(1);
    check_with_bypassed_helper(x, [[false]], y, [[false]], z, [true], 0);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn product_poisoned_rejected_with_next_quotient() {
    let (x, y, z) = product(1);
    check_with_bypassed_helper(x, [[false]], y, [[false]], z, [true], 1);
}

// Powers of two let these boundary cases compute the independent expected
// remainder directly: (m-1)^2 = 1 mod m, so -32 products leave m-32.
fn runtime_tail_boundary<let M: u32>() {
    let top = 1u128 << ((M - 241) as u128);
    let params = crate::params::BigNumParams::<3, M>::new(
        false,
        [0, 0, top],
        [0, 0, 1u128 << ((M - 233) as u128)],
    );
    let b = 1u128 << 120;
    let x = std::hint::black_box([b - 1, b - 1, top - 1]);
    let result = std::hint::black_box([b - 32, b - 1, top - 1]);
    evaluate_quadratic_expression::<3, M, 1, 1, 32, 1>(
        &params,
        &[[x]; 32],
        &[[false]; 32],
        &[[x]; 32],
        &[[true]; 32],
        &[result],
        &[true],
    );
}
#[test]
fn runtime_tail_low_width() {
    runtime_tail_boundary::<241>();
}
#[test]
fn runtime_tail_high_width() {
    runtime_tail_boundary::<258>();
}
#[test]
fn runtime_tail_width_fallback() {
    runtime_tail_boundary::<259>();
}
#[test]
fn dispatch_guards_preserve_fallback() {
    assert_eq(super::quadratic_tail_bits::<4, 381, 1, 1, 1, 1>(), 126);
    assert_eq(super::quadratic_tail_bits::<3, 258, 1, 1, 33, 1>(), 126);
    assert_eq(super::quadratic_tail_bits::<3, 258, 1, 1, 1, 9>(), 126);
    assert(!super::quadratic_fixed_bias::<3, 255, 1, 1, 1, 1>());
    assert(!super::quadratic_fixed_bias::<3, 254, 2, 2, 1, 1>());
}
