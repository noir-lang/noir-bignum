use crate::utils::u60_representation::U60Repr;

use crate::bignum::BigNum;
use crate::bignum::BigNumTrait;

use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;

use crate::fields::bls12_381Fq::BLS12_381_Fq_Params;
use crate::fields::bn254Fq::BN254_Fq_Params;
use crate::fields::U256::U256Params;

struct Test2048Params {}

// See https://github.com/noir-lang/noir/issues/6172

type Fq = BigNum<3, 254, BN254_Fq_Params>;
type BN256 = BigNum<3, 257, U256Params>;
type BN381 = BigNum<4, 381, BLS12_381_Fq_Params>;
type BN2048 = BigNum<18, 2048, Test2048Params>;

#[export]
fn test_add_BN() {
    let mut a: Fq = BigNum::modulus();
    let mut b: Fq = BigNum::modulus();
    let mut expected: Fq = BigNum::modulus();

    a.limbs[0] -= 1;
    b.limbs[0] -= 1;
    expected.limbs[0] -= 2;

    let result = a + b;
    assert(result == expected);
}
