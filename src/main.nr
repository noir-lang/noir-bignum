mod bignum;
mod limbarithmetic;
use crate::limbarithmetic::ArrayX;
use crate::limbarithmetic::BNExpressionInput;

struct BNParams {}
impl limbarithmetic::ParameterTrait<3> for BNParams {
    fn redc_param() -> ArrayX<Field, 3,1> {
        ArrayX{segments: [[
            0x000000000000000000000000000000000059785d9f353021bcebb62866fe4394, 0x0000000000000000000000000000000000d18988e8129eac1d2961a01cc04eba, 0x0000000000000000000000000000000000000000000000000000000000015291
        ]]}
    }
    fn modulus() -> ArrayX<Field, 3,1> {
        ArrayX{ segments: [[
            0x0000000000000000000000000000000000816a916871ca8d3c208c16d87cfd47, 0x00000000000000000000000000000000004e72e131a029b85045b68181585d97, 0x0000000000000000000000000000000000000000000000000000000000003064
        ]]}
    }
    fn double_modulus() -> ArrayX<Field,3,1> {
        ArrayX{ segments: [[
            0x0000000000000000000000000000000000816a916871ca8d3c208c16d87cfd47, 0x00000000000000000000000000000000004e72e131a029b85045b68181585d97, 0x0000000000000000000000000000000000000000000000000000000000003064
        ]]}
    }
    fn k() -> u64 {
        255
    }
    fn modulus_bits() -> u64 {
        254
    }
    fn one3u() -> limbarithmetic::U60Repr<3, 6> {
       limbarithmetic::U60Repr { limbs: ArrayX{ segments: [[1, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]] }}
    }
}
type Fq = limbarithmetic::BigNum<3, BNParams>;

fn main(x: Field, y: pub Field) {
    let z = x + y;
    let a = z * z;
    let b = a * a;
    let c = b * b;
    let q = c * c;
    let r = q * q;
    let s = r * r;

    let mut lhs: Fq= limbarithmetic::BigNum { limbs: [x, y, z] };
    let rhs: Fq = limbarithmetic::BigNum { limbs: [a, b, c] };
    let mut lhs2 = BNExpressionInput::new(lhs, false);
    let rhs2= BNExpressionInput::new(rhs, false);

    for i in 0..101 {
        let out: Fq = lhs2.value.mulmod(rhs2.value);
        out.validate_in_range();
        let rem2 = BNExpressionInput::new(out, true);
        limbarithmetic::BigNum::evaluate_quadratic_expression([[lhs2]], [[rhs2]], [rem2]);
        lhs2.value = out;
    }
    // 68?
}

#[test]
fn test_main() {
    let x: [Field; 6] = [
        0x000000000000000000000000000000000083684820ff40795b8d9f1be2220cba, 0x0000000000000000000000000000000000d4924fbdc522b07b6cd0ef5508fd66, 0x0000000000000000000000000000000000d48f6c43c5930f3d70d6db09a48f4a,
        0x0000000000000000000000000000000000e7f72b2c0756704bea85be38352b34, 0x00000000000000000000000000000000000000000000000000000000b05d5ac5, 0
    ];
    let a: [Field; 3] = [
        0x000000000000000000000000000000000007f3d8208337197826e2e9ea000ed5,
        0x0000000000000000000000000000000000ea48d38740680101b43f6d17de8e35,
        0x0000000000000000000000000000000000000000000000000000000000000355
    ];
    let b: [Field; 3] = [
        0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
        0x0000000000000000000000000000000000c4a832748da6ad742a1fd81b787643,
        0x000000000000000000000000000000000000000000000000000000000034df93
    ];
    let expected_quotient: [Field; 3] = [
        0x0000000000000000000000000000000000373423c664d7b4108a16631d271c48, 0x0000000000000000000000000000000000dc52b6fd67c3293670f369cd9100b6, 0x000000000000000000000000000000000000000000000000000000000003a4fe
    ];
    let expected_remainder: [Field; 3] = [
        0x00000000000000000000000000000000007ad74a6ab59fc786b288d0b2760cc2, 0x0000000000000000000000000000000000545d50595a9a818a28cdc8eb0237dc, 0x0000000000000000000000000000000000000000000000000000000000002427
    ];

    let u: Fq = limbarithmetic::BigNum { limbs: a };
    let v: Fq = limbarithmetic::BigNum { limbs: b };

    let y: Fq = limbarithmetic::BigNum {
        limbs: [
            0x1,
            0x1,
            0x0
        ]
    };
    let z: Fq = limbarithmetic::BigNum {
        limbs: [
            0x2,
            0x2,
            0x0
        ]
    };
    let yy = y.addmod(y);
    println(f"yy = {yy}");
    println(f"zz = {z}");

    assert(yy.limbs == z.limbs);
    let r2: Fq = u.mulmod(v);
    let r2neg = r2.negate();
    //  let foo = limbarithmetic::BigNum::compute_quadratic_expression_quotient([u], [v], [], [], [r2neg]);
    let mut ffq = expected_quotient;
    ffq[0] += 1;
    //  let xxx = foo.limbs;
    //   println(f"result = {xxx}");
    //   println(f"expected = {ffq}");
    //   assert(foo.limbs == ffq);

    let uu: Fq = limbarithmetic::BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
            0x000000000000000000000000000000000000000000000000000000000000063
        ]
    };
    let vv: Fq = limbarithmetic::BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000000062
        ]
    };
    let w: Fq = limbarithmetic::BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000001f93
        ]
    };
    let x: Fq = limbarithmetic::BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000000f93
        ]
    };
    let wx = w.mulmod(x);
    let uv = uu.mulmod(vv);
    let y = (uv.addmod(wx)).negate();
    let z = uv.addmod(wx);
    let uuE: limbarithmetic::BNExpressionInput<3, BNParams> = limbarithmetic::BNExpressionInput { value: uu, is_negative: false };
    let vvE: limbarithmetic::BNExpressionInput<3, BNParams> = limbarithmetic::BNExpressionInput { value: vv, is_negative: false };
    let wE: limbarithmetic::BNExpressionInput<3, BNParams> = limbarithmetic::BNExpressionInput { value: w, is_negative: false };
    let xE: limbarithmetic::BNExpressionInput<3, BNParams> = limbarithmetic::BNExpressionInput { value: x, is_negative: false };
    let yE: limbarithmetic::BNExpressionInput<3, BNParams> = limbarithmetic::BNExpressionInput { value: y, is_negative: false };
    let zE: limbarithmetic::BNExpressionInput<3, BNParams> = limbarithmetic::BNExpressionInput { value: z, is_negative: true };

    limbarithmetic::BigNum::evaluate_quadratic_expression([[uuE], [wE]], [[vvE], [xE]], [zE]);
    main(1, 2);
    //main(1, 1);
    // assert(quotient == expected_quotient);
    // assert(remainder == expected_remainder);
    // // uv + wx - y = 0
    // let uu: Fq = limbarithmetic::BigNum {
    //     limbs: [
    //         0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
    //         0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
    //         0x000000000000000000000000000000000000000000000000000000000000063
    //     ],
    //     foobar: [0; 3]
    // };
    // let vv: Fq = limbarithmetic::BigNum {
    //     limbs: [
    //         0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
    //         0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
    //         0x0000000000000000000000000000000000000000000000000000000000000062
    //     ],
    //     foobar: [0; 3]
    // };
    // let w: Fq = limbarithmetic::BigNum {
    //     limbs: [
    //         0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
    //         0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
    //         0x0000000000000000000000000000000000000000000000000000000000001f93
    //     ],
    //     foobar: [0; 3]
    // };
    // let x: Fq = limbarithmetic::BigNum {
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

//     let mut r2neg: limbarithmetic::BigNum<3, 6, 9, 12, 18, BNParams> = limbarithmetic::BigNum { limbs: r2, foobar: [0; 6] };
//     r2neg = r2neg.negate();

//     let u: Fq = limbarithmetic::BigNum { limbs: a, foobar: [0; 6] };
//     let v: Fq = limbarithmetic::BigNum { limbs: b, foobar: [0; 6] };

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

//     let uu: Fq = limbarithmetic::BigNum {
//         limbs: [
//             0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
//             0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
//             0x000000000000000000000000000000000000000000000000000000000000063
//         ],
//         foobar: [0; 3]
//     };
//     let vv: Fq = limbarithmetic::BigNum {
//         limbs: [
//             0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
//             0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
//             0x0000000000000000000000000000000000000000000000000000000000000062
//         ],
//         foobar: [0; 3]
//     };

//     let w: Fq = limbarithmetic::BigNum {
//         limbs: [
//             0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
//             0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
//             0x0000000000000000000000000000000000000000000000000000000000001f93
//         ],
//         foobar: [0; 3]
//     };
//     let x: Fq = limbarithmetic::BigNum {
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
