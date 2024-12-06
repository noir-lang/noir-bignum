use core::fmt;

use ark_bn254::Fr;
use ark_ff::Field;
use ark_ff::Zero as ZeroField;
use num_bigint::BigUint;
use num_bigint::BigInt;
use num_bigint::ToBigInt;
use num_traits::{Zero, One};

pub(crate) fn sqrt(x: Fr) -> Option<Fr> {
    let sqrt: Option<Fr> = if x.legendre().is_qr() {
        let sqrt = x.sqrt().unwrap();
        assert_eq!(sqrt.square(), x);

        Some(sqrt)
    } else {
        assert_eq!(x.sqrt(), None);

        None
    };

    if sqrt == None {
        // I can't be bothered figuring out how to serialise an `Option::None` back to Noir-land, so I'm panicking in this case, instead.
        panic!("NO SQUARE ROOT EXISTS");
    }

    sqrt
}

pub(crate) fn is_zero(limbs: Vec<Fr>) -> bool {
    let mut result: bool = true;
    for limb in limbs {
        result = result & (limb == ZeroField::zero());
    }
    result
}



pub(crate) fn extended_gcd(_a: &BigInt, _b: &BigInt) -> (BigInt, BigInt, BigInt) {
    let (mut x, mut y) = (BigInt::from(0), BigInt::from(1));
    let (mut u, mut v) = (BigInt::from(1), BigInt::from(0));
    let mut a = _a.clone();
    let mut b = _b.clone();
    while a != BigInt::from(0) {
        let q = &b / &a;
        let r = &b % &a;
        let m = &x - &u * &q;
        let n = &y - &v * &q;
        b = a.clone(); 
        a = r;
        x = u;
        y = v;
        u = m;
        v = n;
    }
    (b.clone(), x.clone(), y.clone())
}


pub(crate) fn invert(a: &BigUint , modulus: &BigUint) -> BigInt {
    // perform a -> BigInt conversion
    let a_bigint = BigInt::from(a.clone());
    let modulus_bigint = BigInt::from(modulus.clone());
    let (gcd , r, _) = extended_gcd(&a_bigint, &modulus_bigint);
    assert_eq!(gcd, BigInt::from(1), "input and modulus are not coprime");
    let mut res = r.clone();
    while res < BigInt::from(0) {
        res = res + &modulus_bigint;
    }
    res
}


pub (crate) fn pow_bn(base: &BigUint, exponent: &BigUint, modulus: &BigUint) -> BigUint {
    // cast the exponent into bytes 
    let exponent_bytes = exponent.to_bytes_be();
    // do a square and multiply type algorithm 
    let mut result = BigUint::from(1u64); 
    for exponent_byte in exponent_bytes {
        // this will be potentially horribly slow 
        result = result.pow(256);
        result = result % modulus;
        result = result * base.pow(exponent_byte as u32);
        result = result % modulus;
    }
    result
}


pub(crate) fn batch_invert(xs: &Vec<BigUint>, modulus: &BigUint) -> Vec<BigInt> {
    // start with an array with 1 at position 0 
    let mut intermediates: Vec<BigUint> = vec![BigUint::from(1u32)];
    let m = xs.len(); 
    let mut temp: BigUint =  BigUint::from(1u64); 
    for i in 0..m {
        // the intermediates array will hold the multiplication of the first i elements in position i 
        temp = (&temp * &xs[i])% modulus ; 
        intermediates.push(temp.clone()); 
    }
    
    // invert the final multiplication 
    let mut mul_inv = invert(&intermediates[m], modulus); 
    // set up a vector of responses that will hold the results 
    let mut inverses: Vec<BigInt> = vec![BigInt::zero() ; m]; 
    // loop over m and compute the inverses 
    for i in 0..m {
        inverses[m-i-1] = (&mul_inv * &BigInt::from(intermediates[m-i-1].clone()))% BigInt::from(modulus.clone()); 
        mul_inv = &mul_inv * &BigInt::from(xs[m-i-1].clone());    
    }

    assert_eq!((BigInt::from(xs[0].clone()) * &inverses[0]) % BigInt::from(modulus.clone()) , BigInt::from(1u32)); 
    inverses
}



// some tests to check the behaviour of the extended gcd
#[test]
fn test_extended_euclidean() {
    let (s, r, t) = extended_gcd(&mut BigInt::from(10u64), &mut BigInt::from(6u64));
    assert_eq!(s, BigInt::from(2u64));
}

#[test]
fn test_invert() {
    let a = BigUint::from(5u64);
    let modulus = BigUint::from(6u64);
    let r = invert(&a, &modulus);
    let modulus_bigint = BigInt::from(modulus.clone());
    let a_bigint = BigInt::from(a.clone());
    assert_eq!((r * a_bigint) % modulus_bigint , BigInt::from(1u64));
}


#[test]
fn test_pow_bn() {
    let base = BigUint::from(3u64);
    let exponent = BigUint::from(10u64);
    let modulus = BigUint::from(1000000000u64);
    let result = pow_bn(&base, &exponent, &modulus);
    assert_eq!(result, BigUint::from(59049u64));
}

// #[test]
// #[should_panic(expected = "input and modulus are no coprime")]
// fn test_invert_fail() {
//     let a = BigUint::from(4u64);
//     let modulus = BigUint::from(8u64);
//     invert(&a, &modulus);
// }

