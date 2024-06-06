use crate::limbarithmetic::split_120_bits;

struct BigNum<NumLimbs>{
    limbs: [Field; NumLimbs]
}

struct FieldParams<NumLimbs> {
    NegativeModulus: [Field; NumLimbs]
}

impl<NumLimbs, N2> BigNum<NumLimbs> {

    fn test(self) -> Field {
        let mut result: Field = 0;
        for i in 0..NumLimbs {
            result += self.limbs[i];
        }
        result
    }

    fn evaluate_linear_relation<A, B, C>(
        mul_left: [BigNum<NumLimbs>; A],
        mul_right: [BigNum<NumLimbs>; B],
        add: [BigNum<NumLimbs>; C],
        params: FieldParams<NumLimbs>
    ) {
        let mut lhs_sum: [Field; NumLimbs] = [0; NumLimbs];
        let mut rhs_sum: [Field; NumLimbs] = [0; NumLimbs];
        let mut add_sum: [Field; NumLimbs] = [0; NumLimbs];
        for i in 0..NumLimbs {
            for j in 0..A {
                lhs_sum[i] += mul_left[j].limbs[i];
            }
            for j in 0..B {
                rhs_sum[i] += mul_right[j].limbs[i];
            }
            for j in 0..C {
                add_sum[i] += add[j].limbs[i];
            }
        }

        let mut product: [Field; N2] = [0; N2];

        for i in 0..NumLimbs {
            for j in 0..NumLimbs {
                product[i + j] += lhs_sum[i] * rhs_sum[j];
            }
            product[i] += add_sum[i];
        }

        let quotient = compute_quotient(product);

        for i in 0..NumLimbs {
            for j in 0..NumLimbs {
                product[i + j] += quotient.limbs[i] * params.NegativeModulus[j];
            }
        }
        for i in 0..NumLimbs + NumLimbs {
            let (lo, hi) = split_120_bits(product[i]);
            hi.assert_max_bit_size(126); // TODO: compute this exactly
            assert(lo == 0);
            let two_pow_120: Field = 0x1000000000000000000000000000000;
            assert(hi * two_pow_120 == product[i]);
            if (i != NumLimbs + NumLimbs - 1) {
                product[i + 1] += hi;
            } else {
                assert(hi == 0);
            }
        }
    }
}

unconstrained fn compute_quotient<NumLimbs, N2>(product: [Field; N2]) -> BigNum<NumLimbs> {
    let mut product: [Field; N2] = [0; N2];

    for i in 0..N2 {}

    let mut foo: BigNum<NumLimbs> = BigNum { limbs: [0; NumLimbs] };
    foo
}
