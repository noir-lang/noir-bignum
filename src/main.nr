mod bignum;
mod split_bits;
mod u60_representation;
mod arrayX;
use crate::arrayX::ArrayX;
use crate::bignum::BNExpressionInput;
use crate::u60_representation::U60Repr;

struct BNParams {}
impl bignum::ParameterTrait<3> for BNParams {
    fn redc_param() -> [Field; 3] {
        [
            0x000000000000000000000000000000000059785d9f353021bcebb62866fe4394, 0x0000000000000000000000000000000000d18988e8129eac1d2961a01cc04eba, 0x0000000000000000000000000000000000000000000000000000000000015291
        ]
    }
    fn modulus() -> [Field; 3] {
        [
            0x0000000000000000000000000000000000816a916871ca8d3c208c16d87cfd47, 0x00000000000000000000000000000000004e72e131a029b85045b68181585d97, 0x0000000000000000000000000000000000000000000000000000000000003064
        ]
    }
    fn double_modulus() -> [Field; 3] {
        [
            0x000000000000000000000000000000000002d522d0e3951a7841182db0f9fa8e, 0x00000000000000000000000000000000009ce5c263405370a08b6d0302b0bb2f, 0x00000000000000000000000000000000000000000000000000000000000060c8
        ]
    }
    fn k() -> u64 {
        255
    }
    fn modulus_bits() -> u64 {
        254
    }
    fn one3u() -> U60Repr<3, 6> {
       U60Repr { limbs: ArrayX{ segments: [[1, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]] }}
    }
}
type Fq = bignum::BigNum<3, BNParams>;

fn main(x: Field, y: pub Field) {
    let z = x + y;
    let a = z * z;
    let b = a * a;
    let c = b * b;

    let mut lhs: Fq= bignum::BigNum { limbs: [x, y, z] };
    let rhs: Fq = bignum::BigNum { limbs: [a, b, c] };
    let mut lhs2 = BNExpressionInput::new(lhs, false);
    let rhs2= BNExpressionInput::new(rhs, false);

    for _ in 0..100 {
        let out: Fq = lhs2.value.__mulmod(rhs2.value);
        out.validate_in_range();
        let rem2 = BNExpressionInput::new(out, true);
        bignum::BigNum::evaluate_quadratic_expression([[lhs2]], [[rhs2]], [rem2]);
        lhs2.value = out;
    }
    // 68?
}

#[test]
fn test_invmod() {
    let a: [Field; 3] = [
        0x000000000000000000000000000000000007f3d8208337197826e2e9ea000ed5,
        0x0000000000000000000000000000000000ea48d38740680101b43f6d17de8e35,
        0x0000000000000000000000000000000000000000000000000000000000000355
    ];

    let u: Fq = bignum::BigNum { limbs: a };
    for _ in 0..1 {
        let v = u.__invmod();
        let result = u.__mulmod(v);
        let expected = bignum::BigNum::one();
        assert(result.limbs == expected.limbs);
    }
}

#[test]
fn test_main() {
    let x: [Field; 6] = [
        0x000000000000000000000000000000000083684820ff40795b8d9f1be2220cba, 0x0000000000000000000000000000000000d4924fbdc522b07b6cd0ef5508fd66, 0x0000000000000000000000000000000000d48f6c43c5930f3d70d6db09a48f4a,
        0x0000000000000000000000000000000000e7f72b2c0756704bea85be38352b34, 0x00000000000000000000000000000000000000000000000000000000b05d5ac5, 0
    ];
    // let a: [Field; 3] = [
    //     0x000000000000000000000000000000000007f3d8208337197826e2e9ea000ed5,
    //     0x0000000000000000000000000000000000ea48d38740680101b43f6d17de8e35,
    //     0x0000000000000000000000000000000000000000000000000000000000000355
    // ];
    // let b: [Field; 3] = [
    //     0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
    //     0x0000000000000000000000000000000000c4a832748da6ad742a1fd81b787643,
    //     0x000000000000000000000000000000000000000000000000000000000034df93
    // ];
    let expected_quotient: [Field; 3] = [
        0x0000000000000000000000000000000000373423c664d7b4108a16631d271c48, 0x0000000000000000000000000000000000dc52b6fd67c3293670f369cd9100b6, 0x000000000000000000000000000000000000000000000000000000000003a4fe
    ];
    // let expected_remainder: [Field; 3] = [
    //     0x00000000000000000000000000000000007ad74a6ab59fc786b288d0b2760cc2, 0x0000000000000000000000000000000000545d50595a9a818a28cdc8eb0237dc, 0x0000000000000000000000000000000000000000000000000000000000002427
    // ];

    // let u: Fq = bignum::BigNum { limbs: a };
    // let v: Fq = bignum::BigNum { limbs: b };

    let y: Fq = bignum::BigNum {
        limbs: [
            0x1,
            0x1,
            0x0
        ]
    };
    let z: Fq = bignum::BigNum {
        limbs: [
            0x2,
            0x2,
            0x0
        ]
    };
    let yy = y.__addmod(y);
    println(f"yy = {yy}");
    println(f"zz = {z}");

    assert(yy.limbs == z.limbs);
    // let r2: Fq = u.__mulmod(v);
    // let r2neg = r2.__negate();
    //  let foo = bignum::BigNum::compute_quadratic_expression_quotient([u], [v], [], [], [r2neg]);
    let mut ffq = expected_quotient;
    ffq[0] += 1;
    //  let xxx = foo.limbs;
    //   println(f"result = {xxx}");
    //   println(f"expected = {ffq}");
    //   assert(foo.limbs == ffq);

    let uu: Fq = bignum::BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
            0x000000000000000000000000000000000000000000000000000000000000063
        ]
    };
    let vv: Fq = bignum::BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000000062
        ]
    };
    let w: Fq = bignum::BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000001f93
        ]
    };
    let x: Fq = bignum::BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000000f93
        ]
    };
    let wx = w.__mulmod(x);
    let uv = uu.__mulmod(vv);
    let y = (uv.__addmod(wx)).__negate();
    let z = uv.__addmod(wx);
    let uuE: bignum::BNExpressionInput<3, BNParams> = bignum::BNExpressionInput { value: uu, is_negative: false };
    let vvE: bignum::BNExpressionInput<3, BNParams> = bignum::BNExpressionInput { value: vv, is_negative: false };
    let wE: bignum::BNExpressionInput<3, BNParams> = bignum::BNExpressionInput { value: w, is_negative: false };
    let xE: bignum::BNExpressionInput<3, BNParams> = bignum::BNExpressionInput { value: x, is_negative: false };
    let yE: bignum::BNExpressionInput<3, BNParams> = bignum::BNExpressionInput { value: y, is_negative: false };
    let zE: bignum::BNExpressionInput<3, BNParams> = bignum::BNExpressionInput { value: z, is_negative: true };

    bignum::BigNum::evaluate_quadratic_expression([[uuE], [wE]], [[vvE], [xE]], [zE]);
    bignum::BigNum::evaluate_quadratic_expression([[uuE], [wE]], [[vvE], [xE]], [yE]);

    let wx_constrained = w * x;
    assert(wx_constrained.limbs == wx.limbs);
    main(1, 2);
    //main(1, 1);
    // assert(quotient == expected_quotient);
    // assert(remainder == expected_remainder);
    // // uv + wx - y = 0
    // let uu: Fq = bignum::BigNum {
    //     limbs: [
    //         0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
    //         0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
    //         0x000000000000000000000000000000000000000000000000000000000000063
    //     ],
    //     foobar: [0; 3]
    // };
    // let vv: Fq = bignum::BigNum {
    //     limbs: [
    //         0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
    //         0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
    //         0x0000000000000000000000000000000000000000000000000000000000000062
    //     ],
    //     foobar: [0; 3]
    // };
    // let w: Fq = bignum::BigNum {
    //     limbs: [
    //         0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
    //         0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
    //         0x0000000000000000000000000000000000000000000000000000000000001f93
    //     ],
    //     foobar: [0; 3]
    // };
    // let x: Fq = bignum::BigNum {
    //     limbs: [
    //         0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
    //         0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
    //         0x0000000000000000000000000000000000000000000000000000000000000f93
    //     ],
    //     foobar: [0; 3]
    // };
    // let uv = uu.mulmod(vv, params);
    // let q = uv.negate(params);
    // Fq::compute_quadratic_expression_quotient([uu], [vv], [], [], [q], params);
    // let wx = w.mulmod(x, params);
    // let y = (uv.addmod(wx, params)).negate(params);
    // Fq::compute_quadratic_expression_quotient([uu], [vv], [w], [x], [y], params);
    // Fq::evaluate_quadratic_expression([uu], [vv], [w], [x], [y], params);
    // //main(1, 2);
    // // Uncomment to make test fail
    // // main(1, 1);
}

// fn test_main() {
//     let x: [Field; 6] = [
//         0x000000000000000000000000000000000083684820ff40795b8d9f1be2220cba, 0x0000000000000000000000000000000000d4924fbdc522b07b6cd0ef5508fd66, 0x0000000000000000000000000000000000d48f6c43c5930f3d70d6db09a48f4a,
//         0x0000000000000000000000000000000000e7f72b2c0756704bea85be38352b34, 0x00000000000000000000000000000000000000000000000000000000b05d5ac5, 0
//     ];
//     let a: [Field; 3] = [
//         0x000000000000000000000000000000000007f3d8208337197826e2e9ea000ed5,
//         0x0000000000000000000000000000000000ea48d38740680101b43f6d17de8e35,
//         0x0000000000000000000000000000000000000000000000000000000000000355
//     ];
//     let b: [Field; 3] = [
//         0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
//         0x0000000000000000000000000000000000c4a832748da6ad742a1fd81b787643,
//         0x000000000000000000000000000000000000000000000000000000000034df93
//     ];
//     let expected_quotient: [Field; 3] = [
//         0x0000000000000000000000000000000000373423c664d7b4108a16631d271c48, 0x0000000000000000000000000000000000dc52b6fd67c3293670f369cd9100b6, 0x000000000000000000000000000000000000000000000000000000000003a4fe
//     ];
//     let expected_remainder: [Field; 3] = [
//         0x00000000000000000000000000000000007ad74a6ab59fc786b288d0b2760cc2, 0x0000000000000000000000000000000000545d50595a9a818a28cdc8eb0237dc, 0x0000000000000000000000000000000000000000000000000000000000002427
//     ];
//     let params = BarrettParams {
//         redc_param: [
//             0x000000000000000000000000000000000059785d9f353021bcebb62866fe4394, 0x0000000000000000000000000000000000d18988e8129eac1d2961a01cc04eba, 0x0000000000000000000000000000000000000000000000000000000000015291
//         ],
//         modulus: [
//             0x0000000000000000000000000000000000816a916871ca8d3c208c16d87cfd47, 0x00000000000000000000000000000000004e72e131a029b85045b68181585d97, 0x0000000000000000000000000000000000000000000000000000000000003064
//         ],
//         k: 255,
//         modulus_bits: 254,
//         one: [1, 0, 0],
//         oneu: [1, 0, 0, 0, 0, 0],
//         one2: [1, 0, 0, 0, 0, 0],
//         one2u: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//         one3: [1, 0, 0, 0, 0, 0, 0, 0, 0],
//         one3u: U60Repr { limbs: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] }
//     };
//     let (quotient, remainder) = barrett_reduction(x, params);
//     let (q2, r2) = mulmod(a, b, params);
//     println(f"q2 = {q2}");
//     println(f"r2 = {r2}");
//     let expected_r2: [Field; 3] = [
//         0x000000000000000000000000000000000097ca8371adfb2eeec697c6ec1b1605,
//         0x0000000000000000000000000000000000d9acea8fce502aa3551906ae653500,
//         0x0000000000000000000000000000000000000000000000000000000000002143
//     ];
//     assert(q2 == expected_quotient);
//     assert(r2 == expected_r2);

//     let mut r2neg: bignum::BigNum<3, 6, 9, 12, 18, BNParams> = bignum::BigNum { limbs: r2, foobar: [0; 6] };
//     r2neg = r2neg.negate();

//     let u: Fq = bignum::BigNum { limbs: a, foobar: [0; 6] };
//     let v: Fq = bignum::BigNum { limbs: b, foobar: [0; 6] };

//     let foo = Fq::compute_quadratic_expression_quotient([u], [v], [], [], [r2neg], params);
//     let mut ffq = expected_quotient;
//     ffq[0] += 1;
//     assert(foo.limbs == ffq);
//     // println(f"foo = {foo}");
//     // let (quotient, remainder) = barrett_reduction(x, params);
//     // println(f"quotient = {quotient}");
//     // println(f"remainder = {remainder}");

//     assert(quotient == expected_quotient);
//     assert(remainder == expected_remainder);

//     // uv + wx - y = 0

//     let uu: Fq = bignum::BigNum {
//         limbs: [
//             0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
//             0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
//             0x000000000000000000000000000000000000000000000000000000000000063
//         ],
//         foobar: [0; 3]
//     };
//     let vv: Fq = bignum::BigNum {
//         limbs: [
//             0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
//             0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
//             0x0000000000000000000000000000000000000000000000000000000000000062
//         ],
//         foobar: [0; 3]
//     };

//     let w: Fq = bignum::BigNum {
//         limbs: [
//             0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
//             0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
//             0x0000000000000000000000000000000000000000000000000000000000001f93
//         ],
//         foobar: [0; 3]
//     };
//     let x: Fq = bignum::BigNum {
//         limbs: [
//             0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
//             0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
//             0x0000000000000000000000000000000000000000000000000000000000000f93
//         ],
//         foobar: [0; 3]
//     };

//     let uv = uu.mulmod(vv, params);
//     let q = uv.negate(params);
//     Fq::compute_quadratic_expression_quotient([uu], [vv], [], [], [q], params);

//     let wx = w.mulmod(x, params);
//     let y = (uv.addmod(wx, params)).negate(params);

//     Fq::compute_quadratic_expression_quotient([uu], [vv], [w], [x], [y], params);

//     Fq::evaluate_quadratic_expression([uu], [vv], [w], [x], [y], params);
//     //main(1, 2);
//     // Uncomment to make test fail
//     // main(1, 1);
// }

