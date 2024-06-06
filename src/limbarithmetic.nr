use dep::std;

trait FpParams<N> {
    let foo: [Field; N];

    fn bar(self) -> Field;
    // pub unconstrained fn bar() -> Field {
    //     let mut x: Field = 0;
    //     for i in 0..N {
    //         x += foo[i];
    //     }
    //     x
    // }
}

struct Flp {
    redc_param: [Field; 3]
}





struct BarrettParams<N, NU, N2, N2U, N3, N3U> {
    redc_param: [Field; N],
    modulus: [Field; N],
    k: u64,
    modulus_bits: u64,
    one: [Field; N],
    oneu: [Field; NU],
    one2: [Field; N2],
    one2u: [Field; N2U],
    one3: [Field; N3],
    one3u: U60Repr<N3, N3U>,
}

// Decomposes a single field into two 120 bit fields and a carry
unconstrained fn split_120_bits(x: Field) -> (Field, Field) {
    let x_bytes = x.to_le_bytes(32);

    let mut low: Field = 0;
    let mut high: Field = 0;

    let offsets: [Field; 16] = [
        1, 0x100, 0x10000, 0x1000000, 0x100000000, 0x10000000000, 0x1000000000000, 0x100000000000000, 0x10000000000000000, 0x1000000000000000000, 0x100000000000000000000, 0x10000000000000000000000, 0x1000000000000000000000000, 0x100000000000000000000000000, 0x10000000000000000000000000000, 0x1000000000000000000000000000000
    ];
    // 0 = 8
    // 13 * 8 = 80 + 24 = 104 bits + 8 = 112

    for i in 0..15 {
        // println(f"i = {i}");
        low += (x_bytes[i] as Field) * offsets[i];
        high += (x_bytes[i + 15] as Field) * offsets[i];
    }
    high += (x_bytes[30] as Field) * offsets[15];
    // 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29
    println(f"split 120 bits, lo = {low}");
    // 0xa4 84b36b8516bbc964703861900988 14 * 8 = 112
    // 116 + 4 = 120
    assert(x_bytes[31] == 0);
    let ff = x_bytes[31] as Field;
    println(f"last? {ff}");
    // high += (x_bytes[31] as Field) * offsets[15];
    (low, high)
}

// Decomposes a single field into two 60 bit fields
unconstrained fn split_60_bits(x: Field) -> (u64, u64) {
    let x_bytes = x.to_le_bytes(32);

    let mut low: u64 = 0;
    let mut high: u64 = 0;

    let offsets: [u64; 8] = [1, 0x100, 0x10000, 0x1000000, 0x100000000, 0x10000000000, 0x1000000000000, 0x100000000000000];
    for i in 0..8 {
        low += (x_bytes[i] as u64) * offsets[i];
        high += (x_bytes[i + 8] as u64) * offsets[i];
    }
    // low = low 64 bits
    // high = high 64 bits
    // [64][64]
    // [60][4][4][60]
    let t1 = low >> 60;
    let mask = ((1 as u64) << 60 as u8) - 1;
    low = low & mask;
    high = (high << 4) | t1;
    // high += (x_bytes[9] as u64) * offsets[8];
    (low, high)
}

struct U60Repr<NumU120Limbs, NumU60Limbs>
{
    limbs: [u64; NumU60Limbs]
}

unconstrained fn into_U60Repr<NumU120Limbs, NumU60Limbs>(x: [Field; NumU120Limbs]) -> U60Repr<NumU120Limbs, NumU60Limbs> {
    let mut result: U60Repr<NumU120Limbs, NumU60Limbs> = U60Repr { limbs: [0; NumU60Limbs] };

    for i in 0..NumU120Limbs {
        let (lo, hi) = split_60_bits(x[i]);
        result.limbs[2 * i] = lo;
        result.limbs[2 * i + 1] = hi;
    }
    result
}

unconstrained fn into_FieldRepr<NumU120Limbs, NumU60Limbs>(x: U60Repr<NumU120Limbs, NumU60Limbs>) -> [Field; NumU120Limbs] {
    let mut result: [Field; NumU120Limbs] = [0; NumU120Limbs];
    let two_pow_60: Field = 0x1000000000000000;
    for i in 0..NumU120Limbs {
        result[i] = x.limbs[2 * i] as Field + (x.limbs[2 * i + 1] as Field * two_pow_60);
    }
    result
}

impl<NumU120Limbs, N> U60Repr<NumU120Limbs, N> {
    // todo: validate this works for shifts that are not a factor of 60, and shift with value 0
    unconstrained fn right_shift(self, shift: u64) -> U60Repr<NumU120Limbs, N> {
        let a = self;
        let mut result: [u64; N] = [0; N];

        let num_shifted_limbs: u64 = shift / 60;
        let mut limb_shift = shift % 60;
        if (limb_shift == 0) {
            for i in 0..N {
                result[i] = a.limbs[i + num_shifted_limbs];
            }
        } else {
            let remainder_shift = 60 - limb_shift;
            let mask: u64 = (((1 as u64) << limb_shift as u8) - 1) << remainder_shift as u8;
            for i in 0..N - num_shifted_limbs {
                result[i] = (a.limbs[i + num_shifted_limbs] >> limb_shift as u8);
                if (i > 0) {
                    let remainder: u64 = (a.limbs[i + num_shifted_limbs] << remainder_shift as u8) & mask;
                    result[i - 1] += remainder;
                    let t3 = result[i - 1] as Field;
                }
            }
        }
        U60Repr { limbs: result }
    }

    // TODO: untested and probably buggy
    unconstrained fn left_shift(self, shift: u64) -> U60Repr<NumU120Limbs, N> {
        let a = self;
        let mut result: [u64; N] = [0; N];

        if (shift == 0) {
            result = a.limbs;
        } else {
            let num_shifted_limbs: u64 = shift / 60;
            let mut limb_shift = shift % 60;
            let mut shifted_limbs: [u64; N] = [0; N];
            if (limb_shift == 0) {
                for i in 0..N {
                    shifted_limbs[i] = a.limbs[i];
                }
            } else {
                let mut remainder: u64 = 0;
                for i in 0..N {
                    let remainder_shift = 60 - limb_shift;
                    shifted_limbs[i] = (a.limbs[i] << limb_shift as u8) + remainder;
                    remainder = a.limbs[i] >> remainder_shift as u8;
                }
            }

            for i in 0..N - num_shifted_limbs {
                result[i + num_shifted_limbs] = shifted_limbs[i];
            }
        }
        U60Repr { limbs: result }
    }

    unconstrained fn add(self, b: U60Repr<NumU120Limbs, N>) -> U60Repr<NumU120Limbs, N> {
        let a = self;
        let mut result: [u64; N] = [0; N];

        let mut carry: u64 = 0;
        for i in 0..N {
            result[i] = a.limbs[i] + b.limbs[i] + carry;
            carry = result[i] >> 60;
            result[i] = result[i] - (carry << 60);
        }
        U60Repr { limbs: result }
    }

    unconstrained fn sub(self, b: U60Repr<NumU120Limbs, N>) -> U60Repr<NumU120Limbs, N> {
        let mut result: [u64; N] = [0; N];

        let mut borrow: u64 = 0;
        let mut borrow_in: u64 = 0;
        for i in 0..N {
            if ((b.limbs[i] + borrow_in) > self.limbs[i]) {
                borrow = 1;
            } else {
                borrow = 0;
            }
            result[i] = (borrow << 60) + self.limbs[i] - b.limbs[i] - borrow_in;
            borrow_in = borrow;
        }
        U60Repr { limbs: result }
    }

    unconstrained fn gt(self, b: U60Repr<NumU120Limbs, N>) -> bool {
        let mut result = false;
        for i in 0..N {
            if (b.limbs[N - 1 - i] < (self.limbs[N - 1 - i])) {
                result = true;
                break;
            } else if (b.limbs[N - 1 - i] != (self.limbs[N - 1 - i])) {
                result = false;
                break;
            }
        }
        result
    }

    unconstrained fn gte(self, b: U60Repr<NumU120Limbs, N>) -> bool {
        let mut result = false;
        let mut early_exit = false;
        for i in 0..N {
            if (b.limbs[N - 1 - i] < (self.limbs[N - 1 - i])) {
                result = true;
                early_exit = true;
                break;
            } else if (b.limbs[N - 1 - i] != (self.limbs[N - 1 - i])) {
                result = false;
                early_exit = true;
                break;
            }
        }
        if (early_exit == false) {
            result = (self.limbs[0] == b.limbs[0]);
        }
        result
    }
}

unconstrained pub fn normalize_limbs<N>(x: [Field; N]) -> [Field; N] {
    let mut normalized: [Field; N] = [0 as Field; N];
    let mut inp: [Field; N] = x;
    for i in 0..N {
        let (lo, hi) = split_120_bits(inp[i]);

        normalized[i] = lo;
        if (i + 1 < N) {
            inp[i + 1] = inp[i + 1] + hi;
        } else {
            assert(hi == 0);
        }
    }
    normalized
}

unconstrained pub fn mul_limbs_and_normalize<N, N2, N3>(x: [Field; N], y: [Field; N2]) -> [Field; N3] {
    let mut muls: [Field; N3] = [0 as Field; N3];
    let mut mulout: [Field; N3] = [0 as Field; N3];

    for i in 0..N {
        for j in 0..N2 {
            muls[i + j] += x[i] * y[j];
        }
    }
    for i in 0..N3 {
        let (lo, hi) = split_120_bits(muls[i]);

        mulout[i] = lo;
        if (i + 1 < N3) {
            muls[i + 1] = muls[i + 1] + hi;
        }
    }
    mulout
}

unconstrained pub fn barrett_reduction<N, NU, N2, N2U, N3, N3U>(x: [Field; N2], params: BarrettParams<N, NU, N2, N2U, N3, N3U>) -> ([Field; N], [Field; N]) {
    let mulout: [Field; N3] = mul_limbs_and_normalize(x, params.redc_param);
    let mulout_u60: U60Repr<N3, N3U> = into_U60Repr(mulout);
    let mut quotient_u60: U60Repr<N3, N3U> = mulout_u60.right_shift(params.k + params.k);
    let partial_quotient: [Field; N3] = into_FieldRepr(quotient_u60);

    //   mulout
    let mut quotient_mul_modulus: [Field; N2] = [0; N2];
    let mut quotient_mul_modulus_normalized: [Field; N2] = [0; N2];
    for i in 0..N2 { // N2 or N3
        for j in 0..N {
            if (i + j < N2) {
                quotient_mul_modulus[i + j] += partial_quotient[i] * params.modulus[j];
            }
        }
    }

    for i in 0..(N2) {
        let (lo, hi) = split_120_bits(quotient_mul_modulus[i]);
        quotient_mul_modulus_normalized[i] = lo;
        if (i + 1 < N2) {
            quotient_mul_modulus[i + 1] = quotient_mul_modulus[i+1] + hi;
        }
    }

    let quotient_mul_modulus_u60 : U60Repr<N2, N2U> = into_U60Repr(quotient_mul_modulus_normalized);
    let x_u60 : U60Repr<N2, N2U> = into_U60Repr(x);

    let mut remainder_u60 = x_u60.sub(quotient_mul_modulus_u60);

    let mut modulus2: [Field; N2] = [0; N2];
    for i in 0..N {
        modulus2[i] = params.modulus[i];
    }
    let modulus_u60: U60Repr<N2, N2U> = into_U60Repr(modulus2);
    if (remainder_u60.gte(modulus_u60)) {
        remainder_u60 = remainder_u60.sub(modulus_u60);
        quotient_u60 = quotient_u60.add(params.one3u);
    }

    let t1 = into_FieldRepr(quotient_u60);
    let t2 = into_FieldRepr(remainder_u60);
    let mut quotient_fields: [Field; N] = [0; N];
    let mut remainder_fields: [Field; N] = [0; N];
    for i in 0..N {
        quotient_fields[i] = t1[i];
        remainder_fields[i] = t2[i];
    }
    (quotient_fields, remainder_fields)
}

struct BigNum<N>{
    limbs: [Field; N]
}

impl<N> BigNum<N> {

    pub fn validate_in_range<NU, N2, N2U, N3, N3U>(self, params: BarrettParams<N, NU, N2, N2U, N3, N3U>) {
        for i in 0..(N - 1) {
            self.limbs[i].assert_max_bit_size(120);
        }
        let final_limb_bits = params.modulus_bits - ((N - 1) * 120);
        self.limbs[N - 1].assert_max_bit_size(final_limb_bits as u32);
    }

    unconstrained pub fn mulmod_with_quotient<NU, N2, N2U, N3, N3U>(self, rhs: BigNum<N>, params: BarrettParams<N, NU, N2, N2U, N3, N3U>) -> (BigNum<N>, BigNum<N>) {
        let mul: [Field; N2] = mul_limbs_and_normalize(self.limbs, rhs.limbs);
        let (q, r) = barrett_reduction(mul, params);
        let a: BigNum<N> = BigNum { limbs: q };
        let b: BigNum<N> = BigNum { limbs: r };
        (a, b)
    }

    unconstrained pub fn mulmod<NU, N2, N2U, N3, N3U>(
        self,
        rhs: BigNum<N>,
        params: BarrettParams<N, NU, N2, N2U, N3, N3U>
    ) -> BigNum<N> {
        let mul: [Field; N2] = mul_limbs_and_normalize(self.limbs, rhs.limbs);
        let (_, r) = barrett_reduction(mul, params);
        let b: BigNum<N> = BigNum { limbs: r };
        b
    }

    unconstrained pub fn addmod<NU, N2, N2U, N3, N3U>(
        self,
        rhs: BigNum<N>,
        params: BarrettParams<N, NU, N2, N2U, N3, N3U>
    ) -> BigNum<N> {
        let x_u60 : U60Repr<N, NU> = into_U60Repr(self.limbs);
        let y_u60 : U60Repr<N, NU> = into_U60Repr(rhs.limbs);

        let mut z_u60 = x_u60.add(y_u60);
        let modulus_u60 : U60Repr<N, NU> = into_U60Repr(params.modulus);

        if z_u60.gt(modulus_u60) {
            z_u60 = z_u60.sub(modulus_u60);
        }
        BigNum { limbs: into_FieldRepr(z_u60) }
    }

    // TODO subtract 2x modulus
    unconstrained pub fn negate<NU, N2, N2U, N3, N3U>(
        self,
        params: BarrettParams<N, NU, N2, N2U, N3, N3U>
    ) -> BigNum<N> {
        let x_u60 : U60Repr<N, NU> = into_U60Repr(self.limbs);
        let modulus_u60 : U60Repr<N, NU> = into_U60Repr(params.modulus);
        BigNum { limbs: into_FieldRepr(modulus_u60.sub(x_u60)) }
    }

    // TODO subtract 2x modulus
    unconstrained pub fn submod<NU, N2, N2U, N3, N3U>(
        self,
        rhs: BigNum<N>,
        params: BarrettParams<N, NU, N2, N2U, N3, N3U>
    ) -> BigNum<N> {
        self.addmod(rhs.negate(params), params)
    }
}

unconstrained pub fn mulmod<N, NU, N2, N2U, N3, N3U>(
    x: [Field; N],
    y: [Field; N],
    params: BarrettParams<N, NU, N2, N2U, N3, N3U>
) -> ([Field; N], [Field; N]) {
    let mul: [Field; N2] = mul_limbs_and_normalize(x, y);
    barrett_reduction(mul, params)
}

unconstrained pub fn addmod<N, NU, N2, N2U, N3, N3U>(
    x: [Field; N],
    y: [Field; N],
    params: BarrettParams<N, NU, N2, N2U, N3, N3U>
) -> [Field; N] {
    let x_u60 : U60Repr<N, NU> = into_U60Repr(x);
    let y_u60 : U60Repr<N, NU> = into_U60Repr(y);

    let mut z_u60 = x_u60.add(y_u60);
    let modulus_u60 : U60Repr<N, NU> = into_U60Repr(params.modulus);

    if z_u60.gt(modulus_u60) {
        z_u60 = z_u60.sub(modulus_u60);
    }
    into_FieldRepr(z_u60)
}

unconstrained pub fn negate<N, NU, N2, N2U, N3, N3U>(
    x: [Field; N],
    params: BarrettParams<N, NU, N2, N2U, N3, N3U>
) -> [Field; N] {
    let x_u60 : U60Repr<N, NU> = into_U60Repr(x);
    let modulus_u60 : U60Repr<N, NU> = into_U60Repr(params.modulus);
    into_FieldRepr(modulus_u60.sub(x_u60))
}

unconstrained pub fn submod<N, NU, N2, N2U, N3, N3U>(
    x: [Field; N],
    y: [Field; N],
    params: BarrettParams<N, NU, N2, N2U, N3, N3U>
) -> [Field; N] {
    addmod(x, negate(y, params), params)
}

unconstrained pub fn add_linear_expression<N, NU, N2, N2U, N3, N3U, LHS_N, RHS_N>(
    x: [BigNum<N>; LHS_N],
    params: BarrettParams<N, NU, N2, N2U, N3, N3U>
) -> [Field; N] {
    // TODO, validate we do not overflow N2 when multiplying and N when adding
    let mut lhs_sum_u60: U60Repr<N, NU> = U60Repr { limbs: [0; NU] };
    for i in 0..LHS_N {
        let lhs_u60: U60Repr<N, NU> = into_U60Repr(x[i].limbs);
        lhs_sum_u60 = lhs_sum_u60.add(lhs_u60);
    }
    let lhs_sum: [Field; N] = into_FieldRepr(lhs_sum_u60);
    lhs_sum
}
unconstrained pub fn mul_linear_expressions<N, NU, N2, N2U, N3, N3U, LHS_N, RHS_N>(
    x: [BigNum<N>; LHS_N],
    y: [BigNum<N>; RHS_N],
    params: BarrettParams<N, NU, N2, N2U, N3, N3U>
) -> [Field; N2] {
    // TODO, validate we do not overflow N2 when multiplying and N when adding
    let lhs_sum: [Field; N] = add_linear_expression(x, params);
    let rhs_sum: [Field; N] = add_linear_expression(y, params);
    let mul: [Field; N2] = mul_limbs_and_normalize(lhs_sum, rhs_sum);
    mul
}

unconstrained pub fn compute_quadratic_expression_quotient<N, NU, N2, N2U, N3, N3U, LHS1_N, RHS1_N, LHS2_N, RHS2_N, ADD_N>(
    first_lhs_products: [BigNum<N>; LHS1_N],
    first_rhs_products: [BigNum<N>; RHS1_N],
    second_lhs_products: [BigNum<N>; LHS2_N],
    second_rhs_products: [BigNum<N>; RHS2_N],
    linear_terms: [BigNum<N>; ADD_N],
    params: BarrettParams<N, NU, N2, N2U, N3, N3U>
) -> BigNum<N> {
    // TODO, validate we do not overflow N2 when multiplying and N when adding
    let first_lhs_sum: [Field; N] = add_linear_expression(first_lhs_products, params);
    let first_rhs_sum: [Field; N] = add_linear_expression(first_rhs_products, params);
    let second_lhs_sum: [Field; N] = add_linear_expression(second_lhs_products, params);
    let second_rhs_sum: [Field; N] = add_linear_expression(second_rhs_products, params);
    let add: [Field; N] = add_linear_expression(linear_terms, params);

    let mut mulout: [Field; N2] = [0; N2];

    for i in 0..N {
        for j in 0..N {
            mulout[i+j] += first_lhs_sum[i] * first_rhs_sum[j];
            mulout[i+j] += second_lhs_sum[i] * second_rhs_sum[j];
        }
        mulout[i] += add[i];
    }
    // TODO: compute borrow flags here to save some redundant comps
    let relation_result = normalize_limbs(mulout);
    let (quotient, remainder) = barrett_reduction(relation_result, params);
    println(f"wtf REMAINDER EQUALS LAERIJFGKAERGFHOAERIRGJAOJ {remainder}");
    assert(remainder == [0; N]);
    BigNum { limbs: quotient }
}

unconstrained fn get_borrow_flags<N>(lhs: [Field; N], rhs: [Field; N]) -> [Field; N] {
    let mut result: [Field; N] = [0; N];
    for i in 0..N - 2 {
        if i > 0 {
            result[i] = lhs[i].lt(rhs[i] + (result[i-1] as Field * 0x4000000000000000000000000000000)) as Field;
        } else {
            result[i] = lhs[i].lt(rhs[i]) as Field;
        }
        let a = lhs[i];
        let b = rhs[i];
        let res = result[i];
        println(f"get borrow flags, lhs {a} , rhs {b}, res {res}, i = {i}");
    }
    result
}

unconstrained fn get_borrow_flags2<N, NU, N2, N2U, N3, N3U>(
    t0: [Field; N],
    t1: [Field; N],
    t2: [Field; N],
    t3: [Field; N],
    t4: [Field; N],
    quotient: [Field; N],
    params: BarrettParams<N, NU, N2, N2U, N3, N3U>
) -> [Field; N2] {
    let mut result: [Field; N2] = [0; N2];
    let mut lhs: [Field; N2] = [0; N2];
    let mut rhs: [Field; N2] = [0; N2];
    for i in 0..N {
        for j in 0..N {
            lhs[i+j] += (t0[i]*t1[j])+(t2[i]*t3[j]);
            rhs[i+j] += quotient[i]*params.modulus[j];
        }
        lhs[i] += t4[i];
    }

    for i in 0..(N2 - 2) {
        if i > 0 {
            result[i] = lhs[i].lt(rhs[i] + (result[i-1] as Field * 0x4000000000000000000000000000000)) as Field;
        } else {
            result[i] = lhs[i].lt(rhs[i]) as Field;
        }
        let a = lhs[i];
        let b = rhs[i];
        let res = result[i];
        println(f"get borrow flags 2, lhs {a} , rhs {b}, res {res}, i = {i}");
    }
    result
}

/**
 * @brief computes \sum_{first_lhs_products} * \sum_{first_rhs_products} + \sum_{second_lhs_products} * \sum_{second_rhs_products} + \sum_{linear_terms}
 *        and evaluates the result is 0 modulo `params.modulus`
 *        i.e. result = quotient * modulus
 *        This method is a primitive that can be used to efficiently constrain non-native field arithmetic
 **/
pub fn evaluate_quadratic_expression<N, NU, N2, N2U, N3, N3U, LHS1_N, RHS1_N, LHS2_N, RHS2_N, ADD_N>(
    first_lhs_products: [BigNum<N>; LHS1_N],
    first_rhs_products: [BigNum<N>; RHS1_N],
    second_lhs_products: [BigNum<N>; LHS2_N],
    second_rhs_products: [BigNum<N>; RHS2_N],
    linear_terms: [BigNum<N>; ADD_N],
    params: BarrettParams<N, NU, N2, N2U, N3, N3U>
) {
    // use an unconstrained function to compute the value of the quotient
    let quotient: BigNum<N> = compute_quadratic_expression_quotient(
        first_lhs_products,
        first_rhs_products,
        second_lhs_products,
        second_rhs_products,
        linear_terms,
        params
    );
    // constrain the quotient to be in the range [0, ..., 2^{m} - 1], where `m` is log2(modulus) rounded up.
    // Additionally, validate quotient limbs are also in the range [0, ..., 2^{120} - 1]
    quotient.validate_in_range(params);
    // TODO, validate we do not overflow N2 when multiplying and N when adding
    // (should be a compile-time check...unconstrained function?)

    // Compute the linear sums that represent lhs_1, rhs_1, lhs_2, rhs_2, add
    let mut t0: [Field; N] = [0; N];
    let mut t1: [Field; N] = [0; N];
    let mut t2: [Field; N] = [0; N];
    let mut t3: [Field; N] = [0; N];
                    let mut t4: [Field; N] = [0; N];
    for i in 0..N {
        for j in 0..LHS1_N {
            t0[i] += first_lhs_products[j].limbs[i];
        }
        for j in 0..RHS1_N {
            t1[i] += first_rhs_products[j].limbs[i];
        }
        for j in 0..LHS2_N {
            t2[i] += second_lhs_products[j].limbs[i];
        }
        for j in 0..RHS2_N {
            t3[i] += second_rhs_products[j].limbs[i];
        }
        for j in 0..ADD_N {
            t4[i] += linear_terms[j].limbs[i];
        }
    }
    // We want to evaluate that t0 * t1 + t2 * t3 + t4 - Quotient * Modulus = 0, evaluated over the integers
    // For this we need to be able to borrow values from more-significant limbs into less-significant limbs,
    // so that we can ensure that no limbs will underflow for an honest Prover
    let mut product_limbs: [Field; N2] = [0; N2];
    let mut borrow_flags: [Field; N2] = get_borrow_flags2(t0, t1, t2, t3, t4, quotient.limbs, params);

    // Compute the product t0 * t1 + t2 * t3 + t4 - Quotient * Modulus
    for i in 0..N {
        for j in 0..N {
            let new_term = t0[i] * t1[j] + t2[i] * t3[j] - quotient.limbs[i] * params.modulus[j];
            std::as_witness(new_term); // width-4 optimization (n.b. might not be optimal if t2, t3 input arrays are nonzero)
            product_limbs[i + j] += new_term;
        }
        product_limbs[i] += t4[i];
    }

    // each limb product represents the sum of 120-bit products.
    // by setting the borrow value to 2^246 we are restricting this method's completeness to expressions
    // where no more than 64 limb products are summed together.
    // TODO: check in unconstrained function that this condition is satisfied
    // TODO: define trade-offs regarding the value of borrow_shift
    // (the larger the value, the greater the range check that is required on product_limbs)
    // (126-bit range check is a sweet spot for the barretenberg backend as it decomposes into 9 14-bit range checks)
    // (the barretenberg backend can evaluate these in 5.25 gates. 127 bits costs 6.5 gates)
    let borrow_shift: Field = 0x40000000000000000000000000000000000000000000000000000000000000; // 2^{246}
    let borrow_carry: Field = 0x40000000000000000000000000000000; // 2^{246 - 120} = 2^{126}

    // N.B. borrow_flags is `Field` type because making it `bool` would apply boolean constraints to all `N2` array entries.
    //      We only use `N2 - 2` borrow flags so applying 1-bit range checks on the array elements we use is more efficient.
    // TODO: Once it is possible to perform arithmetic on generics we can use `borrow_flags: [bool;N+N-2]` to avoid this issue
    borrow_flags[0].assert_max_bit_size(1);
    product_limbs[0] += borrow_flags[0] * borrow_shift;
    for i in 1..(N2 - 2) {
        borrow_flags[i].assert_max_bit_size(1);
        product_limbs[i] += (borrow_flags[i] * borrow_shift - borrow_flags[i - 1] * borrow_carry);
    }
    product_limbs[N2 - 2] -= borrow_flags[N2 - 3] * borrow_carry;

    // Final step: Validate `product_limbs` represents the integer value `0`
    // Each element `i` in `product_limbs` overlaps in bitrange with element `i+1`, EXCEPT for the low 120 bits
    // i.e. we need to do the following for each limb `i`:
    //      1. validate the limb's low-120 bits equals zero
    //      2. compute the limb "carry" by right-shifting by 2^{120}
    //      3. add the carry into limb `i+1`
    // We can efficiently do all of the above by multiplying the limb by 2^{-120} and constraining the result to be <2^{126}
    // (if the low 120 bits are nonzero the result will underflow and product a large value that cannot be range constrained)
    // (the probability of an underflow value satisfying a 126-bit range constraint is approx. 2^{k - 126},
    //  where k is the number of bits in the prime field)
    // We then add the result into the next limb and repeat.
    let hi_shift: Field = 0x1000000000000000000000000000000;
    let hi_downshift: Field = 1 / hi_shift;
    for i in 0..N2 - 2 {
        product_limbs[i] *= hi_downshift;
        std::as_witness(product_limbs[i]);
        product_limbs[i].assert_max_bit_size(126); // N.B. is this sufficient? going beyond 126 costs us 1 gate per limb
        product_limbs[i + 1] += product_limbs[i];
    }
    // the most significant limb has no limb to "carry" values into - the entire limb must equal zero
    assert(product_limbs[N2 - 2] == 0);
}
