mod bn254Fq;
mod bls12381Fr;

use crate::BigNum;
use crate::fields::bn254Fq::BNParams;
use crate::fields::bls12381Fr::Bls12_381_Fr_Params;

// example typedef when using a defined bignum instance
type Fq = BigNum<3, BNParams>;
