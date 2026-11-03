use crate::bignum::BigNum;
use crate::constants::{GRUMPKIN_MODULUS, TWO_POW_120};
use crate::fns::constrained_ops::eq;
use crate::tests::eq_fixtures::{
    BN254_LAZY_MAX, BN254_MODULUS, BN254_MODULUS_MINUS_ONE, BN254_MODULUS_PLUS_ONE, LIMB_MAX,
    unchecked_params,
};

use crate::fields::bls12_381Fq::{BLS12_381_Fq, BLS12_381_Fq_PARAMS};
use crate::fields::bn254Fq::{BN254_Fq, BN254_Fq_PARAMS};

use std::hint::black_box;

#[test]
fn test_eq_zero() {
    let a = black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0]));
    let b = black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0]));
    assert_eq(a, b);
    assert_eq(b, a);
}

#[test]
fn test_eq_lazy_alias() {
    let a = black_box(BN254_Fq::from_limbs([0x1, 0x0, 0x0]));
    let b = black_box(BN254_Fq::from_limbs(BN254_MODULUS_PLUS_ONE));
    assert_eq(a, b);
    assert_eq(b, a);
}

#[test]
fn test_eq_zero_modulus() {
    let a = black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0]));
    let b = black_box(BN254_Fq::from_limbs(BN254_MODULUS));
    assert_eq(a, b);
    assert_eq(b, a);
}

#[test]
fn test_eq_boundary() {
    let a = black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0]));
    let b = black_box(BN254_Fq::from_limbs(BN254_LAZY_MAX));
    assert(a != b);
    assert(b != a);
}

#[test]
fn test_eq_lazy_distinct() {
    let a = black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0]));
    let b = black_box(BN254_Fq::from_limbs(BN254_MODULUS_PLUS_ONE));
    assert(a != b);
    assert(b != a);
}

#[test]
fn test_eq_native_alias() {
    let a = black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0]));
    let b = black_box(BN254_Fq::from_limbs(GRUMPKIN_MODULUS));
    assert(a != b);
    assert(b != a);
}

#[test]
fn test_eq_low_carry() {
    let a = black_box(BN254_Fq::from_limbs([LIMB_MAX, 0x0, 0x0]));
    let b = black_box(BN254_Fq::from_limbs([0x0, 0x1, 0x0]));
    assert(a != b);
    assert(b != a);
}

#[test]
fn test_eq_canonical_max() {
    let a = black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0]));
    let b = black_box(BN254_Fq::from_limbs(BN254_MODULUS_MINUS_ONE));
    assert(a != b);
    assert(b != a);
}

#[test]
fn test_eq_two_limb_carry() {
    let a = black_box(BN254_Fq::from_limbs([LIMB_MAX, LIMB_MAX, 0x0]));
    let b = black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x1]));
    assert(a != b);
    assert(b != a);
}

#[test(should_fail)]
fn test_eq_wrong_flag_rejects() {
    assert(
        black_box(BN254_Fq::from_limbs([0x0, 0x0, 0x0]))
            == black_box(BN254_Fq::from_limbs([0x1, 0x0, 0x0])),
    );
}

#[test(should_fail)]
fn test_eq_oversized_low_limb_rejects() {
    let invalid = black_box([0x1000000000000000000000000000000u128, 0, 0]);
    assert(eq(&BN254_Fq_PARAMS, &invalid, &black_box([0, 1, 0])));
}
#[test(should_fail)]
fn test_eq_oversized_middle_limb_rejects() {
    let invalid = black_box([0u128, 0x1000000000000000000000000000000, 0]);
    assert(eq(&BN254_Fq_PARAMS, &invalid, &black_box([0, 0, 1])));
}
#[test(should_fail)]
fn test_eq_oversized_top_limb_rejects() {
    let invalid = black_box([0u128, 0, 0x8000]);
    assert(eq(&BN254_Fq_PARAMS, &invalid, &invalid));
}

#[test]
fn test_eq_normalized_241_bit_modulus() {
    let params = unchecked_params::<3, 241>([0x1, 0x0, 0x1]);
    let a = black_box([0x0, 0x0, 0x0]);
    let b = black_box([0x1, 0x0, 0x1]);
    assert(eq(&params, &a, &b));
    assert(eq(&params, &b, &a));
    let a = black_box([0x1, 0x0, 0x0]);
    let b = black_box([0x2, 0x0, 0x1]);
    assert(eq(&params, &a, &b));
    assert(eq(&params, &b, &a));
    let a = black_box([0x0, 0x0, 0x0]);
    let b = black_box([LIMB_MAX, LIMB_MAX, 0x1]);
    assert(!eq(&params, &a, &b));
    assert(!eq(&params, &b, &a));
    let a = black_box([0x0, 0x0, 0x1]);
    let b = black_box([0x1, 0x0, 0x1]);
    assert(!eq(&params, &a, &b));
    assert(!eq(&params, &b, &a));
    let a = black_box([LIMB_MAX, LIMB_MAX, 0x0]);
    let b = black_box([0x0, 0x0, 0x1]);
    assert(!eq(&params, &a, &b));
    assert(!eq(&params, &b, &a));
}

#[test]
fn test_eq_quotient_extremes() {
    // MOD = 2^240 + 1 is barely normalized, so the envelope 2^242 reaches
    // almost 4*MOD and the honest quotient attains both extremes: 4 vs
    // 3*MOD + 5 needs k = -4 (borrowing a modulus for the residue MOD - 1)
    // and k = +3 in the swapped direction.
    let params = unchecked_params::<3, 241>([0x1, 0x0, 0x1]);
    let a = black_box([0x4, 0x0, 0x0]);
    let b = black_box([0x8, 0x0, 0x3]);
    assert(!eq(&params, &a, &b));
    assert(!eq(&params, &b, &a));
    // Same alias magnitude, equal values: 5 vs 3*MOD + 5 (k = -3 / +3).
    let a = black_box([0x5, 0x0, 0x0]);
    assert(eq(&params, &a, &b));
    assert(eq(&params, &b, &a));
}

#[test]
fn test_eq_normalized_256_bit_modulus() {
    let params = unchecked_params::<3, 256>([0xffffffffffffffffffffffffffff43, LIMB_MAX, 0xffff]);
    let a = black_box([0x0, 0x0, 0x0]);
    let b = black_box([0xffffffffffffffffffffffffffff43, LIMB_MAX, 0xffff]);
    assert(eq(&params, &a, &b));
    assert(eq(&params, &b, &a));
    let a = black_box([0x1, 0x0, 0x0]);
    let b = black_box([0xffffffffffffffffffffffffffff44, LIMB_MAX, 0xffff]);
    assert(eq(&params, &a, &b));
    assert(eq(&params, &b, &a));
    let a = black_box([0x0, 0x0, 0x0]);
    let b = black_box([LIMB_MAX, LIMB_MAX, 0xffff]);
    assert(!eq(&params, &a, &b));
    assert(!eq(&params, &b, &a));
    let a = black_box([0xffffffffffffffffffffffffffff42, LIMB_MAX, 0xffff]);
    let b = black_box([0xffffffffffffffffffffffffffff43, LIMB_MAX, 0xffff]);
    assert(!eq(&params, &a, &b));
    assert(!eq(&params, &b, &a));
    let a = black_box([LIMB_MAX, LIMB_MAX, 0x0]);
    let b = black_box([0x0, 0x0, 0x1]);
    assert(!eq(&params, &a, &b));
    assert(!eq(&params, &b, &a));
}

#[test]
fn test_eq_normalized_360_bit_modulus() {
    let params = unchecked_params::<3, 360>([0x11, 0x0, 0x800000000000000000000000000000]);
    let a = black_box([0x0, 0x0, 0x0]);
    let b = black_box([0x11, 0x0, 0x800000000000000000000000000000]);
    assert(eq(&params, &a, &b));
    assert(eq(&params, &b, &a));
    let a = black_box([0x1, 0x0, 0x0]);
    let b = black_box([0x12, 0x0, 0x800000000000000000000000000000]);
    assert(eq(&params, &a, &b));
    assert(eq(&params, &b, &a));
    let a = black_box([0x0, 0x0, 0x0]);
    let b = black_box([LIMB_MAX, LIMB_MAX, LIMB_MAX]);
    assert(!eq(&params, &a, &b));
    assert(!eq(&params, &b, &a));
    let a = black_box([0x10, 0x0, 0x800000000000000000000000000000]);
    let b = black_box([0x11, 0x0, 0x800000000000000000000000000000]);
    assert(!eq(&params, &a, &b));
    assert(!eq(&params, &b, &a));
    let a = black_box([LIMB_MAX, LIMB_MAX, 0x0]);
    let b = black_box([0x0, 0x0, 0x1]);
    assert(!eq(&params, &a, &b));
    assert(!eq(&params, &b, &a));
}

#[test]
fn test_eq_wider_lazy_alias() {
    let a = black_box(BN254_MODULUS_MINUS_ONE);
    let b = black_box(
        [0x2d522d0e3951a7841182db0f9fa8d, 0x9ce5c263405370a08b6d0302b0bb2f, 0x60c8],
    );
    assert(eq(&BN254_Fq_PARAMS, &a, &b));
    assert(eq(&BN254_Fq_PARAMS, &b, &a));
}

#[test]
fn test_eq_wider_multiple_aliases() {
    let params = unchecked_params::<3, 241>([0x11, 0x0, 0x1]);
    let a = black_box([0xffffffffffffffffffffffffffffc4, LIMB_MAX, 0x0]);
    let b = black_box([0xffffffffffffffffffffffffffffd5, LIMB_MAX, 0x1]);
    assert(eq(&params, &a, &b));
    assert(eq(&params, &b, &a));
    let a = black_box([0xffffffffffffffffffffffffffffc4, LIMB_MAX, 0x0]);
    let b = black_box([0xffffffffffffffffffffffffffffe6, LIMB_MAX, 0x2]);
    assert(eq(&params, &a, &b));
    assert(eq(&params, &b, &a));
    let a = black_box([0xffffffffffffffffffffffffffffc4, LIMB_MAX, 0x0]);
    let b = black_box([0xfffffffffffffffffffffffffffff7, LIMB_MAX, 0x3]);
    assert(eq(&params, &a, &b));
    assert(eq(&params, &b, &a));
    assert(
        !eq(
            &params,
            &black_box([0x0, 0x0, 0x0]),
            &black_box([LIMB_MAX, LIMB_MAX, 0x3]),
        ),
    );
}

#[test(should_fail)]
fn test_eq_short_runtime_modulus_rejects() {
    let mut params = BN254_Fq_PARAMS;
    params.modulus = black_box([1u128, 0, 1]);
    assert(eq(&params, &black_box([0; 3]), &black_box([0; 3])));
}
#[test(should_fail)]
fn test_eq_oversized_runtime_modulus_limb_rejects() {
    let mut params = BN254_Fq_PARAMS;
    params.modulus[0] = black_box(0x1000000000000000000000000000000);
    assert(eq(&params, &black_box([0; 3]), &black_box([0; 3])));
}

// A normalized power-of-two modulus isolates equality from inversion or primality.
fn wide_alias_controls<let N: u32, let Bits: u32>(modulus: [u128; N]) {
    let params = unchecked_params::<N, Bits>(black_box(modulus));
    let zero = black_box([0; N]);
    let mut one = [0; N];
    one[0] = 1;
    let mut q_plus_one = modulus;
    q_plus_one[0] += 1;
    let mut two_q = [0; N];
    let mut three_q = [0; N];
    for i in 0..N {
        two_q[i] = 2 * modulus[i];
        three_q[i] = 3 * modulus[i];
    }
    for alias in [modulus, two_q, three_q] {
        assert(eq(&params, &zero, &black_box(alias)));
        assert(eq(&params, &black_box(alias), &zero));
        assert(!eq(&params, &one, &black_box(alias)));
        assert(!eq(&params, &black_box(alias), &one));
    }
    assert(eq(&params, &one, &black_box(q_plus_one)));
    assert(eq(&params, &black_box(q_plus_one), &one));
}
#[test]
fn test_eq_one_limb_aliases() {
    wide_alias_controls::<1, 8>([128]);
}
#[test]
fn test_eq_two_limb_aliases() {
    wide_alias_controls::<2, 121>([0, 1]);
}
#[test]
fn test_eq_four_limb_aliases() {
    wide_alias_controls::<4, 361>([0, 0, 0, 1]);
}
#[test]
fn test_eq_seven_limb_aliases() {
    wide_alias_controls::<7, 721>([0, 0, 0, 0, 0, 0, 1]);
}

#[test]
fn test_eq_generic_native_field_alias() {
    let alias = BLS12_381_Fq::from_limbs([
        GRUMPKIN_MODULUS[0],
        GRUMPKIN_MODULUS[1],
        GRUMPKIN_MODULUS[2],
        0,
    ]);
    alias.validate_in_field();
    let zero = BLS12_381_Fq::zero();
    assert(black_box(alias) != black_box(zero));
    assert(black_box(zero) != black_box(alias));
}

#[test]
fn test_eq_generic_full_top_carry() {
    let radix = TWO_POW_120;
    let params = unchecked_params::<2, 240>(black_box([radix - 1; 2]));
    let alias = black_box([radix - 2, 2 * radix - 1]);
    let neighbor = black_box([radix - 1, 2 * radix - 1]);
    let zero = black_box([0; 2]);
    assert(eq(&params, &alias, &zero));
    assert(eq(&params, &zero, &alias));
    assert(!eq(&params, &neighbor, &zero));
    assert(!eq(&params, &zero, &neighbor));
}
#[test(should_fail)]
fn test_eq_generic_bad_modulus() {
    let params = unchecked_params::<4, 381>(black_box([0, 0, 0, 1]));
    assert(!eq(&params, &black_box([1, 0, 0, 0]), &black_box([0; 4])));
}
#[test(should_fail)]
fn test_eq_generic_bad_low_limb() {
    let params = BLS12_381_Fq_PARAMS;
    assert(
        !eq(
            &params,
            &black_box([1u128 << 120, 0, 0, 0]),
            &black_box([0; 4]),
        ),
    );
}
#[test(should_fail)]
fn test_eq_generic_bad_top_limb() {
    let params = BLS12_381_Fq_PARAMS;
    assert(
        !eq(
            &params,
            &black_box([0, 0, 0, 1u128 << 22]),
            &black_box([0; 4]),
        ),
    );
}
