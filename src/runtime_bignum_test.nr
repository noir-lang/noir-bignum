use crate::utils::u60_representation::U60Repr;
use crate::runtime_bignum::RuntimeBigNum;
use crate::params::BigNumParams;
use crate::fields::bn254Fq::BN254_Fq_Params;

global BN254_Fq_PARAMS = BN254_Fq_Params::get_params();

fn get_2048_BN_params() -> BigNumParams<18, 2048> {
    let has_multiplicative_inverse = false;
    // let modulus_bits_getter = || 2048;
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
        0x000000000000000000000000000000000091697def7100cd5cf8d890b4ef2ec3,
        0x00000000000000000000000000000000006765ba8304214dac764d3f4adc3185,
        0x000000000000000000000000000000000048404bd14d927ea230e60d4bebf940,
        0x00000000000000000000000000000000007c4d53a23bacc251ecbfc4b7ba5a0b,
        0x000000000000000000000000000000000093eaf3499474a6f5b2fff83f1259c8,
        0x00000000000000000000000000000000005bff4c737b97281f1a5f2384a8c16d,
        0x000000000000000000000000000000000061b4cf2f55358476b5323782999055,
        0x00000000000000000000000000000000001e7a804e8eacfe3a2a5673bc3885b8,
        0x0000000000000000000000000000000000eabadeae4282906c817adf70eab4ae,
        0x0000000000000000000000000000000000166f7df257fe2bf27f0809aceed9b0,
        0x00000000000000000000000000000000007d90fb7428901b8bed11f6b81e36bf,
        0x0000000000000000000000000000000000f36e6ba885c60b7024c563605df7e0,
        0x000000000000000000000000000000000052b7c58d2fb5d2c8478963ae6d4a44,
        0x000000000000000000000000000000000036ee761de26635f114ccc3f7d74f85,
        0x0000000000000000000000000000000000e3fb726a10cf2220897513f05243de,
        0x0000000000000000000000000000000000f43a26bbd732496eb4d828591b8056,
        0x0000000000000000000000000000000000ff4e42304e60fb3a54fca735499f2c,
        0x0000000000000000000000000000000000000000000000000000000000000162
    ];
    BigNumParams::new(
        has_multiplicative_inverse,
        // modulus_bits_getter,
        modulus,
        redc_param
    )
}

fn test_eq<let N: u32, let MOD: u32>(params: BigNumParams<N, MOD>) {
    let a: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };
    let b: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };
    let c: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [2, 2, 3, 4])
    };

    let modulus = a.modulus();
    let t0: U60Repr<N, 2> = (U60Repr::from(modulus.limbs));
    let t1: U60Repr<N, 2> = (U60Repr::from(b.limbs));
    let b_plus_modulus: RuntimeBigNum<N, MOD> = RuntimeBigNum { limbs: U60Repr::into(t0 + t1), params };

    assert((a == b) == true);
    assert((a == b_plus_modulus) == true);
    assert((c == b) == false);
    assert((c == a) == false);
}

// 98760
// 99689
// 929 gates for a 2048 bit mul
fn test_mul<let N: u32, let MOD: u32>(params: BigNumParams<N, MOD>) {
    let a: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };
    let b: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [4, 5, 6, 7])
    };

    let c = (a + b) * (a + b);
    let d = (a * a) + (b * b) + (a * b) + (a * b);
    assert(c == d);
}

fn test_add<let N: u32, let MOD: u32>(params: BigNumParams<N, MOD>) {
    let a: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };
    let b: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [4, 5, 6, 7])
    };
    let one: RuntimeBigNum<N, MOD> = RuntimeBigNum::one(params);
    a.validate_in_range();
    a.validate_in_field();
    b.validate_in_range();
    b.validate_in_field();

    let mut c = a + b;
    c = c + c;
    let d = (a + b) * (one + one);
    assert(c == d);

    let e = one + one;
    for i in 1..N {
        assert(e.limbs[i] == 0);
    }
    assert(e.limbs[0] == 2);
}

fn test_div<let N: u32, let MOD: u32>(params: BigNumParams<N, MOD>) {
    let a: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };
    let b: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [4, 5, 6, 7])
    };

    let c = a / b;
    assert((b * c) == a);
}

unconstrained fn test_invmod<let N: u32, let MOD: u32>(params: BigNumParams<N, MOD>) {
    let u: RuntimeBigNum<N, MOD> = RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4]);
    for _ in 0..1 {
        let v = u.__invmod();
        let result = u.__mul(v);
        let expected = RuntimeBigNum::one(params);
        assert(result.limbs == expected.limbs);
    }
}

unconstrained fn assert_is_not_equal<let N: u32, let MOD: u32>(params: BigNumParams<N, MOD>) {
    let a: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };
    let b: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [4, 5, 6, 7])
    };

    a.assert_is_not_equal(b);
}

unconstrained fn assert_is_not_equal_fail<let N: u32, let MOD: u32>(params: BigNumParams<N, MOD>) {
    let a: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };
    let b: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };

    a.assert_is_not_equal(b);
}

fn assert_is_not_equal_overloaded_lhs_fail<let N: u32, let MOD: u32>(params: BigNumParams<N, MOD>) {
    let a: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };
    let b: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };

    let modulus = params.modulus;

    let t0: U60Repr<N, 2> = U60Repr::from(a.limbs);
    let t1: U60Repr<N, 2> = U60Repr::from(modulus);
    let a_plus_modulus: RuntimeBigNum<N, MOD> = RuntimeBigNum { limbs: U60Repr::into(t0 + t1), params };
    a_plus_modulus.assert_is_not_equal(b);
}

fn assert_is_not_equal_overloaded_rhs_fail<let N: u32, let MOD: u32>(params: BigNumParams<N, MOD>) {
    let a: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };
    let b: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };

    let modulus = params.modulus;

    let t0: U60Repr<N, 2> = U60Repr::from(b.limbs);
    let t1: U60Repr<N, 2> = U60Repr::from(modulus);
    let b_plus_modulus: RuntimeBigNum<N, MOD> = RuntimeBigNum { limbs: U60Repr::into(t0 + t1), params };
    a.assert_is_not_equal(b_plus_modulus);
}

fn assert_is_not_equal_overloaded_fail<let N: u32, let MOD: u32>(params: BigNumParams<N, MOD>) {
    let a: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };
    let b: RuntimeBigNum<N, MOD> = unsafe {
        RuntimeBigNum::__derive_from_seed(params, [1, 2, 3, 4])
    };

    let modulus = params.modulus;

    let t0: U60Repr<N, 2> = U60Repr::from(a.limbs);
    let t1: U60Repr<N, 2> = U60Repr::from(b.limbs);
    let t2: U60Repr<N, 2> = U60Repr::from(modulus);
    let a_plus_modulus: RuntimeBigNum<N, MOD> = RuntimeBigNum { limbs: U60Repr::into(t0 + t2), params };
    let b_plus_modulus: RuntimeBigNum<N, MOD> = RuntimeBigNum { limbs: U60Repr::into(t1 + t2), params };
    a_plus_modulus.assert_is_not_equal(b_plus_modulus);
}

#[test]
fn test_eq_BN() {
    let params = BN254_Fq_PARAMS;
    test_eq(params);
}

#[test]
fn test_add_BN() {
    let params = BN254_Fq_PARAMS;

    let mut a: RuntimeBigNum<_, 254> = RuntimeBigNum { limbs: params.modulus, params };
    let mut b = a;
    let mut expected = a;

    a.limbs[0] -= 1;
    b.limbs[0] -= 1;
    expected.limbs[0] -= 2;

    let result = a + b;
    assert(result == expected);
}

#[test]
fn test_sub_test_BN() {
    let params = BN254_Fq_PARAMS;

    // 0 - 1 should equal p - 1
    let mut a: RuntimeBigNum<_, 254> = RuntimeBigNum::new(params);
    let mut b: RuntimeBigNum<_, 254> = RuntimeBigNum::one(params);
    let mut expected: RuntimeBigNum<_, 254> = RuntimeBigNum { limbs: params.modulus, params };
    expected.limbs[0] -= 1; // p - 1

    let result = a - b;
    assert(result == expected);
}

#[test]
fn test_sub_modulus_limit() {
    let params = BN254_Fq_PARAMS;

    // if we underflow, maximum result should be ...
    // 0 - 1 = o-1
    // 0 - p = 0
    let mut a: RuntimeBigNum<_, 254> = RuntimeBigNum::new(params);
    let mut b: RuntimeBigNum<_, 254> = RuntimeBigNum { limbs: params.modulus, params };
    let mut expected: RuntimeBigNum<_, 254> = RuntimeBigNum::new(params);

    let result = a - b;
    assert(result == expected);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_sub_modulus_underflow() {
    let params = BN254_Fq_PARAMS;

    // 0 - (p + 1) is smaller than p and should produce unsatisfiable constraints
    let mut a: RuntimeBigNum<_, 254> = RuntimeBigNum::new(params);
    let mut b: RuntimeBigNum<_, 254> = RuntimeBigNum { limbs: params.modulus, params };
    b.limbs[0] += 1;
    let mut expected: RuntimeBigNum<_, 254> = RuntimeBigNum::one(params);

    let result = a - b;

    assert(result == expected);
}

#[test]
fn test_add_modulus_limit() {
    let params = BN254_Fq_PARAMS;

    // p + 2^{254} - 1 should be the maximum allowed value fed into an add operation
    // when adding, if the result overflows the modulus, we conditionally subtract the modulus, producing 2^{254} -  1
    // this is the largest value that will satisfy the range check applied when constructing a bignum
    let p : U60Repr<3, 2> = U60Repr::from(params.modulus);
    let two_pow_254_minus_1: U60Repr<3, 2> = U60Repr::from([0xffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffff, 0x3fff]);
    let a: RuntimeBigNum<_, 254> = RuntimeBigNum { limbs: U60Repr::into(p), params };
    let b: RuntimeBigNum<_, 254> = RuntimeBigNum { limbs: U60Repr::into(two_pow_254_minus_1), params };
    let result = a + b;
    assert(result == b);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_add_modulus_overflow() {
    let params = BN254_Fq_PARAMS;

    //(2^{254} - 1) + (p - 1) = 2^{254} + p
    // after subtracting modulus, result is 2^{254} will does not satisfy the range check applied when constructing a BigNum
    let p : U60Repr<3, 2> = U60Repr::from(params.modulus);
    let two_pow_254_minus_1: U60Repr<3, 2> = U60Repr::from([0xffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffff, 0x3fff]);
    let one = U60Repr::from([1, 0, 0]);
    let a: RuntimeBigNum<_, 254> = RuntimeBigNum { limbs: U60Repr::into(p + one), params };
    let b: RuntimeBigNum<_, 254> = RuntimeBigNum { limbs: U60Repr::into(two_pow_254_minus_1), params };
    let result = a + b;
    assert(result == b);
}

#[test]
fn test_mul_BN() {
    let params = BN254_Fq_PARAMS;
    test_mul(params);
}

#[test]
fn test_add_BN2() {
    let params = BN254_Fq_PARAMS;
    test_add(params);
}

#[test]
fn test_div_BN() {
    let params = BN254_Fq_PARAMS;
    test_div(params);
}

#[test]
unconstrained fn test_invmod_BN() {
    let params = BN254_Fq_PARAMS;
    test_invmod(params);
}

#[test]
unconstrained fn test_assert_is_not_equal_BN() {
    let params = BN254_Fq_PARAMS;
    assert_is_not_equal(params);
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
unconstrained fn test_assert_is_not_equal_fail_BN() {
    let params = BN254_Fq_PARAMS;
    assert_is_not_equal_fail(params);
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_lhs_fail_BN() {
    let params = BN254_Fq_PARAMS;
    assert_is_not_equal_overloaded_lhs_fail(params);
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_rhs_fail_BN() {
    let params = BN254_Fq_PARAMS;
    assert_is_not_equal_overloaded_rhs_fail(params);
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_fail_BN() {
    let params = BN254_Fq_PARAMS;
    assert_is_not_equal_overloaded_fail(params);
}

#[test]
fn test_eq_2048() {
    let params = get_2048_BN_params();
    test_eq(params);
}

#[test]
fn test_mul_2048() {
    let params = get_2048_BN_params();
    test_mul(params);
}

#[test]
fn test_add_2048() {
    let params = get_2048_BN_params();
    test_add(params);
}

#[test]
unconstrained fn test_assert_is_not_equal_2048() {
    let params = get_2048_BN_params();
    assert_is_not_equal(params);
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
unconstrained fn test_assert_is_not_equal_fail_2048() {
    let params = get_2048_BN_params();
    assert_is_not_equal_fail(params);
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_lhs_fail_2048() {
    let params = get_2048_BN_params();
    assert_is_not_equal_overloaded_lhs_fail(params);
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_rhs_fail_2048() {
    let params = get_2048_BN_params();
    assert_is_not_equal_overloaded_rhs_fail(params);
}

#[test(should_fail_with = "asssert_is_not_equal fail")]
fn test_assert_is_not_equal_overloaded_fail_2048() {
    let params = get_2048_BN_params();
    assert_is_not_equal_overloaded_fail(params);
}

// N.B. witness generation times make these tests take ~15 minutes each! Uncomment at your peril
// #[test]
// fn test_div_2048() {
// let params = get_2048_BN_params();
//     test_div(params);
// }

// N.B. witness generation times make these tests take ~15 minutes each! Uncomment at your peril
// #[test]
// fn test_invmod_2048() {
// let params = get_2048_BN_params();
//     test_invmod(params);
// }

#[test]
fn test_2048_bit_quadratic_expression() {
    let params = get_2048_BN_params();
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

    let a: RuntimeBigNum<_, 2048> = RuntimeBigNum { limbs: a, params };
    let b: RuntimeBigNum<_, 2048> = RuntimeBigNum { limbs: b, params };
    let c = a * b;
    assert(c.limbs == c_expected);

    a.validate_in_range();

    RuntimeBigNum::evaluate_quadratic_expression(params, [[a]], [[false]], [[b]], [[false]], [c], [true]);
}

#[test]
fn test_expressions() {
    let params = BN254_Fq_PARAMS;

    let x: [Field; 6] = [
        0x000000000000000000000000000000000083684820ff40795b8d9f1be2220cba, 0x0000000000000000000000000000000000d4924fbdc522b07b6cd0ef5508fd66, 0x0000000000000000000000000000000000d48f6c43c5930f3d70d6db09a48f4a,
        0x0000000000000000000000000000000000e7f72b2c0756704bea85be38352b34, 0x00000000000000000000000000000000000000000000000000000000b05d5ac5, 0
    ];

    let y: RuntimeBigNum<_, 254> = RuntimeBigNum {
        limbs: [
            0x1,
            0x1,
            0x0
        ], params
    };
    let z: RuntimeBigNum<_, 254> = RuntimeBigNum {
        limbs: [
            0x2,
            0x2,
            0x0
        ], params
    };
    let yy = unsafe {
        y.__add(y)
    };

    assert(yy.limbs == z.limbs);

    let uu: RuntimeBigNum<_, 254> = RuntimeBigNum {
        limbs: [
            0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
            0x000000000000000000000000000000000000000000000000000000000000063
        ],
        params
    };
    let vv: RuntimeBigNum<_, 254> = RuntimeBigNum {
        limbs: [
            0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000000062
        ],
        params
    };
    let w: RuntimeBigNum<_, 254> = RuntimeBigNum {
        limbs: [
            0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000001f93
        ],
        params
    };
    let x: RuntimeBigNum<_, 254> = RuntimeBigNum {
        limbs: [
            0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000000f93
        ],
        params
    };
    let wx = unsafe {
        w.__mul(x)
    };
    let uv = unsafe {
        uu.__mul(vv)
    };
    let y = unsafe {
        (uv.__add(wx)).__neg()
    };
    let z = unsafe {
        uv.__add(wx)
    };

    RuntimeBigNum::evaluate_quadratic_expression(
        params,
        [[uu], [w]],
        [[false], [false]],
        [[vv], [x]],
        [[false], [false]],
        [z],
        [true]
    );
    RuntimeBigNum::evaluate_quadratic_expression(
        params,
        [[uu], [w]],
        [[false], [false]],
        [[vv], [x]],
        [[false], [false]],
        [y],
        [false]
    );

    let wx_constrained = w * x;
    assert(wx_constrained.limbs == wx.limbs);
}
