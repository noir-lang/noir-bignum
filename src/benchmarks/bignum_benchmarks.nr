use crate::utils::u60_representation::U60Repr;

use crate::bignum::BigNum;
use crate::bignum::BigNumTrait;

use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;

use crate::fields::bls12_381Fq::BLS12_381_Fq_Params;
use crate::fields::bn254Fq::BN254_Fq_Params;
use crate::fields::U256::U256Params;


// the types we will be benchmarking 

type Fq = BigNum<3, 254, BN254_Fq_Params>;
type BN256 = BigNum<3, 257, U256Params>;
type BN381 = BigNum<4, 381, BLS12_381_Fq_Params>;

// macro magic to generate the benchmarks
fn bench_add<let N: u32, BN>(a: BN, b: BN)
where
    BN: BigNumTrait,
{
    let c = a + b;
}

fn bench_sub<let N: u32, BN>(a: BN, b: BN)
where
    BN: BigNumTrait,
{
    let c = a - b;
}

fn bench_mul<let N: u32, BN>(a: BN, b: BN)
where
    BN: BigNumTrait,
{
    let c = a * b;
}

fn bench_div<let N: u32, BN>(a: BN, b: BN)
where
    BN: BigNumTrait,
{
    let c = a / b;
}


// type Fq
// type BN256
// type BN381
// type BN2048
#[export]
fn bench_add_Fq(a: Fq, b: Fq) {
    bench_add::<3, Fq>(a, b);
}

#[export]
fn bench_sub_Fq(a: Fq, b: Fq) {
    bench_sub::<3, Fq>(a, b);
}

#[export]
fn bench_mul_Fq(a: Fq, b: Fq) {
    bench_mul::<3, Fq>(a, b);
}

#[export]
fn bench_div_Fq(a: Fq, b: Fq) {
    bench_div::<3, Fq>(a, b);
}


#[export]
fn bench_add_BN256(a: BN256, b: BN256) {
    bench_add::<3, BN256>(a, b);
}

#[export]
fn bench_sub_BN256(a: BN256, b: BN256) {
    bench_sub::<3, BN256>(a, b);
}

#[export]
fn bench_mul_BN256(a: BN256, b: BN256) {
        bench_mul::<3, BN256>(a, b);
}

#[export]
fn bench_div_BN256(a: BN256, b: BN256) {
    bench_div::<3, BN256>(a, b);
}