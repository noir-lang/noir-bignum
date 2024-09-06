mod custom_params;

use custom_params::RSA2048_example_Params;
use dep::bignum::BigNum;

type RSA2048 = BigNum<18, RSA2048_example_Params>;

fn main(a: RSA2048, b: RSA2048, expected: RSA2048) {
    let c = a + b;
    assert(c == expected);
}

#[test]

fn test_main() {
    let mut a: RSA2048 = BigNum::new();
    a.limbs[0] = 10;
    let mut b: RSA2048 = BigNum::new();
    b.limbs[0] = 20;

    let mut expected: RSA2048 = BigNum::new();
    expected.limbs[0] = 30;

    main(a, b, expected);
}
