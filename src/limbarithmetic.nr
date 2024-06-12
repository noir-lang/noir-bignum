use dep::std;

// Decomposes a single field into two 120 bit fields and a carry
unconstrained fn split_120_bits(x: Field) -> (Field, Field) {
    let x_bytes = x.to_le_bytes(32);

    let mut low: Field = 0;
    let mut high: Field = 0;

    comptime let offsets: [Field; 16] = [
        1, 0x100, 0x10000, 0x1000000, 0x100000000, 0x10000000000, 0x1000000000000, 0x100000000000000, 0x10000000000000000, 0x1000000000000000000, 0x100000000000000000000, 0x10000000000000000000000, 0x1000000000000000000000000, 0x100000000000000000000000000, 0x10000000000000000000000000000, 0x1000000000000000000000000000000
    ];

    for i in 0..15 {
        low += (x_bytes[i] as Field) * offsets[i];
        high += (x_bytes[i + 15] as Field) * offsets[i];
    }
    high += (x_bytes[30] as Field) * offsets[15];
    assert(x_bytes[31] == 0);
    (low, high)
}

// Decomposes a single field into two 60 bit fields
unconstrained fn split_60_bits(x: Field) -> (u64, u64) {
    let x_bytes = x.to_le_bytes(32);

    let mut low: u64 = 0;
    let mut high: u64 = 0;

    comptime let offsets: [u64; 8] = [1, 0x100, 0x10000, 0x1000000, 0x100000000, 0x10000000000, 0x1000000000000, 0x100000000000000];
    for i in 0..8 {
        low += (x_bytes[i] as u64) * offsets[i];
        high += (x_bytes[i + 8] as u64) * offsets[i];
    }
    let t1 = low >> 60;
    let mask = ((1 as u64) << 60 as u8) - 1;
    low = low & mask;
    high = (high << 4) | t1;
    (low, high)
}

struct U60Repr<N, NumSegments>
{
    limbs: ArrayX<u64, N, NumSegments>
}

impl<N, NumSegments, NumSegments2> U60Repr<N, NumSegments> {
    unconstrained fn into_U60Repr<NumFieldSegments>(x: ArrayX<Field, N, NumFieldSegments>) -> U60Repr<N, NumSegments> {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };
        for i in 0..(N * NumFieldSegments) {
            let (lo, hi) = split_60_bits(x.get(i));
            result.limbs.set(2 * i, lo);
            result.limbs.set(2 * i + 1, hi);
        }
        result
    }

    unconstrained fn into_U60Reprasic(x: [Field; N]) -> U60Repr<N, NumSegments> {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };

        for i in 0..N {
            let (lo, hi) = split_60_bits(x[i]);
            result.limbs.set(2 * i, lo);
            result.limbs.set(2 * i + 1, hi);
        }
        result
    }

    unconstrained fn into_FieldRepr<NumFieldSegments>(x: U60Repr<N, NumSegments>) -> ArrayX<Field, N, NumFieldSegments> {
        let mut result: ArrayX<Field, N, NumFieldSegments> = ArrayX { segments: [[0; N]; NumFieldSegments] };
        let two_pow_60: Field = 0x1000000000000000;
        for i in 0..(N * NumFieldSegments) {
            result.set(
                i,
                x.limbs.get(2 * i) as Field + (x.limbs.get(2 * i + 1) as Field * two_pow_60)
            );
        }
        result
    }

    unconstrained fn into_FieldReprArr<NumFieldSegments>(x: U60Repr<N, NumSegments>) -> [Field; N] {
        let mut result: [Field; N] = [0; N];
        let two_pow_60: Field = 0x1000000000000000;
        for i in 0..N {
            result[i] = x.limbs.get(2 * i) as Field + (x.limbs.get(2 * i + 1) as Field * two_pow_60);
        }
        result
    }

    unconstrained fn right_shift(self, shift: u64) -> Self {
        let a = self;
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };

        let num_shifted_limbs: u64 = shift / 60;
        let mut limb_shift = shift % 60;
        if (limb_shift == 0) {
            for i in 0..(N * NumSegments) {
                result.limbs.set(i, a.limbs.get(i + num_shifted_limbs));
            }
        } else {
            let remainder_shift = 60 - limb_shift;
            let mask: u64 = (((1 as u64) << limb_shift as u8) - 1) << remainder_shift as u8;
            for i in 0..((N * NumSegments) - num_shifted_limbs) {
                result.limbs.set(i, (a.limbs.get(i + num_shifted_limbs) >> limb_shift as u8));
                if (i > 0) {
                    let remainder: u64 = (a.limbs.get(i + num_shifted_limbs) << remainder_shift as u8) & mask;
                    result.limbs.set(i - 1, result.limbs.get(i - 1) + remainder);
                    let t3 = result.limbs.get(i - 1) as Field;
                }
            }
        }
        result
    }

    unconstrained fn add(self, b: Self) -> Self {
        let a = self;
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };

        let mut carry: u64 = 0;
        for i in 0..(N * NumSegments) {
            let mut add: u64 = a.limbs.get(i) + b.limbs.get(i) + carry;
            carry = add >> 60;
            add = add - (carry << 60);
            result.limbs.set(i, add);
        }
        result
    }

    unconstrained fn sub(self, b: Self) -> Self {
        let mut result: Self = U60Repr { limbs: ArrayX { segments: [[0; N]; NumSegments] } };

        let mut borrow: u64 = 0;
        let mut borrow_in: u64 = 0;
        for i in 0..(N * NumSegments) {
            borrow = ((b.limbs.get(i) + borrow_in) > self.limbs.get(i)) as u64;
            let sub = (borrow << 60) + self.limbs.get(i) - b.limbs.get(i) - borrow_in;
            result.limbs.set(i, sub);
            borrow_in = borrow;
        }
        result
    }

    unconstrained fn gte(self, b: Self) -> bool {
        let mut result = false;
        let mut early_exit = false;
        for i in 0..(N * NumSegments) {
            if (b.limbs.get((N * NumSegments) - 1 - i) < (self.limbs.get((N * NumSegments) - 1 - i))) {
                result = true;
                early_exit = true;
                break;
            } else if (b.limbs.get((N * NumSegments) - 1 - i) != (self.limbs.get((N * NumSegments) - 1 - i))) {
                result = false;
                early_exit = true;
                break;
            }
        }
        if (early_exit == false) {
            result = (self.limbs.get(0) == b.limbs.get(0));
        }
        result
    }
}

struct ArrayX<T, N, SizeMultiplier> {
    segments: [[T; N]; SizeMultiplier]
}

impl<T, N, SizeMultiplier> ArrayX<T, N, SizeMultiplier> {

    fn new() -> Self where T: std::default::Default {
        ArrayX { segments: [[T::default(); N]; SizeMultiplier] }
    }

    fn add_assign(&mut self, i: u64, rhs: T) where T: std::ops::Add {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index] += rhs;
    }

    fn sub_assign(&mut self, i: u64, rhs: T) where T: std::ops::Sub {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index] -= rhs;
    }

    fn set(&mut self, i: u64, x: T) {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index] = x;
    }

    fn get(mut self, i: u64) -> T {
        let segment = i / N;
        let index = i % N;
        self.segments[segment][index]
    }
}

trait ParameterTrait<N> {
    fn redc_param() -> ArrayX<Field, N, 1>;
    fn modulus() -> ArrayX<Field, N, 1>;
    fn double_modulus() -> ArrayX<Field, N, 1>;
    fn k() -> u64;
    fn modulus_bits() -> u64;
    fn one3u() -> U60Repr<N, 6>;
}

struct BigNum<N,Params>{
    limbs: [Field; N],
}

unconstrained pub fn mul_limbs_and_normalizeC<N, SegmentsA, SegmentsB, SegmentsC>(x: ArrayX<Field, N, SegmentsA>, y: ArrayX<Field, N, SegmentsB>) -> ArrayX<Field, N, SegmentsC> {
    let mut muls: ArrayX<Field, N, SegmentsC>  = ArrayX { segments: [[0; N]; SegmentsC] };
    let mut mulout: ArrayX<Field, N, SegmentsC>  = ArrayX { segments: [[0; N]; SegmentsC] };

    for i in 0..(N * SegmentsA) {
        for j in 0..(N * SegmentsB) {
            muls.set(i + j, muls.get(i + j) + x.get(i) * y.get(j));
        }
    }
    for i in 0..(N * SegmentsC) {
        let (lo, hi) = split_120_bits(muls.get(i));

        mulout.set(i, lo);
        if (i + 1 < (N * SegmentsC)) {
            muls.set(i + 1, muls.get(i + 1) + hi);
        }
    }
    mulout
}
unconstrained pub fn mul_limbs_and_normalizeBasic<N, SegmentsC>(
    x: [Field; N],
    y: [Field; N]
) -> ArrayX<Field, N, SegmentsC> {
    let mut muls: ArrayX<Field, N, SegmentsC>  = ArrayX { segments: [[0; N]; SegmentsC] };
    let mut mulout: ArrayX<Field, N, SegmentsC>  = ArrayX { segments: [[0; N]; SegmentsC] };

    for i in 0..(N) {
        for j in 0..(N) {
            muls.set(i + j, muls.get(i + j) + x[i] * y[j]);
        }
    }
    for i in 0..(N * SegmentsC) {
        let (lo, hi) = split_120_bits(muls.get(i));

        mulout.set(i, lo);
        if (i + 1 < (N * SegmentsC)) {
            muls.set(i + 1, muls.get(i + 1) + hi);
        }
    }
    mulout
}

unconstrained pub fn normalize_limbsC<N, NumSegments>(x: ArrayX<Field, N, NumSegments>) -> ArrayX<Field, N, NumSegments> {
    let mut normalized: ArrayX<Field, N, NumSegments> = ArrayX::new();
    let mut inp = x;
    for i in 0..(N * NumSegments) {
        let (lo, hi) = split_120_bits(inp.get(i));

        normalized.set(i, lo);
        if (i + 1 < (N * NumSegments)) {
            inp.set(i + 1, inp.get(i + 1) + hi);
        } else {
            assert(hi == 0);
        }
    }
    normalized
}

fn barrett_reductionC<N, Params>(
    x: ArrayX<Field, N, 2>,
    redc_param: ArrayX<Field, N, 1>,
    k: u64,
    modulus: ArrayX<Field, N, 1>,
    one3u: U60Repr<N, 6>
) -> ([Field; N], [Field; N]) {
    let mulout: ArrayX<Field, N, 3> = mul_limbs_and_normalizeC(x, redc_param);
    let mulout_u60: U60Repr<N, 6> = U60Repr::into_U60Repr(mulout);
    let mut quotient_u60 = mulout_u60.right_shift(k + k);
    let partial_quotient: ArrayX<Field, N,3> = quotient_u60.into_FieldRepr();

    //   mulout
    let mut quotient_mul_modulus: ArrayX<Field, N, 2>  = ArrayX { segments: [[0; N]; 2] };
    let mut quotient_mul_modulus_normalized: ArrayX<Field, N, 2>  = ArrayX { segments: [[0; N]; 2] };

    for i in 0..(N + N) { // N2 or N3
        for j in 0..N {
            if (i + j < (N + N)) {
                quotient_mul_modulus.add_assign(i + j, partial_quotient.get(i) * modulus.get(j));
                // quotient_mul_modulus.set(
                //     i + j,
                //     quotient_mul_modulus.get(i + j) + partial_quotient.get(i) * modulus.get(j)
                // );
            }
        }
    }

    for i in 0..(N + N) {
        let (lo, hi) = split_120_bits(quotient_mul_modulus.get(i));
        quotient_mul_modulus_normalized.set(i, lo);
        if (i + 1 < N + N) {
            quotient_mul_modulus.set(i + 1, quotient_mul_modulus.get(i + 1) + hi);
        }
    }

    let quotient_mul_modulus_u60: U60Repr<N, 4> = U60Repr::into_U60Repr(quotient_mul_modulus_normalized);

    let x_u60 : U60Repr<N, 4> = U60Repr::into_U60Repr(x);

    let mut remainder_u60 = x_u60.sub(quotient_mul_modulus_u60);

    let modulus_u60: U60Repr<N, 4> = U60Repr::into_U60Repr(modulus); // TODO make double modulus
    if (remainder_u60.gte(modulus_u60)) {
        remainder_u60 = remainder_u60.sub(modulus_u60);
        quotient_u60 = quotient_u60.add(one3u);
    }

    let t1: ArrayX<Field, N, 2> = U60Repr::into_FieldRepr(quotient_u60);
    let t2: ArrayX<Field, N, 2> = U60Repr::into_FieldRepr(remainder_u60);
    let mut quotient_fields: [Field; N] = [0; N];
    let mut remainder_fields: [Field; N] = [0; N];
    for i in 0..N {
        quotient_fields[i] = t1.get(i);
        remainder_fields[i] = t2.get(i);
    }

    //   ([0; N], [0; N])

    (quotient_fields, remainder_fields)
}

struct BNExpressionInput<N, Params> {
    value: BigNum<N, Params>,
    is_negative: bool,
 }

impl<N, Params> BNExpressionInput<N, Params> {

    fn new() -> Self where BigNum<N, Params>: std::default::Default {
        BNExpressionInput { value: BigNum::new(), is_negative: false }
    }
    fn new(input: BigNum<N, Params>) -> Self {
        BNExpressionInput { value: input, is_negative: false }
    }
    fn new(input: BigNum<N, Params>, _is_negative: bool) -> Self {
        BNExpressionInput { value: input, is_negative: _is_negative }
    }
}
impl<N, Params>  BigNum<N, Params> {

    fn new() -> Self {
        BigNum { limbs: [0; N] }
    }
    pub fn validate_in_range(self) where Params: ParameterTrait<N> {
        for i in 0..(N - 1) {
            self.limbs[i].assert_max_bit_size(120);
        }
        let final_limb_bits = Params::modulus_bits() - ((N - 1) * 120);
        self.limbs[N - 1].assert_max_bit_size(final_limb_bits as u32);
    }

    fn mulmod_with_quotient(self, rhs: Self) -> (Self, Self) where Params: ParameterTrait<N> {
        //     let params = BarrettParams {
        //     redc_param: [
        //         0x000000000000000000000000000000000059785d9f353021bcebb62866fe4394, 0x0000000000000000000000000000000000d18988e8129eac1d2961a01cc04eba, 0x0000000000000000000000000000000000000000000000000000000000015291
        //     ],
        //     modulus: [
        //         0x0000000000000000000000000000000000816a916871ca8d3c208c16d87cfd47, 0x00000000000000000000000000000000004e72e131a029b85045b68181585d97, 0x0000000000000000000000000000000000000000000000000000000000003064
        //     ],
        //     k: 255,
        //     modulus_bits: 254,
        //     one: [1, 0, 0],
        //     oneu: [1, 0, 0, 0, 0, 0],
        //     one2: [1, 0, 0, 0, 0, 0],
        //     one2u: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        //     one3: [1, 0, 0, 0, 0, 0, 0, 0, 0],
        //     one3u: U60Repr { limbs: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] }
        // };
        let mul: ArrayX<Field, N,2> = mul_limbs_and_normalizeBasic(self.limbs, rhs.limbs);
        // let fff: Params<N, N2, N3, N4, N6> = Params{};
        let (q, r) = barrett_reductionC(
            mul,
            Params::redc_param(),
            Params::k(),
            Params::modulus(),
            Params::one3u()
        );

        let a: Self = Self { limbs: q };
        let b: Self = Self { limbs: r };
        //let a: Self = Self { limbs: [0; N] };
        //let b: Self = Self { limbs: [0; N] };

        (a, b)
    }

    unconstrained pub fn mulmod(self, rhs: Self) -> Self where Params: ParameterTrait<N> {
        let mul: ArrayX<Field, N,2> = mul_limbs_and_normalizeBasic(self.limbs, rhs.limbs);
        let (_, r) = barrett_reductionC(
            mul,
            Params::redc_param(),
            Params::k(),
            Params::modulus(),
            Params::one3u()
        );
        let b: Self = Self { limbs: r };
        b
    }

    unconstrained pub fn addmod(self, rhs: Self) -> Self where Params: ParameterTrait<N> {
        let x_u60 : U60Repr<N, 2> = U60Repr::into_U60Reprasic(self.limbs);
        let y_u60 : U60Repr<N, 2> = U60Repr::into_U60Reprasic(rhs.limbs);

        println(f"xu60repr = {x_u60}");
        println(f"yu60repr = {y_u60}");
        let mut z_u60 = x_u60.add(y_u60);
        println(f"zu60repr = {z_u60}");

        let modulus_u60 : U60Repr<N,2> = U60Repr::into_U60Repr(Params::modulus());
        let mmm = Params::modulus();
        println(f"modulus base = {mmm}");
        println(f"modulus repr = {modulus_u60}");
        if z_u60.gte(modulus_u60) {
            z_u60 = z_u60.sub(modulus_u60);
        }
        Self { limbs: U60Repr::into_FieldReprArr(z_u60) }
    }

    // // TODO subtract 2x modulus
    unconstrained pub fn negate(self) -> Self where Params: ParameterTrait<N> {
        let x_u60 : U60Repr<N, 2> = U60Repr::into_U60Reprasic(self.limbs);
        let modulus_u60 : U60Repr<N, 2> = U60Repr::into_U60Repr(Params::modulus());
        Self { limbs: U60Repr::into_FieldReprArr(modulus_u60.sub(x_u60)) }
    }

    // // TODO subtract 2x modulus
    unconstrained pub fn submod(self, rhs: Self) -> Self where Params: ParameterTrait<N> {
        self.addmod(rhs.negate())
    }

    unconstrained pub fn add_linear_expression<LHS_N, RHS_N>(x: [Self; LHS_N]) -> [Field; N] where Params: ParameterTrait<N> {
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        let mut lhs_sum_u60: U60Repr<N, 2> = U60Repr { limbs: ArrayX { segments: [[0; N]; 2] } };

        for i in 0..LHS_N {
            let lhs_u60: U60Repr<N, 2> = U60Repr::into_U60Reprasic(x[i].limbs);
            lhs_sum_u60 = lhs_sum_u60.add(lhs_u60);
        }
        let lhs_sum: [Field; N] = U60Repr::into_FieldReprArr(lhs_sum_u60);
        lhs_sum
    }

    unconstrained pub fn mul_linear_expressions<LHS_N, RHS_N>(
        x: [Self; LHS_N],
        y: [Self; RHS_N]
    ) -> ArrayX<Field, N, 2> where Params: ParameterTrait<N> {
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        let lhs_sum: [Field; N] = BigNum::add_linear_expression(x);
        let rhs_sum: [Field; N] = BigNum::add_linear_expression(y);
        let mul: ArrayX<Field, N, 2> = mul_limbs_and_normalizeC(
            ArrayX { segments: [lhs_sum] },
            ArrayX { segments: [rhs_sum] }
        );
        mul
    }

    unconstrained pub fn add_linear_expressionB<M>(x: [BNExpressionInput<N, Params>; M]) -> ([Field; N], [Field; N]) where Params: ParameterTrait<N> {
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        let mut lhs_sum_u60_p: U60Repr<N, 2> = U60Repr { limbs: ArrayX { segments: [[0; N]; 2] } };
        let mut lhs_sum_u60_n: U60Repr<N, 2> = U60Repr { limbs: ArrayX { segments: [[0; N]; 2] } };
        let modulus2_u60: U60Repr<N, 2> = U60Repr::into_U60Repr(Params::modulus());
        for i in 0..M {
            let mut lhs_u60: U60Repr<N, 2> = U60Repr::into_U60Reprasic(x[i].value.limbs);
            if (x[i].is_negative) {
                lhs_sum_u60_p = lhs_sum_u60_p.add(modulus2_u60);
                lhs_sum_u60_n = lhs_sum_u60_n.add(lhs_u60);
            } else {
                lhs_sum_u60_p = lhs_sum_u60_p.add(lhs_u60);
            }
        }
        let lhs_sum_p: [Field; N] = U60Repr::into_FieldReprArr(lhs_sum_u60_p);
        let lhs_sum_n: [Field; N] = U60Repr::into_FieldReprArr(lhs_sum_u60_n);
        (lhs_sum_p, lhs_sum_n)
    }

    unconstrained pub fn compute_quadratic_expression_quotient<LHS_N, RHS_N, NUM_PRODUCTS, ADD_N>(
        lhs_terms: [[BNExpressionInput<N, Params>; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[BNExpressionInput<N, Params>; RHS_N]; NUM_PRODUCTS],
        linear_terms: [BNExpressionInput<N, Params>; ADD_N]
    ) -> (Self, ArrayX<Field, N, 2>) where Params: ParameterTrait<N> {
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        let mut lhs_p: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
        let mut lhs_n: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
        let mut rhs_p: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
        let mut rhs_n: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
        let mut add_p: [Field; N] = [0; N];
        let mut add_n: [Field; N] = [0; N];

        for i in 0..NUM_PRODUCTS {
            let (l_p, l_n): ([Field; N], [Field; N]) = BigNum::add_linear_expressionB(lhs_terms[i]);
            let (r_p, r_n): ([Field; N], [Field; N]) = BigNum::add_linear_expressionB(rhs_terms[i]);
            lhs_p[i] = l_p;
            lhs_n[i] = l_n;
            rhs_p[i] = r_p;
            rhs_n[i] = r_n;
        }
        let (add_p, add_n): ([Field; N], [Field; N]) = BigNum::add_linear_expressionB(linear_terms);

        let mut mulout_p: ArrayX<Field, N,2> = ArrayX::new();
        let mut mulout_n: ArrayX<Field, N,2> = ArrayX::new();

        for i in 0..N {
            for j in 0..N {
                for k in 0..NUM_PRODUCTS {
                    assert(lhs_n[k][i] == 0);
                    assert(rhs_n[k][i] == 0);
                    mulout_p.add_assign(i + j, lhs_p[k][i] * rhs_p[k][j]);
                    mulout_n.add_assign(i + j, lhs_n[k][i] * rhs_n[k][j]);
                }
            }
            mulout_p.add_assign(i, add_p[i]);
            mulout_n.add_assign(i, add_n[i]);
        }

        let T0: ArrayX<Field, N, 2> = normalize_limbsC(mulout_p);
        let T1: ArrayX<Field, N, 2> = normalize_limbsC(mulout_n);

        let mulout_pu60: U60Repr<N, 4> = U60Repr::into_U60Repr(T0);
        let mulout_nu60: U60Repr<N, 4> = U60Repr::into_U60Repr(T1);
        let relation_result: ArrayX<Field, N, 2> = normalize_limbsC(U60Repr::into_FieldRepr(mulout_pu60.sub(mulout_nu60)));

        let (quotient, remainder) = barrett_reductionC(
            relation_result,
            Params::redc_param(),
            Params::k(),
            Params::modulus(),
            Params::one3u()
        );
        assert(remainder == [0; N]);

        for i in 0..N {
            for j in 0..N {
                mulout_n.add_assign(i + j, quotient[i] * Params::modulus().get(j));
            }
        }

        // compute borrow flags from mulout_p and mulout_n
        let mut borrow_flags: ArrayX<Field, N, 2> = ArrayX::new();
        let borrow_shift: Field = 0x4000000000000000000000000000000;
        for i in 0..(N + N - 2) {
            if i > 0 {
                let res: Field = mulout_p.get(i).lt(mulout_n.get(i) + (borrow_flags.get(i - 1) * borrow_shift)) as Field;
                borrow_flags.set(i, res);
            } else {
                borrow_flags.set(i, mulout_p.get(i).lt(mulout_n.get(i)) as Field);
            }
        }

        (Self { limbs: quotient }, borrow_flags)
    }

    fn evaluate_quadratic_expression<LHS_N, RHS_N, NUM_PRODUCTS, ADD_N>(
        lhs_products: [[BNExpressionInput<N, Params>; LHS_N]; NUM_PRODUCTS],
        rhs_products: [[BNExpressionInput<N, Params>; RHS_N]; NUM_PRODUCTS],
        linear_terms: [BNExpressionInput<N, Params>; ADD_N]
    ) where Params: ParameterTrait<N> {
        // use an unconstrained function to compute the value of the quotient
        let (quotient, borrow_flags): (Self, ArrayX<Field, N, 2>) = BigNum::compute_quadratic_expression_quotient(lhs_products, rhs_products, linear_terms);
        // constrain the quotient to be in the range [0, ..., 2^{m} - 1], where `m` is log2(modulus) rounded up.
        // Additionally, validate quotient limbs are also in the range [0, ..., 2^{120} - 1]
        quotient.validate_in_range();
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        // (should be a compile-time check...unconstrained function?)

        // Compute the linear sums that represent lhs_1, rhs_1, lhs_2, rhs_2, add
        let mut t0: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
        let mut t1: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
        let mut t4: [Field; N] = [0; N];
        for k in 0..NUM_PRODUCTS {
            for i in 0..N {
                for j in 0..LHS_N {
                    // note: if is_negative is not known at comptime this is vvvvvery expensive
                    let is_negative: bool = lhs_products[k][j].is_negative;
                    if (is_negative) {
                        t0[k][i] -= lhs_products[k][j].value.limbs[i];
                        t0[k][i] += Params::modulus().get(i); // TODO twice mox
                    } else {
                        t0[k][i] += lhs_products[k][j].value.limbs[i];
                    }
                }
                for j in 0..RHS_N {
                    let is_negative: bool = rhs_products[k][j].is_negative;
                    if (is_negative) {
                        t1[k][i] -= rhs_products[k][j].value.limbs[i];
                        t1[k][i] += Params::modulus().get(i); // TODO twice mox
                    } else {
                        t1[k][i] += rhs_products[k][j].value.limbs[i];
                    }
                }
            }
        }
        for i in 0..N {
            for j in 0..ADD_N {
                let is_negative: bool = linear_terms[j].is_negative;
                if (is_negative) {
                    t4[i] -= linear_terms[j].value.limbs[i];
                    t4[i] += Params::modulus().get(i); // TODO twice mox
                } else {
                    t4[i] += linear_terms[j].value.limbs[i];
                }
            }
        }
        // We want to evaluate that t0 * t1 + t2 * t3 + t4 - Quotient * Modulus = 0, evaluated over the integers
        // For this we need to be able to borrow values from more-significant limbs into less-significant limbs,
        // so that we can ensure that no limbs will underflow for an honest Prover
        let mut product_limbs: ArrayX<Field, N,2> = ArrayX::new();
        //       let fff: [Field; N] = quotient.limbs;
        //      let mut borrow_flags: ArrayX<Field, N,2> = BigNum::get_borrow_flags3(t0, t1, t2, t3, t4, fff, Params::modulus());

        // Compute the product t0 * t1 + t2 * t3 + t4 - Quotient * Modulus
        for i in 0..N {
            for j in 0..N {
                for k in 0..NUM_PRODUCTS {
                    if k == 0 {
                        let new_term = t0[k][i] * t1[k][j] - quotient.limbs[i] * Params::modulus().get(j);
                        std::as_witness(new_term); // width-4 optimization (n.b. might not be optimal if t2, t3 input arrays are nonzero)
                        product_limbs.set(i + j, product_limbs.get(i + j) + new_term);
                    } else {
                        product_limbs.set(i + j, product_limbs.get(i + j) + t0[k][i] * t1[k][j]);
                    }
                }
            }
            product_limbs.set(i, product_limbs.get(i) + t4[i]);
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
        borrow_flags.get(0).assert_max_bit_size(1);
        product_limbs.set(0, product_limbs.get(0) + borrow_flags.get(0) * borrow_shift);
        for i in 1..(N + N - 2) {
            borrow_flags.get(i).assert_max_bit_size(1);
            product_limbs.set(
                i,
                product_limbs.get(i)
                + (borrow_flags.get(i) * borrow_shift - borrow_flags.get(i - 1) * borrow_carry)
            );
        }
        product_limbs.set(
            N + N - 2,
            product_limbs.get(N + N - 2) - borrow_flags.get(N + N - 3) * borrow_carry
        );

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
        for i in 0..N + N - 2 {
            product_limbs.set(i, product_limbs.get(i) * hi_downshift);
            std::as_witness(product_limbs.get(i));
            product_limbs.get(i).assert_max_bit_size(126); // N.B. is this sufficient? going beyond 126 costs us 1 gate per limb
            product_limbs.set(i + 1, product_limbs.get(i + 1) + product_limbs.get(i));
        }
        // the most significant limb has no limb to "carry" values into - the entire limb must equal zero
        assert(product_limbs.get(N + N - 2) == 0);
    }
}
