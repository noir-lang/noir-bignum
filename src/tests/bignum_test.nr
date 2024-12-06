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
#[test]
fn silence_warning() {
    let _ = Test2048Params {};
}

global TEST_2048_PARAMS: BigNumParams<18, 2048> = BigNumParams {
    has_multiplicative_inverse: false,
    modulus: [
        0xc0a197a5ae0fcdceb052c9732614fe,
        0x656ae034423283422243918ab83be3,
        0x6bf590da48a7c1070b7d5aabaac678,
        0x0cce39f530238b606f24b296e2bda9,
        0x01e1fef9bb9c1c3ead98f226f1bfa0,
        0xad8c1c816e12e0ed1379055e373abf,
        0xcebe80e474f753aa9d1461c435123d,
        0xaee5a18ceedef88d115a8b93c167ad,
        0x268ba83c4a65c4307427fc495d9e44,
        0xdd2777926848667b7df79f342639d4,
        0xf455074c96855ca0068668efe7da3d,
        0x5ddba6b30bbc168bfb3a1225f27d65,
        0x591fec484f36707524133bcd6f4258,
        0x59641b756766aeebe66781dd01d062,
        0x58bc5eaff4b165e142bf9e2480eebb,
        0x667a3964f08e06df772ce64b229a72,
        0x9c1fdb18907711bfe3e3c1cf918395,
        0xb8,
    ],
    double_modulus: [
        0x0181432f4b5c1f9b9d60a592e64c29fc,
        0x01cad5c06884650684448723157077c6,
        0x01d7eb21b4914f820e16fab557558cef,
        0x01199c73ea604716c0de49652dc57b51,
        0x0103c3fdf37738387d5b31e44de37f3f,
        0x015b183902dc25c1da26f20abc6e757d,
        0x019d7d01c8e9eea7553a28c3886a247a,
        0x015dcb4319ddbdf11a22b5172782cf5a,
        0x014d17507894cb8860e84ff892bb3c88,
        0x01ba4eef24d090ccf6fbef3e684c73a7,
        0x01e8aa0e992d0ab9400d0cd1dfcfb47a,
        0x01bbb74d6617782d17f674244be4faca,
        0x01b23fd8909e6ce0ea4826779ade84af,
        0x01b2c836eacecd5dd7cccf03ba03a0c3,
        0x01b178bd5fe962cbc2857f3c4901dd75,
        0x01ccf472c9e11c0dbeee59cc964534e3,
        0x01383fb63120ee237fc7c7839f230729,
        0x0170,
    ],
    modulus_u60: U60Repr {
        limbs: [
            0x0eb052c9732614fe,
            0x0c0a197a5ae0fcdc,
            0x022243918ab83be3,
            0x0656ae0344232834,
            0x070b7d5aabaac678,
            0x06bf590da48a7c10,
            0x6f24b296e2bda9,
            0xcce39f530238b6,
            0x0ead98f226f1bfa0,
            0x1e1fef9bb9c1c3,
            0x0d1379055e373abf,
            0x0ad8c1c816e12e0e,
            0x0a9d1461c435123d,
            0x0cebe80e474f753a,
            0x0d115a8b93c167ad,
            0x0aee5a18ceedef88,
            0x7427fc495d9e44,
            0x0268ba83c4a65c43,
            0x0b7df79f342639d4,
            0x0dd2777926848667,
            0x068668efe7da3d,
            0x0f455074c96855ca,
            0x0bfb3a1225f27d65,
            0x05ddba6b30bbc168,
            0x0524133bcd6f4258,
            0x0591fec484f36707,
            0x0be66781dd01d062,
            0x059641b756766aee,
            0x0142bf9e2480eebb,
            0x058bc5eaff4b165e,
            0x0f772ce64b229a72,
            0x0667a3964f08e06d,
            0x0fe3e3c1cf918395,
            0x09c1fdb18907711b,
            0xb8,
            0x00,
        ],
    },
    modulus_u60_x4: U60Repr {
        limbs: [
            0x0eb052c9732614fe,
            0x0c0a197a5ae0fcdc,
            0x022243918ab83be3,
            0x0656ae0344232834,
            0x070b7d5aabaac678,
            0x06bf590da48a7c10,
            0x6f24b296e2bda9,
            0xcce39f530238b6,
            0x0ead98f226f1bfa0,
            0x1e1fef9bb9c1c3,
            0x0d1379055e373abf,
            0x0ad8c1c816e12e0e,
            0x0a9d1461c435123d,
            0x0cebe80e474f753a,
            0x0d115a8b93c167ad,
            0x0aee5a18ceedef88,
            0x7427fc495d9e44,
            0x0268ba83c4a65c43,
            0x0b7df79f342639d4,
            0x0dd2777926848667,
            0x068668efe7da3d,
            0x0f455074c96855ca,
            0x0bfb3a1225f27d65,
            0x05ddba6b30bbc168,
            0x0524133bcd6f4258,
            0x0591fec484f36707,
            0x0be66781dd01d062,
            0x059641b756766aee,
            0x0142bf9e2480eebb,
            0x058bc5eaff4b165e,
            0x0f772ce64b229a72,
            0x0667a3964f08e06d,
            0x0fe3e3c1cf918395,
            0x09c1fdb18907711b,
            0xb8,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
        ],
    },
    redc_param: [
        0x1697def7100cd5cf8d890b4ef2ec3f,
        0x765ba8304214dac764d3f4adc31859,
        0x8404bd14d927ea230e60d4bebf9406,
        0xc4d53a23bacc251ecbfc4b7ba5a0b4,
        0x3eaf3499474a6f5b2fff83f1259c87,
        0xbff4c737b97281f1a5f2384a8c16d9,
        0x1b4cf2f55358476b53237829990555,
        0xe7a804e8eacfe3a2a5673bc3885b86,
        0xabadeae4282906c817adf70eab4ae1,
        0x66f7df257fe2bf27f0809aceed9b0e,
        0xd90fb7428901b8bed11f6b81e36bf1,
        0x36e6ba885c60b7024c563605df7e07,
        0x2b7c58d2fb5d2c8478963ae6d4a44f,
        0x6ee761de26635f114ccc3f7d74f855,
        0x3fb726a10cf2220897513f05243de3,
        0x43a26bbd732496eb4d828591b8056e,
        0xf4e42304e60fb3a54fca735499f2cf,
        0x162f,
    ],
};

impl BigNumParamsGetter<18, 2048> for Test2048Params {
    fn get_params() -> BigNumParams<18, 2048> {
        TEST_2048_PARAMS
    }
}

type Fq = BigNum<3, 254, BN254_Fq_Params>;
type BN256 = BigNum<3, 257, U256Params>;
type BN381 = BigNum<4, 381, BLS12_381_Fq_Params>;
type BN2048 = BigNum<18, 2048, Test2048Params>;

/**
 * @brief this example was failing - sanity test to validate it now works
 **/
#[test]
fn test_bls_reduction() {
    let X1: BN381 = BigNum {
        limbs: [
            0x55e83ff97a1aeffb3af00adb22c6bb,
            0x8c4f9774b905a14e3a3f171bac586c,
            0xa73197d7942695638c4fa9ac0fc368,
            0x17f1d3,
        ],
    };
    X1.validate_in_field();
    let mut (_, XX_mul_3): (BN381, BN381) = unsafe {
        BigNum::__compute_quadratic_expression(
            [[X1, X1, X1]],
            [[false, false, false]],
            [[X1]],
            [[false]],
            [],
            [],
        )
    };
    XX_mul_3.validate_in_field();
}

fn test_eq<let N: u32, BN>()
where
    BN: BigNumTrait,
{
    let a = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };
    let b = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };
    let c = unsafe { BN::__derive_from_seed([2, 2, 3, 4]) };

    let modulus = BN::modulus();
    let t0: U60Repr<N, 2> = (U60Repr::from(modulus.get_limbs_slice().as_array()));
    let t1: U60Repr<N, 2> = (U60Repr::from(b.get_limbs_slice().as_array()));
    let b_plus_modulus = BN::from_slice(U60Repr::into(t0 + t1));
    assert(a.eq(b) == true);
    assert(a.eq(b_plus_modulus) == true);
    assert(c.eq(b) == false);
    assert(c.eq(a) == false);
}

// fn test_eq<let N: u32, Params>(_: BigNum<N, Params>) where Params: BigNumParamsGetter<N> + RuntimeBigNumParamsTrait<N> {
//     let a = BigNum::__derive_from_seed([1, 2, 3, 4]);
//     let b = BigNum::__derive_from_seed([1, 2, 3, 4]);
//     let c = BigNum::__derive_from_seed([2, 2, 3, 4]);

//     let modulus: BigNum<N, Params> = Params::get_params().modulus();
//     let t0: U60Repr<N, 2> = (U60Repr::from(modulus.limbs));
//     let t1: U60Repr<N, 2> = (U60Repr::from(b.limbs));
//     let b_plus_modulus: BigNum<N, Params> = BigNum { limbs: U60Repr::into(t0 + t1) };

//     assert(a.eq(b) == true);
//     assert(a.eq(b_plus_modulus) == true);
//     assert(c.eq(b) == false);
//     assert(c.eq(a) == false);
// }

// // // 98760
// // // 99689
// // // 929 gates for a 2048 bit mul
fn test_mul<let N: u32, BN>()
where
    BN: BigNumTrait + std::ops::Mul + std::ops::Add,
{
    let a: BN = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };
    let b: BN = unsafe { BN::__derive_from_seed([4, 5, 6, 7]) };

    let c = (a + b) * (a + b);
    let d = (a * a) + (b * b) + (a * b) + (a * b);
    assert(c.eq(d));
}

fn test_add<let N: u32, BN>()
where
    BN: BigNumTrait + std::ops::Add + std::ops::Mul + std::cmp::Eq,
{
    let a = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };
    let b: BN = unsafe { BN::__derive_from_seed([4, 5, 6, 7]) };
    let one = BN::one();
    a.validate_in_range();
    a.validate_in_field();
    b.validate_in_range();
    b.validate_in_field();
    let mut c = (a + b);
    c += c;
    let d = (a + b) * (one + one);
    assert(c == (d));
    let e = one + one;
    let limbs: [Field; N] = e.get_limbs_slice().as_array();
    let mut first: bool = true;
    for limb in limbs {
        if first {
            first = false;
            assert(limb == 2);
        } else {
            assert(limb == 0);
        }
    }
}

fn test_div<let N: u32, BN>()
where
    BN: BigNumTrait + std::ops::Div + std::ops::Mul + std::ops::Add + std::cmp::Eq,
{
    let a = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };
    let b = unsafe { BN::__derive_from_seed([4, 5, 6, 7]) };

    let c = a / b;
    assert((b * c) == (a));
}

fn test_invmod<let N: u32, BN>()
where
    BN: BigNumTrait + std::cmp::Eq,
{
    let u = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };
    for _ in 0..1 {
        let v = unsafe { u.__invmod() };
        let result = unsafe { u.__mul(v) };
        let expected = BN::one();
        assert(result == expected);
    }
}

fn assert_is_not_equal<let N: u32, BN>()
where
    BN: BigNumTrait,
{
    let a = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };
    let b = unsafe { BN::__derive_from_seed([4, 5, 6, 7]) };

    a.assert_is_not_equal(b);
}

fn assert_is_not_equal_fail<let N: u32, BN>()
where
    BN: BigNumTrait,
{
    let a = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };
    let b = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };

    a.assert_is_not_equal(b);
}

fn assert_is_not_equal_overloaded_lhs_fail<let N: u32, BN>()
where
    BN: BigNumTrait,
{
    let a = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };
    let b = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };

    let modulus = BN::modulus();

    let t0: U60Repr<N, 2> = U60Repr::from(a.get_limbs_slice().as_array());
    let t1: U60Repr<N, 2> = U60Repr::from(modulus.get_limbs_slice().as_array());
    let a_plus_modulus = BN::from_slice(U60Repr::into(t0 + t1));
    a_plus_modulus.assert_is_not_equal(b);
}

fn assert_is_not_equal_overloaded_rhs_fail<let N: u32, BN>()
where
    BN: BigNumTrait,
{
    let a = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };
    let b = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };

    let modulus = BN::modulus();

    let t0: U60Repr<N, 2> = U60Repr::from(b.get_limbs_slice().as_array());
    let t1: U60Repr<N, 2> = U60Repr::from(modulus.get_limbs_slice().as_array());
    let b_plus_modulus = BN::from_slice(U60Repr::into(t0 + t1));
    a.assert_is_not_equal(b_plus_modulus);
}

fn assert_is_not_equal_overloaded_fail<let N: u32, BN>()
where
    BN: BigNumTrait,
{
    let a = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };
    let b = unsafe { BN::__derive_from_seed([1, 2, 3, 4]) };

    let modulus = BN::modulus();

    let t0: U60Repr<N, 2> = U60Repr::from(a.get_limbs_slice().as_array());
    let t1: U60Repr<N, 2> = U60Repr::from(b.get_limbs_slice().as_array());
    let t2: U60Repr<N, 2> = U60Repr::from(modulus.get_limbs_slice().as_array());
    let a_plus_modulus: BN = BN::from_slice(U60Repr::into(t0 + t2));
    let b_plus_modulus: BN = BN::from_slice(U60Repr::into(t1 + t2));
    a_plus_modulus.assert_is_not_equal(b_plus_modulus);
}

#[test]
fn test_eq_BN() {
    // let stub: Fq = BigNum::new();
    test_eq::<3, Fq>();
}
#[test]
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

#[test]
fn test_sub_test_BN() {
    // 0 - 1 should equal p - 1
    let mut a: Fq = BigNum::new();
    let mut b: Fq = BigNum::one();
    let mut expected: Fq = BigNum::modulus();
    expected.limbs[0] -= 1; // p - 1
    let result = a - b;
    assert(result == expected);
}

#[test]
fn test_sub_modulus_limit() {
    // if we underflow, maximum result should be ...
    // 0 - 1 = o-1
    // 0 - p = 0
    let mut a: Fq = BigNum::new();
    let mut b: Fq = BigNum::modulus();
    let mut expected = BigNum::new();

    let result = a - b;
    assert(result == expected);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_sub_modulus_underflow() {
    // 0 - (p + 1) is smaller than p and should produce unsatisfiable constraints
    let mut a: Fq = BigNum::new();
    let mut b: Fq = BigNum::modulus();
    b.limbs[0] += 1;
    let mut expected = BigNum::one();

    let result = a - b;
    assert(result == expected);
}

#[test]
fn test_add_modulus_limit() {
    // p + 2^{254} - 1 should be the maximum allowed value fed into an add operation
    // when adding, if the result overflows the modulus, we conditionally subtract the modulus, producing 2^{254} -  1
    // this is the largest value that will satisfy the range check applied when constructing a bignum
    let p: U60Repr<3, 2> = U60Repr::from(BN254_Fq_Params::get_params().modulus);
    let two_pow_254_minus_1: U60Repr<3, 2> = U60Repr::from([
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0x3fff,
    ]);
    let a: Fq = BigNum { limbs: U60Repr::into(p) };
    let b: Fq = BigNum { limbs: U60Repr::into(two_pow_254_minus_1) };
    let result = a + b;
    assert(result == b);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_add_modulus_overflow() {
    //(2^{254} - 1) + (p - 1) = 2^{254} + p
    // after subtracting modulus, result is 2^{254} will does not satisfy the range check applied when constructing a BigNum
    let p: U60Repr<3, 2> = U60Repr::from(BN254_Fq_Params::get_params().modulus);
    let two_pow_254_minus_1: U60Repr<3, 2> = U60Repr::from([
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0x3fff,
    ]);
    let one = U60Repr::from([1, 0, 0]);
    let a: Fq = BigNum { limbs: U60Repr::into(p + one) };
    let b: Fq = BigNum { limbs: U60Repr::into(two_pow_254_minus_1) };
    let result = a + b;
    assert(result == b);
}

#[test]
fn test_mul_BN() {
    test_mul::<3, Fq>();
}

#[test]
fn test_add_BN2() {
    test_add::<3, Fq>();
}

#[test]
fn test_div_BN() {
    test_div::<3, Fq>();
}

#[test]
fn test_invmod_BN() {
    test_invmod::<3, Fq>();
}

#[test]
fn test_assert_is_not_equal_BN() {
    assert_is_not_equal::<3, Fq>();
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_fail_BN() {
    assert_is_not_equal_fail::<3, Fq>();
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_lhs_fail_BN() {
    assert_is_not_equal_overloaded_lhs_fail::<3, Fq>();
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_rhs_fail_BN() {
    assert_is_not_equal_overloaded_rhs_fail::<3, Fq>();
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_fail_BN() {
    assert_is_not_equal_overloaded_fail::<3, Fq>();
}

#[test]
fn test_eq_2048() {
    test_eq::<18, BN2048>();
}

#[test]
fn test_mul_2048() {
    test_mul::<18, BN2048>();
}

#[test]
fn test_add_2048() {
    test_add::<18, BN2048>();
}

#[test]
fn test_assert_is_not_equal_2048() {
    assert_is_not_equal::<18, BN2048>();
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_fail_2048() {
    assert_is_not_equal_fail::<18, BN2048>();
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_lhs_fail_2048() {
    assert_is_not_equal_overloaded_lhs_fail::<18, BN2048>();
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_rhs_fail_2048() {
    assert_is_not_equal_overloaded_rhs_fail::<18, BN2048>();
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_fail_2048() {
    assert_is_not_equal_overloaded_fail::<18, BN2048>();
}

#[test]
fn test_eq_U256() {
    test_eq::<3, BN256>();
}

#[test]
fn test_mul_U256() {
    test_mul::<3, BN256>();
}

#[test]
fn test_add_U256() {
    test_add::<3, BN256>();
}

#[test]
fn test_assert_is_not_equal_U256() {
    assert_is_not_equal::<3, BN256>();
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_fail_U256() {
    assert_is_not_equal_fail::<3, BN256>();
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_lhs_fail_U256() {
    assert_is_not_equal_overloaded_lhs_fail::<3, BN256>();
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_rhs_fail_U256() {
    assert_is_not_equal_overloaded_rhs_fail::<3, BN256>();
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_fail_U256() {
    assert_is_not_equal_overloaded_fail::<3, BN256>();
}

type U256 = BN256;

#[test]
fn test_udiv_mod_U256() {
    let a: U256 = unsafe { BigNum::__derive_from_seed([1, 2, 3, 4]) };
    let b: U256 = BigNum::from_slice([12, 0, 0]);

    let (q, r) = a.udiv_mod(b);

    // let qb = q.__mul(b);
    let product = unsafe { q.__mul(b).__add(r) };
    assert(product == a);
}

// // N.B. witness generation times make these tests take ~15 minutes each! Uncomment at your peril
// #[test]
// fn test_div_2048() {
//     let stub: BN2048 = BigNum::new();
//     test_div(stub);
// }

// // N.B. witness generation times make these tests take ~15 minutes each! Uncomment at your peril
// #[test]
// fn test_invmod_2048() {
//     let stub: BN2048 = BigNum::new();
//     test_invmod(stub);
// }

#[test]
fn test_2048_bit_quadratic_expression() {
    let a: [Field; 18] = [
        0x000000000000000000000000000000000083684820ff40795b8d9f1be2220cba,
        0x0000000000000000000000000000000000d4924fbdc522b07b6cd0ef5508fd66,
        0x0000000000000000000000000000000000d48f6c43c5930f3d70d6db09a48f4a,
        0x0000000000000000000000000000000000e7f72b2c0756704bea85be38352b34,
        0x00000000000000000000000000000000008337197826e2e9ea000ed5b05d5ac5,
        0x000000000000000000000000000000000040680101b43f6d17de8e3507f3d820,
        0x00000000000000000000000000000000000c6ba0cdcf77cff1c10355ea48d387,
        0x0000000000000000000000000000000000e51717a72902214a9dbeb90e4f225f,
        0x0000000000000000000000000000000000c1bd5bec78406b691f71cbcddb4574,
        0x00000000000000000000000000000000001ce5e532cfb306d7b52e7d9f1aa442,
        0x000000000000000000000000000000000019575932f75ddf00595b22782e1ba2,
        0x0000000000000000000000000000000000d630b3fbf0a9e55861e4399900feb9,
        0x0000000000000000000000000000000000d6b37aeb2daa8d2e2f7e29b0f7752a,
        0x0000000000000000000000000000000000e9cacdd93406256b9eb46b73948849,
        0x00000000000000000000000000000000001400e1f0a38695db66993fe042c48b,
        0x0000000000000000000000000000000000e1d829cb4fa8cabb7d0265efbd8527,
        0x000000000000000000000000000000000055f1a92a5dd099ef2bcd89ac175b52,
        0x00000000000000000000000000000000000000000000000000000000000000fc,
    ];
    let b: [Field; 18] = [
        0x0000000000000000000000000000000000c5694493e9bcc76e68dfcf73e0fde1,
        0x0000000000000000000000000000000000ede5e4b8b3e0dec1f4705c35521620,
        0x00000000000000000000000000000000007aa800bab1b33eda0f07695af6c583,
        0x000000000000000000000000000000000045892edea2c02bf0b8b1d2d9a4ebcc,
        0x00000000000000000000000000000000004dffb06bf396f3d0a5b67cff714bdd,
        0x00000000000000000000000000000000004d691db495235e1e032f1ef3e90274,
        0x0000000000000000000000000000000000d92c069d0f2675b2f46cb497aa62d4,
        0x00000000000000000000000000000000003d3f23584f113cef1a4b8b7d183f5c,
        0x0000000000000000000000000000000000289ba11d897837f9cec57dcc430bfc,
        0x0000000000000000000000000000000000765dc64f6ed4a6efd7b26c38f79e59,
        0x00000000000000000000000000000000008edf31fabf5c330ecf7f92fb6487cd,
        0x000000000000000000000000000000000053392f8b14dd78af702b3be2e0d557,
        0x000000000000000000000000000000000034abf357bfd56e9786a7e47ed9a5ae,
        0x0000000000000000000000000000000000a9ebb234064c8ab10d4e7900d4b973,
        0x00000000000000000000000000000000002a6850cce14a20463913002ddc0fa6,
        0x0000000000000000000000000000000000a97e3b06586bfa62325ef7557ab536,
        0x0000000000000000000000000000000000b942b0d26e5be2e08cd425107c59f7,
        0x0000000000000000000000000000000000000000000000000000000000000031,
    ];
    let c_expected: [Field; 18] = [
        0x00000000000000000000000000000000004518a874adebbcf963fed876dfcf78,
        0x00000000000000000000000000000000002b1535070c2deca63e2dc7145a9997,
        0x0000000000000000000000000000000000d9b738665a290c09f09202043d9387,
        0x0000000000000000000000000000000000c88853b11034fe12661eb7a5e41ca7,
        0x0000000000000000000000000000000000357cc4053e7eb127abc2c1430972a1,
        0x0000000000000000000000000000000000224df5e1be31a51562f8574027a992,
        0x000000000000000000000000000000000070ad9287e6326d534f1d2835e159ad,
        0x00000000000000000000000000000000000efa138f75f20b5117955e15bbb447,
        0x0000000000000000000000000000000000d9f45c310be1865ad23fbcdeb1d93f,
        0x00000000000000000000000000000000004f74ca4cf3df59a83f2df796fc9beb,
        0x0000000000000000000000000000000000ed1801428ebf7db771deb45f4311eb,
        0x00000000000000000000000000000000002ded3b46e3a84cda43157d4d927162,
        0x00000000000000000000000000000000009bcd6ac8f90601a44a84a026d4b383,
        0x0000000000000000000000000000000000ab098478b39031a1de85062fd5712b,
        0x00000000000000000000000000000000004432a79276f4375ff3ec2ced8b6cf6,
        0x0000000000000000000000000000000000a0922d75e96e3f9e31c0cbbcbd708a,
        0x00000000000000000000000000000000004013822c9e9aa5b5b1e9c33e4332b7,
        0x0000000000000000000000000000000000000000000000000000000000000058,
    ];

    let a_bn: BN2048 = BigNum { limbs: a };
    let b_bn: BN2048 = BigNum { limbs: b };
    let c_bn = unsafe { a_bn.__mul(b_bn) };
    assert(c_bn.limbs == c_expected);

    a_bn.validate_in_range();

    BigNum::evaluate_quadratic_expression([[a_bn]], [[false]], [[b_bn]], [[false]], [c_bn], [true]);
}

#[test]
fn test_expressions() {
    let x: [Field; 6] = [
        0x000000000000000000000000000000000083684820ff40795b8d9f1be2220cba,
        0x0000000000000000000000000000000000d4924fbdc522b07b6cd0ef5508fd66,
        0x0000000000000000000000000000000000d48f6c43c5930f3d70d6db09a48f4a,
        0x0000000000000000000000000000000000e7f72b2c0756704bea85be38352b34,
        0x00000000000000000000000000000000000000000000000000000000b05d5ac5,
        0,
    ];

    let y: Fq = BigNum { limbs: [0x1, 0x1, 0x0] };
    let z: Fq = BigNum { limbs: [0x2, 0x2, 0x0] };
    let yy = unsafe { y.__add(y) };

    assert(yy.limbs == z.limbs);

    let uu: Fq = BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
            0x000000000000000000000000000000000000000000000000000000000000063,
        ],
    };
    let vv: Fq = BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000000062,
        ],
    };
    let w: Fq = BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000001f93,
        ],
    };
    let x: Fq = BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000000f93,
        ],
    };
    let wx = unsafe { w.__mul(x) };
    let uv = unsafe { uu.__mul(vv) };
    let y = unsafe { (uv.__add(wx)).__neg() };
    let z = unsafe { uv.__add(wx) };

    BigNum::evaluate_quadratic_expression(
        [[uu], [w]],
        [[false], [false]],
        [[vv], [x]],
        [[false], [false]],
        [z],
        [true],
    );
    BigNum::evaluate_quadratic_expression(
        [[uu], [w]],
        [[false], [false]],
        [[vv], [x]],
        [[false], [false]],
        [y],
        [false],
    );

    let wx_constrained = w * x;
    assert(wx_constrained.limbs == wx.limbs);
}

