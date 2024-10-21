use dep::bignum::fields::ed25519Fq::ED25519_Fq_Params;
use dep::bignum::runtime_bignum::BigNumInstance;
use dep::bignum::BigNum;

// Prime field mod 2^255-19
type Ed25519Fq = BigNum<3, ED25519_Fq_Params>;

// Check that `a * b + (c + d) * e + f` equals `expected`
// (this constrains `a * b + (c + d) * e + f - expected = 0`)
fn main(
    a: Ed25519Fq,
    b: Ed25519Fq,
    c: Ed25519Fq,
    d: Ed25519Fq,
    e: Ed25519Fq,
    f: Ed25519Fq,
    expected: Ed25519Fq
) {
    // Step 1: calculate g = a * b + (c + d) * e + f in unconstrained functions 
    // First product term a * b
    let t0 = a.__mul(b);
    // Second product term (c + d) * e
    let t1 = (c.__add(d)).__mul(e);
    let g = t0.__add(t1).__add(f);

    // Step 2: 
    // product term 1 a * b. Rewrite to (a + 0) * b
    // product term 2 (c + d) * e 
    // linear terms f, g
    BigNum::evaluate_quadratic_expression(
        [[a, BigNum::new()], [c, d]],
        [[false, false], [false, false]],
        [[b], [e]],
        [[false], [false]],
        [f, g],
        [false, true]
    );

    // Step 3: check res equals `expected`
    assert(g == expected);
}

// Simple test
#[test]
fn test_main() {
    // a=1, b=2, c=3, d=4, e=5, f=6
    let a: Ed25519Fq = BigNum::from_array([1, 0, 0]);
    let b: Ed25519Fq = BigNum::from_array([2, 0, 0]);
    let c: Ed25519Fq = BigNum::from_array([3, 0, 0]);
    let d: Ed25519Fq = BigNum::from_array([4, 0, 0]);
    let e: Ed25519Fq = BigNum::from_array([5, 0, 0]);
    let f: Ed25519Fq = BigNum::from_array([6, 0, 0]);
    // 1*2 + (3+4) * 5 + 6 = 43
    let expected: Ed25519Fq = BigNum::from_array([43, 0, 0]);

    main(a, b, c, d, e, f, expected);
}
