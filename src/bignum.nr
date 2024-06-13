use dep::std;
use crate::split_bits;
use crate::u60_representation::U60Repr;
use crate::arrayX::ArrayX;

/**
 * @brief ParameterTrait defines a field with which to parametrise BigNum 
**/
trait ParameterTrait<N> {
    fn redc_param() -> [Field; N];
    fn modulus() -> [Field; N];
    fn double_modulus() -> [Field; N];
    fn k() -> u64; // used for Barrett Reduction. Should be at least modulus_bits() + 1
    fn modulus_bits() -> u64;
    fn one3u() -> U60Repr<N, 6>; // used for Barrett Reduction
}

/**
 * @brief BNExpressionInput used to define inputs into `BigNum::evaluate_quadratic_expression`
 *        (this method is the basic building block for efficiently evaluating BigNum algebra)
**/
struct BNExpressionInput<N, Params> {
    value: BigNum<N, Params>,
    is_negative: bool,
 }

impl<N, Params> BNExpressionInput<N, Params> {

    fn new(input: BigNum<N, Params>, _is_negative: bool) -> Self {
        BNExpressionInput { value: input, is_negative: _is_negative }
    }
}

struct BigNum<N,Params> {
    limbs: [Field; N],
}

impl<N, Params> BigNum<N, Params> {

    fn new() -> Self {
        BigNum { limbs: [0; N] }
    }

    fn one() -> Self {
        let mut result = BigNum::new();
        result.limbs[0] = 1;
        result
    }

    fn validate_in_range(self) where Params: ParameterTrait<N> {
        for i in 0..(N - 1) {
            self.limbs[i].assert_max_bit_size(120);
        }
        let final_limb_bits = Params::modulus_bits() - ((N - 1) * 120);
        self.limbs[N - 1].assert_max_bit_size(final_limb_bits as u32);
    }

    unconstrained fn __normalize_limbs<NumSegments>(x: ArrayX<Field, N, NumSegments>, range: u64) -> ArrayX<Field, N, NumSegments> {
        let mut normalized: ArrayX<Field, N, NumSegments> = ArrayX::new();
        let mut inp = x;
        for i in 0..(range - 1) {
            let (lo, hi) = split_bits::split_120_bits(inp.get(i));

            normalized.set(i, lo);
            inp.set(i + 1, inp.get(i + 1) + hi);
        }
        {
            let (lo, hi) = split_bits::split_120_bits(inp.get(range - 1));
            normalized.set(range - 1, lo);
            assert(hi == 0);
        }
        normalized
    }

    unconstrained fn __powmod(self: Self, exponent: Self) -> Self where Params: ParameterTrait<N> {
        let x: U60Repr<N, 2> = U60Repr::from_array(exponent.limbs);

        let num_bits = Params::modulus_bits() + 1;

        let mut accumulator: Self = BigNum::one();

        for i in 0..num_bits {
            accumulator = accumulator.__mulmod(accumulator);
            if x.get_bit(num_bits - i - 1) {
                accumulator = accumulator.__mulmod(self);
            }
        }
        accumulator
    }

    unconstrained fn __invmod(self: Self) -> Self where Params: ParameterTrait<N> {
        let modulus_u60: U60Repr<N, 2> = U60Repr::from_array(Params::modulus());
        let one_u60: U60Repr<N, 2> = U60Repr::from_array(BigNum::one().limbs);
        let exponent = modulus_u60.sub(one_u60.add(one_u60));
        self.__powmod(BigNum { limbs: exponent.into_array() })
    }

    unconstrained fn __divmod(self: Self, divisor: Self) -> Self where Params: ParameterTrait<N> {
        let t0 = divisor.__invmod();
        self.__mulmod(t0)
    }

    unconstrained fn __barrett_reduction(
        x: ArrayX<Field, N, 2>,
        redc_param: [Field; N],
        k: u64,
        modulus: [Field; N],
        one3u: U60Repr<N, 6>
    ) -> ([Field; N], [Field; N]) {
        let mut mulout: ArrayX<Field, N, 3>  = ArrayX { segments: [[0; N]; 3] };
        for i in 0..(N + N) {
            for j in 0..N {
                mulout.add_assign(i + j, x.get(i) * redc_param[j]);
            }
        }
        mulout = BigNum::__normalize_limbs(mulout, 3 * N - 2);
        let mulout_u60: U60Repr<N, 6> = U60Repr::new(mulout);
        let mut quotient_u60 = mulout_u60.shr((k + k));

        // N.B. we assume that the shifted quotient cannot exceed 2 times original bit size.
        //      (partial_quotient should be just slightly larger than the modulus, we could probably represent with a size N+1 array)
        let partial_quotient: ArrayX<Field, N, 2> = quotient_u60.into_arrayX();

        // quotient_mul_modulus can never exceed input value `x` so can fit into size-2 array
        let mut quotient_mul_modulus: ArrayX<Field, N, 2>  = ArrayX { segments: [[0; N]; 2] };
        let mut quotient_mul_modulus_normalized: ArrayX<Field, N, 2>  = ArrayX { segments: [[0; N]; 2] };
        for j in 0..N {
            for i in 0..(N + N - j) {
                quotient_mul_modulus.add_assign(i + j, partial_quotient.get(i) * modulus[j]);
            }
        }

        for i in 0..(N + N - 1) {
            let (lo, hi) = split_bits::split_120_bits(quotient_mul_modulus.get(i));
            quotient_mul_modulus_normalized.set(i, lo);
            // TODO: what is faster, leaving this if statement in or out?
            // (array is size-1 too large so we can tolerate adding 0 into max element)
            //if (i + 1 < N + N - 1) {
            quotient_mul_modulus.add_assign(i + 1, hi);
            //}
        }

        let quotient_mul_modulus_u60: U60Repr<N, 4> = U60Repr::new(quotient_mul_modulus_normalized);

        let x_u60 : U60Repr<N, 4> = U60Repr::new(x);

        let mut remainder_u60 = x_u60 - quotient_mul_modulus_u60;

        let modulus_u60: U60Repr<N, 4> = U60Repr::from_array(modulus); // TODO make double modulus
        if (remainder_u60.gte(modulus_u60)) {
            remainder_u60 = remainder_u60 - modulus_u60;
            quotient_u60 = quotient_u60 + one3u;
        }

        let t1: ArrayX<Field, N, 2> = quotient_u60.into_arrayX();
        let t2: ArrayX<Field, N, 2> = remainder_u60.into_arrayX();
        let mut quotient_fields: [Field; N] = [0; N];
        let mut remainder_fields: [Field; N] = [0; N];
        for i in 0..N {
            quotient_fields[i] = t1.get(i);
            remainder_fields[i] = t2.get(i);
        }

        (quotient_fields, remainder_fields)
    }

    unconstrained fn __mulmod_with_quotient(self, rhs: Self) -> (Self, Self) where Params: ParameterTrait<N> {
        let mut mul: ArrayX<Field, N, 2> = ArrayX::new();
        for i in 0..N {
            for j in 0..N {
                mul.add_assign(i + j, self.limbs[i] * rhs.limbs[j]);
            }
        }
        let (q, r) = BigNum::__barrett_reduction(
            BigNum::__normalize_limbs(mul, N + N - 1),
            Params::redc_param(),
            Params::k(),
            Params::modulus(),
            Params::one3u()
        );

        (Self { limbs: q }, Self { limbs: r })
    }

    unconstrained fn __mulmod(self, rhs: Self) -> Self where Params: ParameterTrait<N> {
        let (_, b) = self.__mulmod_with_quotient(rhs);
        b
    }

    unconstrained fn __addmod(self, rhs: Self) -> Self where Params: ParameterTrait<N> {
        let x_u60 : U60Repr<N, 2> = U60Repr::from_array(self.limbs);
        let y_u60 : U60Repr<N, 2> = U60Repr::from_array(rhs.limbs);

        let mut z_u60 = x_u60 + y_u60;

        let modulus_u60 : U60Repr<N,2> = U60Repr::from_array(Params::modulus());
        if z_u60.gte(modulus_u60) {
            z_u60 = z_u60 - modulus_u60;
        }
        Self { limbs: z_u60.into_array() }
    }

    // // TODO subtract 2x modulus
    unconstrained fn __negate(self) -> Self where Params: ParameterTrait<N> {
        let x_u60 : U60Repr<N, 2> = U60Repr::from_array(self.limbs);
        let modulus_u60 : U60Repr<N, 2> = U60Repr::from_array(Params::modulus());
        Self { limbs: (modulus_u60 - x_u60).into_array() }
    }

    // // TODO subtract 2x modulus
    unconstrained fn __submod(self, rhs: Self) -> Self where Params: ParameterTrait<N> {
        self.__addmod(rhs.__negate())
    }

    unconstrained fn __add_linear_expression<M>(x: [BNExpressionInput<N, Params>; M]) -> ([Field; N], [Field; N]) where Params: ParameterTrait<N> {
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        let mut lhs_sum_p: [Field; N] = [0; N];
        let mut lhs_sum_n: [Field; N] = [0; N];
        let modulus2: [Field;N] = Params::double_modulus();
        for i in 0..M {
            if (x[i].is_negative) {
                for j in 0..N {
                    lhs_sum_p[j] = lhs_sum_p[j] + modulus2[j];
                    lhs_sum_n[j] = lhs_sum_n[j] + x[i].value.limbs[j];
                }
            } else {
                for j in 0..N {
                    lhs_sum_p[j] = lhs_sum_p[j] + x[i].value.limbs[j];
                }
            }
        }
        let result_p: ArrayX<Field, N, 1> = BigNum::__normalize_limbs(ArrayX::from_array(lhs_sum_p), N);
        let result_n: ArrayX<Field, N, 1> = BigNum::__normalize_limbs(ArrayX::from_array(lhs_sum_n), N);

        (result_p.segments[0], result_n.segments[0])
    }

    unconstrained fn __compute_mul_quotient(lhs: Self, rhs: Self) -> (Self, Self, ArrayX<Field, N, 2>) where Params: ParameterTrait<N> {
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        let mut mulout: ArrayX<Field, N,2> = ArrayX::new();

        for i in 0..N {
            for j in 0..N {
                mulout.add_assign(i + j, lhs.limbs[i] * rhs.limbs[j]);
            }
        }

        let relation_result: ArrayX<Field, N, 2> = BigNum::__normalize_limbs(mulout, N + N - 1);
        let modulus: [Field; N] = Params::modulus();
        let (quotient, remainder) = BigNum::__barrett_reduction(
            relation_result,
            Params::redc_param(),
            Params::k(),
            modulus,
            Params::one3u()
        );
        let mut mulout_n: ArrayX<Field, N,2> = ArrayX::new();
        for i in 0..N {
            for j in 0..N {
                mulout_n.add_assign(i + j, quotient[i] * modulus[j]);
            }
            mulout_n.add_assign(i, remainder[i]);
        }
        // compute borrow flags from mulout_p and mulout_n
        let mut borrow_flags: ArrayX<Field, N, 2> = ArrayX::new();
        let borrow_shift: Field = 0x4000000000000000000000000000000;
        borrow_flags.set(0, mulout.get(0).lt(mulout_n.get(0)) as Field);
        for i in 1..(N + N - 2) {
            let res: Field = mulout.get(i).lt(mulout_n.get(i) + (borrow_flags.get(i - 1) * borrow_shift)) as Field;
            borrow_flags.set(i, res);
        }

        (Self { limbs: quotient }, Self { limbs: remainder }, borrow_flags)
    }

    unconstrained fn __compute_quadratic_expression_quotient<LHS_N, RHS_N, NUM_PRODUCTS, ADD_N>(
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
            let (l_p, l_n): ([Field; N], [Field; N]) = BigNum::__add_linear_expression(lhs_terms[i]);
            let (r_p, r_n): ([Field; N], [Field; N]) = BigNum::__add_linear_expression(rhs_terms[i]);
            lhs_p[i] = l_p;
            lhs_n[i] = l_n;
            rhs_p[i] = r_p;
            rhs_n[i] = r_n;
        }
        let (add_p, add_n): ([Field; N], [Field; N]) = BigNum::__add_linear_expression(linear_terms);

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

        let T0: ArrayX<Field, N, 2> = BigNum::__normalize_limbs(mulout_p, N + N - 1);
        let T1: ArrayX<Field, N, 2> = BigNum::__normalize_limbs(mulout_n, N + N - 1);

        let mulout_pu60: U60Repr<N, 4> = U60Repr::new(T0);
        let mulout_nu60: U60Repr<N, 4> = U60Repr::new(T1);
        let relation_result: ArrayX<Field, N, 2> = BigNum::__normalize_limbs((mulout_pu60 - mulout_nu60).into_arrayX(), N + N - 1);

        let modulus: [Field; N] = Params::modulus();
        let (quotient, remainder) = BigNum::__barrett_reduction(
            relation_result,
            Params::redc_param(),
            Params::k(),
            modulus,
            Params::one3u()
        );
        assert(remainder == [0; N]);

        for i in 0..N {
            for j in 0..N {
                mulout_n.add_assign(i + j, quotient[i] * modulus[j]);
            }
        }

        // compute borrow flags from mulout_p and mulout_n
        let mut borrow_flags: ArrayX<Field, N, 2> = ArrayX::new();
        let borrow_shift: Field = 0x4000000000000000000000000000000;
        borrow_flags.set(0, mulout_p.get(0).lt(mulout_n.get(0)) as Field);
        for i in 1..(N + N - 2) {
            let res: Field = mulout_p.get(i).lt(mulout_n.get(i) + (borrow_flags.get(i - 1) * borrow_shift)) as Field;
            borrow_flags.set(i, res);
        }

        (Self { limbs: quotient }, borrow_flags)
    }

    /**
     * @brief
    =**/
    fn evaluate_mul(lhs: Self, rhs: Self) -> Self where Params: ParameterTrait<N> {
        // use an unconstrained function to compute the value of the quotient
        let (quotient, remainder, borrow_flags): (Self, Self, ArrayX<Field, N, 2>) = BigNum::__compute_mul_quotient(lhs, rhs);
        // constrain the quotient to be in the range [0, ..., 2^{m} - 1], where `m` is log2(modulus) rounded up.
        // Additionally, validate quotient limbs are also in the range [0, ..., 2^{120} - 1]
        // TODO: validate_in_range should be more flexible for quotient
        quotient.validate_in_range();
        remainder.validate_in_range();
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        // (should be a compile-time check...unconstrained function?)

        // Compute the linear sums that represent lhs_1, rhs_1, lhs_2, rhs_2, add

        // We want to evaluate that t0 * t1 + t2 * t3 + t4 - Quotient * Modulus = 0, evaluated over the integers
        // For this we need to be able to borrow values from more-significant limbs into less-significant limbs,
        // so that we can ensure that no limbs will underflow for an honest Prover
        let mut product_limbs: ArrayX<Field,N,2> = ArrayX::new();
        //       let fff: [Field; N] = quotient.limbs;
        //      let mut borrow_flags: ArrayX<Field, N,2> = BigNum::get_borrow_flags3(t0, t1, t2, t3, t4, fff, Params::modulus());

        // Compute the product t0 * t1 + t2 * t3 + t4 - Quotient * Modulus
        let modulus: [Field; N] = Params::modulus();
        for i in 0..N {
            for j in 0..N {
                let new_term = lhs.limbs[i] * rhs.limbs[j] - quotient.limbs[i] * modulus[j];
                std::as_witness(new_term); // width-4 optimization (n.b. might not be optimal if t2, t3 input arrays are nonzero)
                product_limbs.add_assign(i + j, new_term);
            }
            product_limbs.sub_assign(i, remainder.limbs[i]);
        }

        // a < b

        // 1. decompose a/b into 128-bit slices a0, a1, b0, b1
        // 2. validate a0 + 2^{128}a1 < field modulus (over the integers)
        // 3. validate a0 + 2^{128}a1 < field modulus (over the integers)
        // 4. use range checks to determine whether r0 = a0 > b0, r1 = a1 > b1
        // 5. compute < result from r0, r1
    
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
        product_limbs.add_assign(0, borrow_flags.get(0) * borrow_shift);
        for i in 1..(N + N - 2) {
            borrow_flags.get(i).assert_max_bit_size(1);
            product_limbs.add_assign(
                i,
                (borrow_flags.get(i) * borrow_shift - borrow_flags.get(i - 1) * borrow_carry)
            );
        }
        product_limbs.sub_assign(N + N - 2, borrow_flags.get(N + N - 3) * borrow_carry);

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
        let hi_shift: Field = 0x1000000000000000000000000000000; // 2^{120}
        let hi_downshift: Field = 1 / hi_shift;
        for i in 0..N + N - 2 {
            product_limbs.mul_assign(i, hi_downshift);
            std::as_witness(product_limbs.get(i));
            product_limbs.get(i).assert_max_bit_size(126); // N.B. is this sufficient? going beyond 126 costs us 1 gate per limb
            product_limbs.add_assign(i + 1, product_limbs.get(i));
        }
        // the most significant limb has no limb to "carry" values into - the entire limb must equal zero
        assert(product_limbs.get(N + N - 2) == 0);
        remainder
    }

    /**
     * @brief
    =**/
    fn evaluate_quadratic_expression<LHS_N, RHS_N, NUM_PRODUCTS, ADD_N>(
        lhs_products: [[BNExpressionInput<N, Params>; LHS_N]; NUM_PRODUCTS],
        rhs_products: [[BNExpressionInput<N, Params>; RHS_N]; NUM_PRODUCTS],
        linear_terms: [BNExpressionInput<N, Params>; ADD_N]
    ) where Params: ParameterTrait<N> {
        // use an unconstrained function to compute the value of the quotient
        let (quotient, borrow_flags): (Self, ArrayX<Field, N, 2>) = BigNum::__compute_quadratic_expression_quotient(lhs_products, rhs_products, linear_terms);
        // constrain the quotient to be in the range [0, ..., 2^{m} - 1], where `m` is log2(modulus) rounded up.
        // Additionally, validate quotient limbs are also in the range [0, ..., 2^{120} - 1]
        quotient.validate_in_range();
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        // (should be a compile-time check...unconstrained function?)

        // Compute the linear sums that represent lhs_1, rhs_1, lhs_2, rhs_2, add
        let mut t0: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
        let mut t1: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
        let mut t4: [Field; N] = [0; N];
        let modulus: [Field; N] = Params::double_modulus();
        for k in 0..NUM_PRODUCTS {
            for i in 0..N {
                for j in 0..LHS_N {
                    // note: if is_negative is not known at comptime this is vvvvvery expensive
                    let is_negative: bool = lhs_products[k][j].is_negative;
                    if (is_negative) {
                        t0[k][i] -= lhs_products[k][j].value.limbs[i];
                        t0[k][i] += modulus[i]; // TODO twice mox
                    } else {
                        t0[k][i] += lhs_products[k][j].value.limbs[i];
                    }
                }
                for j in 0..RHS_N {
                    let is_negative: bool = rhs_products[k][j].is_negative;
                    if (is_negative) {
                        t1[k][i] -= rhs_products[k][j].value.limbs[i];
                        t1[k][i] += modulus[i]; // TODO twice mox
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
                    t4[i] += modulus[i]; // TODO twice mox
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
        let modulus: [Field; N] = Params::modulus();
        for i in 0..N {
            for j in 0..N {
                for k in 0..NUM_PRODUCTS {
                    if k == 0 {
                        let new_term = t0[k][i] * t1[k][j] - quotient.limbs[i] * modulus[j];
                        std::as_witness(new_term); // width-4 optimization (n.b. might not be optimal if t2, t3 input arrays are nonzero)
                        product_limbs.add_assign(i + j, new_term);
                    } else {
                        product_limbs.add_assign(i + j, t0[k][i] * t1[k][j]);
                    }
                }
            }
            product_limbs.add_assign(i, t4[i]);
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
        product_limbs.add_assign(0, borrow_flags.get(0) * borrow_shift);
        for i in 1..(N + N - 2) {
            borrow_flags.get(i).assert_max_bit_size(1);
            product_limbs.add_assign(
                i,
                (borrow_flags.get(i) * borrow_shift - borrow_flags.get(i - 1) * borrow_carry)
            );
        }
        product_limbs.sub_assign(N + N - 2, borrow_flags.get(N + N - 3) * borrow_carry);

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
            product_limbs.mul_assign(i, hi_downshift);
            std::as_witness(product_limbs.get(i));
            product_limbs.get(i).assert_max_bit_size(126); // N.B. is this sufficient? going beyond 126 costs us 1 gate per limb
            product_limbs.add_assign(i + 1, product_limbs.get(i));
        }
        // the most significant limb has no limb to "carry" values into - the entire limb must equal zero
        assert(product_limbs.get(N + N - 2) == 0);
    }
}

impl<N, Params> std::ops::Add for BigNum<N, Params> where Params: ParameterTrait<N> {
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    fn add(self, other: Self) -> Self {
        let result = self.__addmod(other);
        BigNum::evaluate_quadratic_expression(
            [[]],
            [[]],
            [BNExpressionInput::new(self, false), BNExpressionInput::new(other, false), BNExpressionInput::new(result, true)]
        );
        result
    }
}

impl<N, Params> std::ops::Sub for BigNum<N, Params> where Params: ParameterTrait<N> {
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    fn sub(self, other: Self) -> Self {
        let result = self.__submod(other);
        BigNum::evaluate_quadratic_expression(
            [[]],
            [[]],
            [BNExpressionInput::new(self, true), BNExpressionInput::new(other, false), BNExpressionInput::new(result, false)]
        );
        result
    }
}

impl<N, Params> std::ops::Mul for BigNum<N, Params> where Params: ParameterTrait<N> {
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    // e.g. performing a sum of multiple multiplications and additions via `evaluate_quadratic_expression`
    //      will create much fewer constraints than calling `mul` and `add` directly
    // N.B. evaluate_mul is used because witness generation is probably faster - not sure increased code complexity is worth
    fn mul(self, other: Self) -> Self {
        let result = BigNum::evaluate_mul(
            self,
            other
        );
        result
    }
}

impl<N, Params> std::ops::Div for BigNum<N, Params> where Params: ParameterTrait<N> {
    // Note: this method is expensive! Witness computation is extremely expensive
    fn div(self, other: Self) -> Self {
        let result = self.__divmod(other);
        BigNum::evaluate_quadratic_expression(
            [[BNExpressionInput::new(result, false)]],
            [[BNExpressionInput::new(other, false)]],
            [BNExpressionInput::new(self, true)]
        );
        result
    }
}
