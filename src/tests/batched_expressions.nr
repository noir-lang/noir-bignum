use crate::{
    BigNum, BLS12_377_Fq, BLS12_381_Fq, BN254_Fq, ED25519_Fq, MNT4_753_Fq, Pallas_Fq, U1024, U2048,
    U256, U4096, U512, U8192, Vesta_Fq,
};
use crate::bignum::{evaluate_quadratic_expressions, evaluate_quadratic_expressions_with_params};
use std::hint::black_box;

fn small<T: BigNum>(value: u128) -> T {
    let mut limbs = T::zero().get_limbs();
    limbs[0] = value;
    T::from_limbs(limbs)
}

fn check_shared_products<T: BigNum>() {
    let a = black_box(small::<T>(3));
    let b = black_box(small::<T>(5));
    let product = black_box(small::<T>(15));
    let square = black_box(small::<T>(9));
    // a*b-product=0 and a*a-square=0 reuse the same checked a.
    evaluate_quadratic_expressions(
        [a, b, product, square],
        [[[0]], [[0]]],
        [[[false]], [[false]]],
        [[[1]], [[0]]],
        [[[false]], [[false]]],
        [[2], [3]],
        [[true], [true]],
    );
}

#[test]
fn batch_native_and_pasta_fields() {
    check_shared_products::<BN254_Fq>();
    check_shared_products::<ED25519_Fq>();
    check_shared_products::<Pallas_Fq>();
    check_shared_products::<Vesta_Fq>();
}

#[test]
fn batch_four_and_seven_limb_fields() {
    check_shared_products::<BLS12_381_Fq>();
    check_shared_products::<BLS12_377_Fq>();
    check_shared_products::<MNT4_753_Fq>();
}

#[test]
fn batch_integer_layouts() {
    check_shared_products::<U256>();
    check_shared_products::<U512>();
    check_shared_products::<U1024>();
    check_shared_products::<U2048>();
    check_shared_products::<U4096>();
}

#[test]
fn batch_largest_integer_linear_relation() {
    // U8192 multiplication exceeds the existing quadratic product bound.
    // Its supported linear relation still shares checked inputs normally.
    let a = black_box(U8192::from(7));
    evaluate_quadratic_expressions(
        [a],
        [[[]]; 2],
        [[[]]; 2],
        [[[]]; 2],
        [[[]]; 2],
        [[0, 0]; 2],
        [[false, true]; 2],
    );
}

#[test]
fn batch_runtime_modulus_and_witness_indices() {
    let params = BN254_Fq::params();
    let pool = black_box([[3, 0, 0], [5, 0, 0], [15, 0, 0]]);
    let index = black_box(0u32);
    evaluate_quadratic_expressions_with_params(
        &params,
        &pool,
        &[[[index]]],
        &[[[false]]],
        &[[[1]]],
        &[[[false]]],
        &[[2]],
        &[[true]],
    );
}

#[test]
fn batch_accepts_bounded_modular_alias() {
    let modulus = black_box(BN254_Fq::from_limbs_unsafe(BN254_Fq::params().modulus));
    evaluate_quadratic_expressions([modulus], [[[]]], [[[]]], [[[]]], [[[]]], [[0]], [[false]]);
}

#[test(should_fail)]
fn batch_rejects_wrong_second_relation() {
    let a = black_box(BN254_Fq::from(3));
    let correct = black_box(BN254_Fq::from(9));
    let wrong = black_box(BN254_Fq::from(8));
    evaluate_quadratic_expressions(
        [a, correct, wrong],
        [[[0]]; 2],
        [[[false]]; 2],
        [[[0]]; 2],
        [[[false]]; 2],
        [[1], [2]],
        [[true]; 2],
    );
}

#[test(should_fail)]
fn batch_rejects_oversized_unused_pool_value() {
    let valid = black_box(BN254_Fq::zero());
    let invalid = black_box(BN254_Fq::from_limbs_unsafe([1u128 << 120, 0, 0]));
    evaluate_quadratic_expressions(
        [valid, invalid],
        [[[]]],
        [[[]]],
        [[[]]],
        [[[]]],
        [[0]],
        [[false]],
    );
}

#[test(should_fail)]
fn batch_rejects_index_outside_pool() {
    let zero = black_box(BN254_Fq::zero());
    evaluate_quadratic_expressions(
        [zero],
        [[[]]],
        [[[]]],
        [[[]]],
        [[[]]],
        [[black_box(1u32)]],
        [[false]],
    );
}

#[test]
fn batch_runtime_two_limb_power_of_two_modulus() {
    // For m=2^120 and MOD_BITS=121, Barrett parameter=floor(2^(2*121+6)/m)=2^128.
    let params = crate::params::BigNumParams::<2, 121>::new(false, [0, 1], [0, 1u128 << 8]);
    evaluate_quadratic_expressions_with_params(
        &params,
        &black_box([[3, 0], [9, 0]]),
        &[[[0]]],
        &[[[false]]],
        &[[[0]]],
        &[[[false]]],
        &[[1]],
        &[[true]],
    );
}

#[test]
fn batch_rebuilds_runtime_negation_metadata() {
    let mut params = BN254_Fq::params();
    params.double_modulus = black_box([0; 3]);
    evaluate_quadratic_expressions_with_params(
        &params,
        &black_box([[3, 0, 0], [9, 0, 0]]),
        &[[[0]]],
        &[[[false]]],
        &[[[0]]],
        &[[[false]]],
        &[[1]],
        &[[true]],
    );
}
