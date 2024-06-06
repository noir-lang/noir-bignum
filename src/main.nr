mod bignum;
mod limbarithmetic;
use crate::limbarithmetic::barrett_reduction;
use crate::limbarithmetic::mulmod;
use crate::limbarithmetic::BarrettParams;
use crate::limbarithmetic::U60Repr;
use crate::limbarithmetic::compute_quadratic_expression_quotient;
use crate::limbarithmetic::BigNum;

fn main(x: Field, y: pub Field) {
    let z = x + y;
    let a = z * z;
    let b = a * a;
    let c = b * b;
    let q = c * c;
    let r = q * q;
    let s = r * r;
    let params = BarrettParams {
        redc_param: [
            0x000000000000000000000000000000000059785d9f353021bcebb62866fe4394, 0x0000000000000000000000000000000000d18988e8129eac1d2961a01cc04eba, 0x0000000000000000000000000000000000000000000000000000000000015291
        ],
        modulus: [
            0x0000000000000000000000000000000000816a916871ca8d3c208c16d87cfd47, 0x00000000000000000000000000000000004e72e131a029b85045b68181585d97, 0x0000000000000000000000000000000000000000000000000000000000003064
        ],
        k: 255,
        modulus_bits: 254,
        one: [1, 0, 0],
        oneu: [1, 0, 0, 0, 0, 0],
        one2: [1, 0, 0, 0, 0, 0],
        one2u: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        one3: [1, 0, 0, 0, 0, 0, 0, 0, 0],
        one3u: U60Repr { limbs: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] }
    };

    let mut lhs: BigNum<3> = BigNum { limbs: [x, y, z] };
    let rhs: BigNum<3> = BigNum { limbs: [a, b, c] };
    for i in 0..101 {
        let out: BigNum<3> = lhs.mulmod(rhs, params);
        out.validate_in_range(params);
        let remainder = out.negate(params);
        limbarithmetic::evaluate_quadratic_expression([lhs], [rhs], [], [], [remainder], params);
        lhs = out;
    }
    let tt = limbarithmetic::BigNum { limbs: [x, y, z] };
    //   1 mul:   5630 (extra 2824 gates because of bug)
    // 100 muls: 13599 = 136 per mul???
    // 101 muls: 13680 = 81 gates for additional mul
    // 102 muls: 13760 = 80 gates
    // 80.5 gates perm mul
    // 12 gates for remainder, 12 gates for quotient = 24.

    // NO RANGE CHECKS FOR QUOTIENT:REMAINDER
    // 1 mul: 2812
    // 101 mul: 8012
    // 52 gates per mul
    // => 23.5 gates from range checks ()
    // (ignoring constants)
    // tt.validate_in_range(params);
    // 11437
    // 11449 = 12 gates
    // 7480
    // 40 gates boo
    // 120 = 8 14 bit, 1 8-bit
    // 9 limbs =
    // x x x x
    // x x x s1
    // x x s1 s2 <-- 3 gates
    // 3 gates per limb, 2 limbs = 6 gates
    // 1 gate for final 14 bit limb = 7 gates
    // 19 range checks = 19/4 = +5 gates
    // = 12 gates? yay
    // 9102
    // 9165 = 63??
    // 11496
    // 11437 = 59?
    // 2827 to 7433
    // let mut foo: bignum::BigNum<2> = bignum::BigNum { limbs: [0, 1] };
    // let (u, v) = limbarithmetic::barrett_reduction<1,2,2,4,3,6>([1, 2], [10], [10], 1);
    assert(x != y);
    // assert(foo.test() == 1);
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
    let params = BarrettParams {
        redc_param: [
            0x000000000000000000000000000000000059785d9f353021bcebb62866fe4394, 0x0000000000000000000000000000000000d18988e8129eac1d2961a01cc04eba, 0x0000000000000000000000000000000000000000000000000000000000015291
        ],
        modulus: [
            0x0000000000000000000000000000000000816a916871ca8d3c208c16d87cfd47, 0x00000000000000000000000000000000004e72e131a029b85045b68181585d97, 0x0000000000000000000000000000000000000000000000000000000000003064
        ],
        k: 255,
        modulus_bits: 254,
        one: [1, 0, 0],
        oneu: [1, 0, 0, 0, 0, 0],
        one2: [1, 0, 0, 0, 0, 0],
        one2u: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        one3: [1, 0, 0, 0, 0, 0, 0, 0, 0],
        one3u: U60Repr { limbs: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] }
    };
    let (quotient, remainder) = barrett_reduction(x, params);
    let (q2, r2) = mulmod(a, b, params);
    println(f"q2 = {q2}");
    println(f"r2 = {r2}");
    let expected_r2: [Field; 3] = [
        0x000000000000000000000000000000000097ca8371adfb2eeec697c6ec1b1605,
        0x0000000000000000000000000000000000d9acea8fce502aa3551906ae653500,
        0x0000000000000000000000000000000000000000000000000000000000002143
    ];
    assert(q2 == expected_quotient);
    assert(r2 == expected_r2);

    let mut r2neg: limbarithmetic::BigNum<3> = limbarithmetic::BigNum { limbs: r2 };
    r2neg = r2neg.negate(params);

    let u: limbarithmetic::BigNum<3> = limbarithmetic::BigNum { limbs: a };
    let v: limbarithmetic::BigNum<3> = limbarithmetic::BigNum { limbs: b };

    let foo = limbarithmetic::compute_quadratic_expression_quotient([u], [v], [], [], [r2neg], params);
    let mut ffq = expected_quotient;
    ffq[0] += 1;
    assert(foo.limbs == ffq);
    // println(f"foo = {foo}");
    // let (quotient, remainder) = barrett_reduction(x, params);
    // println(f"quotient = {quotient}");
    // println(f"remainder = {remainder}");

    assert(quotient == expected_quotient);
    assert(remainder == expected_remainder);

    // uv + wx - y = 0

    let uu: limbarithmetic::BigNum<3> = BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
            0x000000000000000000000000000000000000000000000000000000000000063
        ]
    };
    let vv: limbarithmetic::BigNum<3> = BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000000062
        ]
    };

    let w: limbarithmetic::BigNum<3> = BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4a832748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e04080471712c1d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000001f93
        ]
    };
    let x: limbarithmetic::BigNum<3> = BigNum {
        limbs: [
            0x0000000000000000000000000000000000b4aec2748da6ad742a1fd81b787643,
            0x00000000000000000000000000000000009575f594e0408047171a01d7f18e89,
            0x0000000000000000000000000000000000000000000000000000000000000f93
        ]
    };

    let uv = uu.mulmod(vv, params);
    let q = uv.negate(params);
    limbarithmetic::compute_quadratic_expression_quotient([uu], [vv], [], [], [q], params);

    let wx = w.mulmod(x, params);
    let y = (uv.addmod(wx, params)).negate(params);

    limbarithmetic::compute_quadratic_expression_quotient([uu], [vv], [w], [x], [y], params);

    limbarithmetic::evaluate_quadratic_expression([uu], [vv], [w], [x], [y], params);
    //main(1, 2);
    // Uncomment to make test fail
    // main(1, 1);
}
