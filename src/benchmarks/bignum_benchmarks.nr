use crate::bignum::BigNum;
use crate::bignum::BigNumTrait;

use crate::fields::bn254Fq::BN254_Fq_Params;
use crate::fields::U256::U256Params;

// the types we will be benchmarking

type Fq = BigNum<3, 254, BN254_Fq_Params>;
type BN256 = BigNum<3, 257, U256Params>;

// type Fq
// type BN256
// type BN381
// type BN2048
#[export]
fn bench_add_Fq(a: Fq, b: Fq) -> Fq {
    a + b
}

#[export]
fn bench_sub_Fq(a: Fq, b: Fq) -> Fq {
    a - b
}

#[export]
fn bench_mul_Fq(a: Fq, b: Fq) -> Fq {
    a * b
}

#[export]
fn bench_div_Fq(a: Fq, b: Fq) -> Fq {
    a / b
}

#[export]
fn bench_add_BN256(a: BN256, b: BN256) -> BN256 {
    a + b
}

#[export]
fn bench_sub_BN256(a: BN256, b: BN256) -> BN256 {
    a - b
}

#[export]
fn bench_mul_BN256(a: BN256, b: BN256) -> BN256 {
    a * b
}

#[export]
fn bench_div_BN256(a: BN256, b: BN256) -> BN256 {
    a / b
}

#[export]
fn bench_from_field_Fq(a: Field) -> Fq {
    Fq::from(a)
}

#[export]
fn bench_from_field_BN256(a: Field) -> BN256 {
    BN256::from(a)
}

// #[export]
// fn bench_cmp_Fq(a: Fq, b: Fq) -> bool {
//     a > b
// }

#[export]
fn bench_udiv_mod_Fq(a: Fq, b: Fq) -> (Fq, Fq) {
    a.udiv_mod(b)
}

#[export]
fn bench_udiv_mod_BN256(a: BN256, b: BN256) -> (BN256, BN256) {
    a.udiv_mod(b)
}

#[export]
fn bench_udiv_Fq(a: Fq, b: Fq) -> Fq {
    a.udiv(b)
}

#[export]
fn bench_udiv_BN256(a: BN256, b: BN256) -> BN256 {
    a.udiv(b)
}

#[export]
fn bench_evaluate_quadratic_expression_3_elements(
    lhs: [[Fq; 3]; 3],
    lhs_flags: [[bool; 3]; 3],
    rhs: [[Fq; 3]; 3],
    rhs_flags: [[bool; 3]; 3],
    add: [Fq; 3],
    add_flags: [bool; 3],
) {
    Fq::evaluate_quadratic_expression(lhs, lhs_flags, rhs, rhs_flags, add, add_flags)
}

#[export]
fn bench_compute_quadratic_expression_12_elemepts(
    lhs: [[Fq; 3]; 12],
    lhs_flags: [[bool; 3]; 12],
    rhs: [[Fq; 3]; 12],
    rhs_flags: [[bool; 3]; 12],
    add: [Fq; 3],
    add_flags: [bool; 3],
) {
    Fq::evaluate_quadratic_expression(lhs, lhs_flags, rhs, rhs_flags, add, add_flags)
}

#[export]
fn bench_validate_in_field_Fq(a: Fq) {
    a.validate_in_field()
}

#[export]
fn bench_validate_in_field_BN256(a: BN256) {
    a.validate_in_field()
}
