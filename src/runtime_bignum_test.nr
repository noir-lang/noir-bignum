use crate::BigNum;
use crate::runtime_bignum::BigNumInstance;
use crate::runtime_bignum::BigNumParamsTrait;
use crate::BigNumParamsTrait as NotRuntimeBigNumParamsTrait;

use crate::utils::u60_representation::U60Repr;
use crate::fields::bn254Fq::BNParams as BNParams;
use crate::fields::secp256k1Fq::Secp256k1_Fq_Params;
use crate::fields::bls12_381Fq::BLS12_381_Fq_Params;
use crate::fields::bls12_381Fr::BLS12_381_Fr_Params;
use crate::fields::bls12_377Fq::BLS12_377_Fq_Params;
use crate::fields::bls12_377Fr::BLS12_377_Fr_Params;

struct Test2048Params {}

// See https://github.com/noir-lang/noir/issues/6172
#[test]
fn silence_warning() {
    let _  = Test2048Params {};
}

impl BigNumParamsTrait<18, 2048> for Test2048Params {
    fn modulus_bits() -> u32 {
        2048
    }
}
impl NotRuntimeBigNumParamsTrait<18, 2048> for Test2048Params {
    fn modulus_bits() -> u32 {
        2048
    }
    fn get_instance() -> BigNumInstance<18, Test2048Params> {
        let modulus: [Field; 18] = [
            0x0000000000000000000000000000000000c0a197a5ae0fcdceb052c9732614fe,
            0x0000000000000000000000000000000000656ae034423283422243918ab83be3,
            0x00000000000000000000000000000000006bf590da48a7c1070b7d5aabaac678,
            0x00000000000000000000000000000000000cce39f530238b606f24b296e2bda9,
            0x000000000000000000000000000000000001e1fef9bb9c1c3ead98f226f1bfa0,
            0x0000000000000000000000000000000000ad8c1c816e12e0ed1379055e373abf,
            0x0000000000000000000000000000000000cebe80e474f753aa9d1461c435123d,
            0x0000000000000000000000000000000000aee5a18ceedef88d115a8b93c167ad,
            0x0000000000000000000000000000000000268ba83c4a65c4307427fc495d9e44,
            0x0000000000000000000000000000000000dd2777926848667b7df79f342639d4,
            0x0000000000000000000000000000000000f455074c96855ca0068668efe7da3d,
            0x00000000000000000000000000000000005ddba6b30bbc168bfb3a1225f27d65,
            0x0000000000000000000000000000000000591fec484f36707524133bcd6f4258,
            0x000000000000000000000000000000000059641b756766aeebe66781dd01d062,
            0x000000000000000000000000000000000058bc5eaff4b165e142bf9e2480eebb,
            0x0000000000000000000000000000000000667a3964f08e06df772ce64b229a72,
            0x00000000000000000000000000000000009c1fdb18907711bfe3e3c1cf918395,
            0x00000000000000000000000000000000000000000000000000000000000000b8
        ];
        let redc_param: [Field; 18] = [
            0x1697def7100cd5cf8d890b4ef2ec3f, 0x765ba8304214dac764d3f4adc31859, 0x8404bd14d927ea230e60d4bebf9406, 0xc4d53a23bacc251ecbfc4b7ba5a0b4, 0x3eaf3499474a6f5b2fff83f1259c87, 0xbff4c737b97281f1a5f2384a8c16d9, 0x1b4cf2f55358476b53237829990555, 0xe7a804e8eacfe3a2a5673bc3885b86, 0xabadeae4282906c817adf70eab4ae1, 0x66f7df257fe2bf27f0809aceed9b0e, 0xd90fb7428901b8bed11f6b81e36bf1, 0x36e6ba885c60b7024c563605df7e07, 0x2b7c58d2fb5d2c8478963ae6d4a44f, 0x6ee761de26635f114ccc3f7d74f855, 0x3fb726a10cf2220897513f05243de3, 0x43a26bbd732496eb4d828591b8056e, 0xf4e42304e60fb3a54fca735499f2cf, 0x162f
        ];
        BigNumInstance::new(modulus, redc_param)
    }
}

/**
 * @brief this example was failing - sanity test to validate it now works
 **/
#[test]
fn test_bls_reduction() {
    let X1: BigNum<4, BLS12_381_Fq_Params> = BigNum {
        limbs: [
            0x55e83ff97a1aeffb3af00adb22c6bb, 0x8c4f9774b905a14e3a3f171bac586c, 0xa73197d7942695638c4fa9ac0fc368, 0x17f1d3
        ]
    };
    X1.validate_in_field();
    let mut (_, XX_mul_3): (BigNum<4, BLS12_381_Fq_Params>, BigNum<4, BLS12_381_Fq_Params> ) = unsafe {
        BigNum::__compute_quadratic_expression(
            [[X1, X1, X1]],
            [[false, false, false]],
            [[X1]],
            [[false]],
            [],
            []
        )
    };
    XX_mul_3.validate_in_field();
}

// /**
//  * @brief experimenting with macro madness and code generation to make some tests that apply to multiple BigNum parametrisations!
//  **/
// comptime fn make_test(f: StructDefinition, N: Quoted, typ: Quoted) -> Quoted {
//     let k = f.name();
//     quote{
// impl $k {
// #[test]
// fn test_add() {
//     let bn = $typ ::get_instance();
//     let a: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([1, 2, 3, 4]) };
//     let b: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([4, 5, 6, 7]) };
//     let one: BigNum<$N, $typ> = BigNum::one();
//     a.validate_in_range();
//     bn.validate_in_field(a);
//     b.validate_in_range();
//     bn.validate_in_field(b);

//     let mut c = bn.add(a, b);
//     c = bn.add(c, c);
//     let d = bn.mul(bn.add(a, b), bn.add(one, one));
//     assert(bn.eq(c, d));

//     let e = bn.add(one, one);
//     for i in 1..$N {
//         assert(e.limbs[i] == 0);
//     }
//     assert(e.limbs[0] == 2);
// }

// #[test]
// fn test_sub() {
//     let bn = $typ::get_instance();
//     // 0 - 1 should equal p - 1
//     let mut a: BigNum<$N, $typ> = BigNum::new();
//     let mut b: BigNum<$N, $typ> = BigNum::one();
//     let mut expected: BigNum<$N, $typ> = bn.modulus();
//     expected.limbs[0] -= 1; // p - 1

//     let result = bn.sub(a, b);
//     assert(bn.eq(result, expected));
// }


// #[test]
// fn test_sub_modulus_limit() {
//     let instance = $typ::get_instance();
//     // if we underflow, maximum result should be ...
//     // 0 - 1 = o-1
//     // 0 - p = 0
//     let mut a: BigNum<$N, $typ> = BigNum::new();
//     let mut b: BigNum<$N, $typ> = instance.modulus();
//     let mut expected: BigNum<$N, $typ> = BigNum::new();
//     let result = instance.sub(a, b);
//     assert(instance.eq(result, expected));
// }


// #[test(should_fail_with = "call to assert_max_bit_size")]
// fn test_sub_modulus_underflow() {
//     let instance = $typ::get_instance();

//     // 0 - (p + 1) is smaller than p and should produce unsatisfiable constraints
//     let mut a: BigNum<$N, $typ> = BigNum::new();
//     let mut b: BigNum<$N, $typ> = instance.modulus();
//     b.limbs[0] += 1;
//     let mut expected: BigNum<$N, $typ> = BigNum::one();

//     let result = instance.sub(a, b);

//     assert(instance.eq(result, expected));
// }

// #[test]
// fn test_add_modulus_limit() {
//     let instance = $typ::get_instance();
//     // p + 2^{modulus_bits()} - 1 should be the maximum allowed value fed into an add operation
//     // when adding, if the result overflows the modulus, we conditionally subtract the modulus, producing 2^{254} -  1
//     // this is the largest value that will satisfy the range check applied when constructing a bignum
//     let p : U60Repr<$N, 2> = U60Repr::from(instance.modulus().limbs);
//     let one = unsafe{ U60Repr::one() };

//     let a: BigNum<$N, $typ> = unsafe{ BigNum { limbs: U60Repr::into(p) } };
//     let mut two_pow_modulus_bits_minus_one: U60Repr<$N, 2> = unsafe{ one.shl(a.modulus_bits()) - one };
//     let b: BigNum<$N, $typ> = BigNum { limbs: U60Repr::into(two_pow_modulus_bits_minus_one) };
//     let result = instance.add(a, b);
//     assert(instance.eq(result, b));
// }

// #[test(should_fail_with = "call to assert_max_bit_size")]
// fn test_add_modulus_overflow() {

//     let instance = $typ::get_instance();
//     let p : U60Repr<$N, 2> = U60Repr::from(instance.modulus().limbs);
//     let one = unsafe{ U60Repr::one() };
//     let a: BigNum<$N, $typ> = unsafe{ BigNum { limbs: U60Repr::into(p + one) } };
//     let mut two_pow_modulus_bits_minus_one: U60Repr<$N, 2> = unsafe{ one.shl(a.modulus_bits()) - one };
//     let b: BigNum<$N, $typ> = BigNum { limbs: U60Repr::into(two_pow_modulus_bits_minus_one) };
//     let result = instance.add(a, b);
//     assert(instance.eq(result, b));
// }

// #[test]
// fn test_mul() {
//     let bn = $typ ::get_instance();
//     let a: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([1, 2, 3, 4]) };
//     let b: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([4, 5, 6, 7]) };

//     let c = bn.mul(bn.add(a, b), bn.add(a, b));
//     let d = bn.add(
//         bn.add(
//             bn.add(bn.mul(a, a), bn.mul(b, b)),
//             bn.mul(a, b)
//         ),
//         bn.mul(a, b)
//     );
//     assert(bn.eq(c, d));
// }

// #[test]
// fn test_quadratic_expression() {
//     let bn = $typ ::get_instance();
//     for i in 0..32 {
//     let X1: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([i as u8,2,3,4]) };
//     let Y1: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([i as u8,i as u8,6,7]) };
//     let Z1: BigNum<$N, $typ> = BigNum::one();

//         let (_, YY_mul_2): (BigNum<$N, $typ>, BigNum<$N, $typ> ) = unsafe{BigNum::__compute_quadratic_expression([[Y1]], [[false]], [[Y1, Y1]], [[false, false]], [], [])};
//         let mut (_, XX_mul_3): (BigNum<$N, $typ>, BigNum<$N, $typ> ) = unsafe{BigNum::__compute_quadratic_expression(
//             [[X1]],
//             [[false]],
//             [[X1, X1, X1]],
//             [[false, false, false]],
//             [],
//             []
//         )};
//         let (_, D): (BigNum<$N, $typ>, BigNum<$N, $typ> ) = unsafe{BigNum::__compute_quadratic_expression([[X1, X1]], [[false, false]], [[YY_mul_2]], [[false]], [], [])};
//         let mut (_, X3): (BigNum<$N, $typ>, BigNum<$N, $typ> ) = unsafe{BigNum::__compute_quadratic_expression(
//             [[XX_mul_3]],
//             [[false]],
//             [[XX_mul_3]],
//             [[false]],
//             [D, D],
//             [true, true]
//         )};
//         let (_, Y3): (BigNum<$N, $typ>, BigNum<$N, $typ> ) = unsafe{BigNum::__compute_quadratic_expression(
//             [[XX_mul_3], [YY_mul_2]],
//             [[false], [true]],
//             [[D, X3], [YY_mul_2, YY_mul_2]],
//             [[false, true], [false, false]],
//             [],
//             []
//         )};
//         // 3XX * (D - X3) - 8YYYY

//         let (_, Z3): (BigNum<$N, $typ>, BigNum<$N, $typ> ) = unsafe{ BigNum::__compute_quadratic_expression([[Y1]], [[false]], [[Z1, Z1]], [[false, false]], [], []) };

//         bn.validate_in_field(X3);
//         bn.validate_in_field(Y3);
//         bn.validate_in_field(Z3);
//     }
// }

// #[test]
// fn assert_is_not_equal() {
//     let bn = $typ ::get_instance();
//     let a: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([1, 2, 3, 4]) };
//     let b: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([4, 5, 6, 7]) };

//     bn.assert_is_not_equal(a, b);
// }

// #[test(should_fail_with = "asssert_is_not_equal fail")]
// fn assert_is_not_equal_fail() {
//     let bn = $typ ::get_instance();
//     let a: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([1, 2, 3, 4]) };
//     let b: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([1, 2, 3, 4]) };

//     bn.assert_is_not_equal(a, b);
// }

// #[test(should_fail_with = "asssert_is_not_equal fail")]
// fn assert_is_not_equal_overloaded_lhs_fail() {
//     let bn = $typ ::get_instance();
//     let a: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([1, 2, 3, 4]) };
//     let b: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([1, 2, 3, 4]) };

//     let modulus = bn.modulus();

//     let t0: U60Repr<$N, 2> = U60Repr::from(a.limbs);
//     let t1: U60Repr<$N, 2> = U60Repr::from(modulus.limbs);
//     let a_plus_modulus: BigNum<$N, $typ> = BigNum { limbs: U60Repr::into(t0 + t1) };
//     bn.assert_is_not_equal(a_plus_modulus, b);
// }

// #[test(should_fail_with = "asssert_is_not_equal fail")]
// fn assert_is_not_equal_overloaded_rhs_fail() {
//     let bn = $typ ::get_instance();
//     let a: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([1, 2, 3, 4]) };
//     let b: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([1, 2, 3, 4]) };

//     let modulus = bn.modulus();

//     let t0: U60Repr<$N, 2> = U60Repr::from(b.limbs);
//     let t1: U60Repr<$N, 2> = U60Repr::from(modulus.limbs);
//     let b_plus_modulus: BigNum<$N, $typ> = BigNum { limbs: U60Repr::into(t0 + t1) };
//     bn.assert_is_not_equal(a, b_plus_modulus);
// }

// #[test(should_fail_with = "asssert_is_not_equal fail")]
// fn assert_is_not_equal_overloaded_fail() {
//     let bn = $typ ::get_instance();
//     let a: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([1, 2, 3, 4]) };
//     let b: BigNum<$N, $typ> = unsafe{ bn.__derive_from_seed([1, 2, 3, 4]) };
//     let modulus = bn.modulus();
//     let t0: U60Repr<$N, 2> = U60Repr::from(a.limbs);
//     let t1: U60Repr<$N, 2> = U60Repr::from(b.limbs);
//     let t2: U60Repr<$N, 2> = U60Repr::from(modulus.limbs);
//     let a_plus_modulus: BigNum<$N, $typ> = BigNum { limbs: U60Repr::into(t0 + t2) };
//     let b_plus_modulus: BigNum<$N, $typ> = BigNum { limbs: U60Repr::into(t1 + t2) };
//     bn.assert_is_not_equal(a_plus_modulus, b_plus_modulus);
// }

// #[test]
// fn test_derive()
// {
//     let bn = $typ ::get_instance();
//     let a: BigNum<$N, $typ> = bn.derive_from_seed("hello".as_bytes());
//     let b: BigNum<$N, $typ> = unsafe {
//         bn.__derive_from_seed("hello".as_bytes())
//     };
//     assert(bn.eq(a, b));
// }

// #[test]
// fn test_eq() {
//     let bn = $typ ::get_instance();
//     let a: BigNum<$N, $typ> = unsafe {
//         bn.__derive_from_seed([1, 2, 3, 4])
//     };
//     let b: BigNum<$N, $typ> = unsafe {
//         bn.__derive_from_seed([1, 2, 3, 4])
//     };
//     let c: BigNum<$N, $typ> = unsafe {
//         bn.__derive_from_seed([2, 2, 3, 4])
//     };

//     let modulus: BigNum<$N, $typ> = bn.modulus();
//     let t0: U60Repr<$N, 2> = (U60Repr::from(modulus.limbs));
//     let t1: U60Repr<$N, 2> = (U60Repr::from(b.limbs));
//     let b_plus_modulus: BigNum<$N, $typ> = BigNum { limbs: U60Repr::into(t0 + t1) };

//     assert(bn.eq(a, b) == true);
//     assert(bn.eq(a, b_plus_modulus) == true);
//     assert(bn.eq(c, b) == false);
//     assert(bn.eq(c, a) == false);
// }

// }
// }
// }

// #[make_test(quote{3},quote{BNParams})]
// pub struct BNTests{}
// #[make_test(quote{3},quote{Secp256k1_Fq_Params})]
// pub struct Secp256K1FqTests{}
// #[make_test(quote{4},quote{BLS12_381_Fq_Params})]
// pub struct BLS12_381FqTests{}

// #[make_test(quote{18},quote{Test2048Params})]
// pub struct Test2048Tests{}

// #[make_test(quote{3},quote{BLS12_381_Fr_Params})]
// pub struct BLS12_381_Fr_ParamsTests{}

// #[make_test(quote{4},quote{BLS12_377_Fq_Params})]
// pub struct BLS12_377_Fq_ParamsTests{}

// #[make_test(quote{3},quote{BLS12_377_Fr_Params})]
// pub struct BLS12_377_Fr_ParamsTests{}

type Fq = BigNum<3, BNParams>;

// 98760
// 99689
// 929 gates for a 2048 bit mul

fn test_div<let N: u32, let MOD_BITS: u32, Params>(bn: BigNumInstance<N, Params>) where Params: BigNumParamsTrait<N, MOD_BITS> {
    let a: BigNum<N, Params> = unsafe {
        bn.__derive_from_seed([1, 2, 3, 4])
    };
    let b: BigNum<N, Params> = unsafe {
        bn.__derive_from_seed([4, 5, 6, 7])
    };

    let c = bn.div(a, b);
    assert(bn.eq(bn.mul(b, c), a));
}

fn test_invmod<let N: u32, let MOD_BITS: u32, Params>(bn: BigNumInstance<N, Params>) where Params: BigNumParamsTrait<N, MOD_BITS> {
    let u: BigNum<N, Params> = unsafe {
        bn.__derive_from_seed([1, 2, 3, 4])
    };
    for _ in 0..1 {
        let v = unsafe {
            bn.__invmod(u)
        };
        let result = unsafe {
            bn.__mul(u, v)
        };
        let expected: BigNum<N, Params> = BigNum::one();
        assert(result.limbs == expected.limbs);
    }
}

#[test]
fn test_div_BN() {
    let instance = BNParams::get_instance();
    test_div(instance);
}

#[test]
fn test_invmod_BN() {
    let instance = BNParams::get_instance();
    test_invmod(instance);
}

// N.B. witness generation times make these tests take ~15 minutes each! Uncomment at your peril
// #[test]
// fn test_div_2048() {
// let instance = get_2048_BN_instance();
//     test_div(instance);
// }

// N.B. witness generation times make these tests take ~15 minutes each! Uncomment at your peril
// #[test]
// fn test_invmod_2048() {
// let instance = get_2048_BN_instance();
//     test_invmod(instance);
// }

#[test]
fn test_2048_bit_quadratic_expression() {
    let instance = Test2048Params::get_instance();
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
        0x00000000000000000000000000000000000000000000000000000000000000fc
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
        0x0000000000000000000000000000000000000000000000000000000000000031
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
        0x0000000000000000000000000000000000000000000000000000000000000058
    ];

    let a_bn: BigNum<18, Test2048Params> = BigNum { limbs: a };
    let b_bn: BigNum<18, Test2048Params> = BigNum { limbs: b };
    let c_bn = unsafe {
        instance.__mul(a_bn, b_bn)
    };
    assert(c_bn.limbs == c_expected);

    a_bn.validate_in_range();

    instance.evaluate_quadratic_expression([[a_bn]], [[false]], [[b_bn]], [[false]], [c_bn], [true]);
}

#[test]
fn test_expressions() {
    let instance = BNParams::get_instance();
    let x: [Field; 6] = [
        0x000000000000000000000000000000000083684820ff40795b8d9f1be2220cba, 0x0000000000000000000000000000000000d4924fbdc522b07b6cd0ef5508fd66, 0x0000000000000000000000000000000000d48f6c43c5930f3d70d6db09a48f4a,
        0x0000000000000000000000000000000000e7f72b2c0756704bea85be38352b34, 0x00000000000000000000000000000000000000000000000000000000b05d5ac5, 0
    ];

    let y: Fq = BigNum {
        limbs: [
            0x1,
            0x1,
            0x0
        ]
    };
    let z: Fq = BigNum {
        limbs: [
            0x2,
            0x2,
            0x0
        ]
    };
    let yy = unsafe {
        instance.__add(y, y)
    };

    assert(yy.limbs == z.limbs);

    let uu: Fq = BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
            0x000000000000000000000000000000000000000000000000000000000000063
        ]
    };
    let vv: Fq = BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000000062
        ]
    };
    let w: Fq = BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000001f93
        ]
    };
    let x: Fq = BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000000f93
        ]
    };
    let wx = unsafe {
        instance.__mul(w, x)
    };
    let uv = unsafe {
        instance.__mul(uu, vv)
    };
    let y = unsafe {
        instance.__neg(instance.__add(uv, wx))
    };
    let z = unsafe {
        instance.__add(uv, wx)
    };

    instance.evaluate_quadratic_expression(
        [[uu], [w]],
        [[false], [false]],
        [[vv], [x]],
        [[false], [false]],
        [z],
        [true]
    );
    instance.evaluate_quadratic_expression(
        [[uu], [w]],
        [[false], [false]],
        [[vv], [x]],
        [[false], [false]],
        [y],
        [false]
    );

    let wx_constrained = instance.mul(w, x);
    assert(wx_constrained.limbs == wx.limbs);
}
