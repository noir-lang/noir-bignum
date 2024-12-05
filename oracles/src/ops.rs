use ark_bn254::Fr;
use ark_ff::Field;
use ark_ff::Zero as ZeroField;
use num_bigint::BigUint;
use num_bigint::BigInt;
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

// #[test]
// #[should_panic(expected = "input and modulus are no coprime")]
// fn test_invert_fail() {
//     let a = BigUint::from(4u64);
//     let modulus = BigUint::from(8u64);
//     invert(&a, &modulus);
// }

