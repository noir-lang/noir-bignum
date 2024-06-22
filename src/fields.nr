mod bn254Fq;

use crate::BigNum;
use crate::fields::bn254Fq::BNParams;

// example typedef when using a defined bignum instance
type Fq = BigNum<3, BNParams>;
