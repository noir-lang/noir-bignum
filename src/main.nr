mod bignum;
mod params;
mod fields;
mod utils;
mod fns;

use crate::bignum::BigNum;
use crate::bignum::BigNumTrait;
use crate::bignum::to_field;
use crate::utils::u60_representation::U60Repr;

use crate::params::BigNumParams;
use crate::params::BigNumParamsGetter;

use crate::fields::bls12_381Fq::BLS12_381_Fq_Params;
use crate::fields::bn254Fq::BN254_Fq_Params;
use crate::fields::U256::U256Params;

type Fq = BigNum<3, 254, BN254_Fq_Params>;

fn main(a: Fq, b: Fq) -> pub Fq {
    a + b
    // assert(result == expected);
}
