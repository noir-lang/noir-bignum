//! Shared values for the modular equality tests.

use crate::constants::TWO_POW_120;
use crate::fields::bn254Fq::BN254_Fq_PARAMS;
use crate::params::BigNumParams;

/// Largest value of a non-top limb.
pub(crate) global LIMB_MAX: u128 = TWO_POW_120 - 1;

pub(crate) global BN254_MODULUS: [u128; 3] = BN254_Fq_PARAMS.modulus;

/// `MOD - 1`: the largest canonical BN254 Fq value.
pub(crate) global BN254_MODULUS_MINUS_ONE: [u128; 3] =
    [0x816a916871ca8d3c208c16d87cfd46, 0x4e72e131a029b85045b68181585d97, 0x3064];

/// `MOD + 1`: a lazy alias of one.
pub(crate) global BN254_MODULUS_PLUS_ONE: [u128; 3] =
    [0x816a916871ca8d3c208c16d87cfd48, 0x4e72e131a029b85045b68181585d97, 0x3064];

/// `2^254 - 1`: the largest value allowed by a BN254 Fq lazy-alias range check.
pub(crate) global BN254_LAZY_MAX: [u128; 3] = [LIMB_MAX, LIMB_MAX, 0x3fff];

/// `2 * MOD` with carries propagated: 120-bit lower limbs and a 15-bit top limb. It is
/// below `2^(MOD_BITS+1)` but above the `MOD_BITS`-bit range check, so it is built
/// without one.
pub(crate) global BN254_TWO_MODULUS: [u128; 3] =
    [0x2d522d0e3951a7841182db0f9fa8e, 0x9ce5c263405370a08b6d0302b0bb2f, 0x60c8];

/// Builds params without `BigNumParams::new`, so tests can exercise the in-circuit
/// modulus validation. `eq` does not read `double_modulus` or `redc_param`.
pub(crate) fn unchecked_params<let N: u32, let MOD_BITS: u32>(
    modulus: [u128; N],
) -> BigNumParams<N, MOD_BITS> {
    BigNumParams {
        has_multiplicative_inverse: false,
        modulus,
        double_modulus: [0; N],
        redc_param: [0; N],
    }
}
