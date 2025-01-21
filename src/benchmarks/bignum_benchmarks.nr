use crate::bignum::BigNum;

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
