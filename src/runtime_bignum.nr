use dep::std;
use crate::utils::u60_representation::U60Repr;
use crate::utils::arrayX::ArrayX;
use crate::utils::split_bits;
use crate::BigNum;

/**
 * @brief runtime_bignum::BigNumTrait defines methods available to BigNum *if* the modulus is not known at compile time.
 *        e.g. RSA where the modulus is a witness value as it changes for every RSA signature
 *        tee `lib.nr` for a trait definition where the modulus is known at compile time
 **/
trait BigNumTrait {
    fn new() -> Self;
    fn one() -> Self;
    fn from(limbs: [Field]) -> Self;
    fn from_byte_be<let NBytes: u64>(x: [u8; NBytes]) -> Self;
    fn to_le_bytes<let NBytes: u64>(val: Self) -> [u8; NBytes];
    fn get(self) -> [Field];
    fn get_limb(self, idx: u64) -> Field;
    fn set_limb(&mut self, idx: u64, value: Field);
    fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self;
    fn validate_in_range(self);
    fn validate_quotient_in_range(self);
    fn __is_zero(self) -> bool;
    fn __eq(self, rhs: Self) -> bool;
}

/**
 * @brief BigNumInstanceTrait defines methods available to a runtime BigNumInstance.
 *        BigNumInstance wraps the modulus parameter (as well as a Barret reduction parameter),
 *        which is required for the majority of BigNum operations
 **/
trait BigNumInstanceTrait<BN> where BN: BigNumTrait {
    fn modulus(self) -> BN;
    fn __derive_from_seed<let SeedBytes: u64>(self, seed: [u8; SeedBytes]) -> BN;
    fn eq(self, lhs: BN, rhs: BN) -> bool;
    fn __neg(self, val: BN) -> BN;
    fn __add(self, lhs: BN, rhs: BN) -> BN;
    fn __sub(self, lhs: BN, rhs: BN) -> BN;
    fn __mul(self, lhs: BN, rhs: BN) -> BN;
    fn __div(self, lhs: BN, rhs: BN) -> BN;
    fn __batch_invert<let M: u64>(self, x: [BN; M]) -> [BN; M];
    fn __batch_invert_slice(self, x: [BN]) -> [BN];
    fn __udiv_mod(self, numerator: BN, divisor: BN) -> (BN, BN);
    fn __invmod(self, val: BN) -> BN;
    fn __pow(self, val: BN, exponent: BN) -> BN;
    fn __compute_quadratic_expression<let LHS_N: u64, let RHS_N: u64, let NUM_PRODUCTS: u64, let ADD_N: u64>(
        self,
        lhs_terms: [[BN; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[BN; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [BN; ADD_N],
        linear_flags: [bool; ADD_N]
    ) -> (BN, BN);

    fn evaluate_quadratic_expression<let LHS_N: u64, let RHS_N: u64, let NUM_PRODUCTS: u64, let ADD_N: u64>(
        self,
        lhs_terms: [[BN; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[BN; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [BN; ADD_N],
        linear_flags: [bool; ADD_N]
    );

    fn validate_in_field(self, val: BN);
    fn validate_gt(self, lhs: BN, rhs: BN);
    fn assert_is_not_equal(self, lhs: BN, rhs: BN);
    fn neg(self, val: BN) -> BN;
    fn add(self, lhs: BN, rhs: BN) -> BN;
    fn sub(self, lhs: BN, rhs: BN) -> BN;
    fn mul(self, lhs: BN, rhs: BN) -> BN;
    fn div(self, lhs: BN, rhs: BN) -> BN;
    fn udiv_mod(self, numerator: BN, divisor: BN) -> (BN, BN);
    fn udiv(self, numerator: BN, divisor: BN) -> BN;
    fn umod(self, numerator: BN, divisor: BN) -> BN;

}

/**
 * @brief BigNumParamsTrait defines a "field" with which to parametrise BigNum.
 * @description The "field" does not need to be prime, any value *should* work (TODO: test!)
**/
trait BigNumParamsTrait<let N: u64> {
    /**
     * @brief modulus_bits = log2(modulus) rounded up
     **/
    fn modulus_bits() -> u64;

    fn has_multiplicative_inverse() -> bool { true }
}

struct BigNumInstance<let N: u64, Params> {
    
    /**
     * @brief modulus: all BigNum operations are evaluated modulo this value
     **/
    modulus: [Field; N],

    /**
     * @brief modulus but represented in a U60Repr form
     **/
    modulus_u60: U60Repr<N, 2>,
    modulus_u60_x4: U60Repr<N, 4>,

    // /**
    //  * @brief double_modulus: used when performing negations and subtractions
    //  **/
    double_modulus: [Field; N],
    // /**
    //  * @brief redc_param used for __barrett_reduction. See https://en.wikipedia.org/wiki/Barrett_reduction
    //  **/
    redc_param: [Field; N],
}

impl<let N: u64, Params> BigNum<N, Params> {
    // some strange circular dependency problem means we need to define `new` as a member of BigNumTrait as well as a definition outside of the trait
    // (delete this method to see. BigNumInstance methods that use BigNum::new() error out, and I can't find a way of declaring BigNum to satisfy BigNumTrait as part of the BigNumInstance definition because BigNumInstance has no contextual knowledge of the BigNum type...)
    fn new() -> Self {
        BigNum { limbs: [0; N] }
    }
    fn one() -> BigNum<N, Params> {
        let mut result: Self = BigNum { limbs: [0; N] };
        result.limbs[0] = 1;
        result
    }
}

impl<let N: u64, Params> BigNumTrait for BigNum<N, Params> where Params: BigNumParamsTrait<N> {

    fn new() -> Self {
        BigNum::new()
    }
    fn one() -> Self {
        BigNum::one()
    }

    fn from(limbs: [Field]) -> Self { BigNum{ limbs: limbs.as_array() }}

    /**
     * @brief construct a BigNum instance out of an array of bytes in BIG ENDIAN format
     * @description: each 120-bit limb represents 15 bytes, we require that the size of the byte array
     *               is precisely large enough to cover Params::modulus_bits()
     * @param x: input byte array
     **/
    fn from_byte_be<let NBytes: u64>(x: [u8; NBytes]) -> BigNum<N, Params> {
        let num_bits: u64 = NBytes * 8;
        let modulus_bits: u64 = Params::modulus_bits();
        assert(num_bits > modulus_bits);
        assert(num_bits - modulus_bits < 8);
        let mut result = BigNum::new();

        let excess_bytes = N * 15 - NBytes;
        let final_limb_bytes = 15 - excess_bytes;
        let mut limb: Field = 0;
        let mut k = 0;
        for _j in 0..final_limb_bytes {
            limb *= 256;
            limb += x[k] as Field;
            k += 1;
        }
        result.limbs[N - 1] = limb;

        for i in 1..N {
            let mut limb: Field = 0;
            for _j in 0..15 {
                limb *= 256;
                limb += x[k] as Field;
                k += 1;
            }
            result.limbs[N - i - 1] = limb;
        }

        // max_bits_in_most_significant_byte should be known at comptime. if not...messy!
        let mut max_bits_in_most_significant_byte = num_bits - modulus_bits;
        if num_bits == modulus_bits {
            max_bits_in_most_significant_byte = 8;
        }

        let most_significant_byte: Field = x[NBytes - 1] as Field;
        most_significant_byte.assert_max_bit_size(max_bits_in_most_significant_byte as u32);
        result
    }

    fn to_le_bytes<let NBytes: u64>(val: BigNum<N, Params>) -> [u8; NBytes] {
        let nbytes = (Params::modulus_bits() / 8) + (Params::modulus_bits() % 8 != 0) as u64;
        assert(nbytes <= NBytes);

        let mut result: [u8; NBytes] = [0; NBytes];
        for i in 0..N - 1 {
            let limb_bytes = val.limbs[i].to_le_bytes(15);
            for j in 0..15 {
                result[i * 15 + j] = limb_bytes[j];
            }
        }
        let last_limb_bytes = val.limbs[N - 1].to_le_bytes(15);
        let num_last_bytes = (NBytes - (N - 1) * 15);
        for i in 0..num_last_bytes {
            result[(N-1) * 15 + i] = last_limb_bytes[i];
        }
        result
    }

    fn get(self) -> [Field] {
        self.limbs
    }
    fn get_limb(self, idx: u64) -> Field {
        self.limbs[idx]
    }
    fn set_limb(&mut self, idx: u64, value: Field) {
        self.limbs[idx] = value;
    }

    /**
     * @brief conditional_select given the value of `predicate` return either `self` (if 0) or `other` (if 1)
     * @description should be cheaper than using an IF statement (TODO: check!)
     **/
    fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self {
        let mut result: Self = lhs;
        for i in 0..N {
            result.limbs[i] = (lhs.limbs[i] - rhs.limbs[i]) * predicate as Field + rhs.limbs[i];
        }
        result
    }

    /**
     * @brief Validate a BigNum instance is correctly range constrained to contain no more than Params::modulus_bits()
     **/
    fn validate_in_range(self) {
        for i in 0..(N - 1) {
            self.limbs[i].assert_max_bit_size(120);
        }
        let final_limb_bits = Params::modulus_bits() - ((N - 1) * 120);
        self.limbs[N - 1].assert_max_bit_size(final_limb_bits as u32);
    }

    /**
     * @brief validate quotient produced from `evaluate_quadratic_expression` is well-formed
     * @description because the inputs into evaluate_quadratic_expression may cause the quotient to extend beyond `Params::modulus_bits`.
     *              We allow the quotient to extend 6 bits beyond Params::modulus_bits()
     *              Why is this?
     *              several factors:    1. quotient * modulus , limbs cannot overflow field boundary (254 bits)
     *                                  2. in `evaluate_quadratic_expression`, we require that for `expression - quotient * modulus`,
     *                                     limbs cannot exceed 246 bits (246 magic number due to a higher number adding extra range check gates)
     *              because of factor 2 and the fact that modulus limbs are 120 bits, quotient limbs cannot be >126 bits
     *
     *              Note: doesn't this mean that final_limb_bits should be constrained to be 126 bits, not modulus_bits() - ((N - 1) * 120) + 6?
     *              TODO: think about this more! we want the range constraint we apply to be as small as allowable as this is more efficient
     **/
    fn validate_quotient_in_range(self) {
        for i in 0..(N) {
            self.limbs[i].assert_max_bit_size(120);
        }
        // Note: replace magic number 6 with definition
        let final_limb_bits = Params::modulus_bits() - ((N - 1) * 120) + 6;
        self.limbs[N - 1].assert_max_bit_size(final_limb_bits as u32);
    }

    fn __is_zero(self) -> bool {
        self.__is_zero_impl()
    }

    fn __eq(self, rhs: Self) -> bool {
        self.__eq_impl(rhs)
    }
}

impl<let N: u64, Params> BigNum<N, Params> where Params: BigNumParamsTrait<N> {

    fn from_array(limbs: [Field; N]) -> BigNum<N, Params> {
        BigNum { limbs }
    }

    unconstrained fn __is_zero_impl(self) -> bool {
        let mut result: bool = true;
        for i in 0..N {
            result = result & (self.limbs[i] == 0);
        }
        result
    }

    unconstrained fn __eq_impl(lhs: Self, rhs: Self) -> bool {
        lhs.limbs == rhs.limbs
    }
}

impl<let N: u64, Params,> BigNumInstanceTrait<BigNum<N, Params>> for BigNumInstance<N, Params> where Params: BigNumParamsTrait<N> {

    fn modulus(self) -> BigNum<N, Params> { BigNum{ limbs: self.modulus } }
    fn __derive_from_seed<let SeedBytes: u64>(self, seed: [u8; SeedBytes]) -> BigNum<N, Params> {
        self.__derive_from_seed_impl(seed)
    }
    // ####################################################################################################################
    // ####################################################################################################################
    // ### U N C O N S T R A I N E D    F U N C T I O N S
    // ### NOTE: these functions call unconstrained internal implementations because trait impl modifiers are not supported 
    // ####################################################################################################################
    // ####################################################################################################################

    fn __neg(self, val: BigNum<N, Params>) -> BigNum<N, Params> {
        self.__neg_impl(val)
    }

    fn __add(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) -> BigNum<N, Params> {
        self.__add_impl(lhs, rhs)
    }

    fn __sub(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) -> BigNum<N, Params> {
        self.__sub_impl(lhs, rhs)
    }

    fn __mul(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) -> BigNum<N, Params> {
        self.__mul_impl(lhs, rhs)
    }

    fn __div(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) -> BigNum<N, Params> {
        self.__div_impl(lhs, rhs)
    }

    fn __batch_invert<let M: u64>(self, x: [BigNum<N, Params>; M]) -> [BigNum<N, Params>; M] {
        self.batch_invert_impl(x)
    }

    // n.b. needs to be declared unconstrained because we return a slice from an unconstrained runtime
    unconstrained fn __batch_invert_slice(self, x: [BigNum<N, Params>]) -> [BigNum<N, Params>] {
        self.batch_invert_slice_impl(x)
    }

    fn __invmod(self, val: BigNum<N, Params>) -> BigNum<N, Params> {
        self.__invmod_impl(val)
    }

    fn __pow(self, val: BigNum<N, Params>, exponent: BigNum<N, Params>) -> BigNum<N, Params> {
        self.__pow_impl(val, exponent)
    }

    fn __compute_quadratic_expression<let LHS_N: u64, let RHS_N: u64, let NUM_PRODUCTS: u64, let ADD_N: u64>(
            self,
            lhs_terms: [[BigNum<N, Params>; LHS_N]; NUM_PRODUCTS],
            lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
            rhs_terms: [[BigNum<N, Params>; RHS_N]; NUM_PRODUCTS],
            rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
            linear_terms: [BigNum<N, Params>; ADD_N],
            linear_flags: [bool; ADD_N]
        ) -> (BigNum<N, Params>, BigNum<N, Params>) {
            self.__compute_quadratic_expression_impl(
                lhs_terms,
                lhs_flags,
                rhs_terms,
                rhs_flags,
                linear_terms,
                linear_flags
            )
    }


    // ####################################################################################################################
    // ####################################################################################################################
    // ### C O N S T R A I N E D    F U N C T I O N S
    // ####################################################################################################################
    // ####################################################################################################################


    /**
     * @brief Constrain a degree-2 BigNum expression to be equal to 0 modulo self.modulus
     * @description The expression is of the form (when evaluated as an integer relation):
     *
     * \sum_{i=0}^{NUM_PRODUCTS - 1} ((\sum_{j=0}^{LHS_N-1}lhs[i][j]) * (\sum_{j=0}^{RHS_N-1}rhs[i][j])) + \sum_{i=0}^{ADD_N - 1}linear_terms[i] - quotient * modulus = 0
     *
     * The intent is to capture an arbitrary degree-2 expression within the limitations of Noir (no efficient dynamically-sized vectors)
     *
     * Note: this method requires the remainder term of the expression to be ZERO
     * When performing BigNum arithmetic, we want to represent desired BigNum operations in a way that minimizes the number of modular reductions that are required.
     * This can be achieved by minimizing the number of degree-2 relations required.
     *
     * The expensive parts of this algorithm are the following:
     *      1. evaluating the limb products required to compute `lhs * rhs`
     *      2. applying range constraints to validate the result is 0
     *
     * Range constraints are needed for the following reason:
     * When evaluating the above expression over N-limb BigNum objects, the result will consist of 2N - 1 limbs.
     * Each limb will be in the range [0, ..., 2^{240 + twiddle_factor} - 1] (twiddle_factor needs to be less than 6).
     * Because of the subtractions, the limbs may underflow and represent NEGATIVE values.
     * To account for this, we allow the Prover to borrow values from more significant limbs and add them into less significant limbs
     * (explicitly, we can borrow 2^{126} from limb `i + 1` to add `2^{246}` into `i`).
     * To ensure this has been done correctly, we validate that the borrow-adjusted limbs are all-zero for the first 120 bits.
     * We do *this* by multiplying the borrow-adjusted limbs by 1 / 2^{120} modulo CircutModulus, and we validate the result is in the range [0, ..., 2^{126} - 1].
     * TODO: explain why this check works. It's statistically sound but not perfectly sound. Chance of the check failing is ~1 in 2^{120}
     * I believe this is the most efficient way of performing the zero-check for this relation as it only requires `2N - 2` 126-bit range checks.
     * TODO: explain why we apply a 126-bit range check, this feels like a magic number
     * (it is. we could go higher, up to the number of bits in the CircuitModulus - 121, but 126 *should be* sufficient and is much cheaper)
     * TODO: apply checks in this method to validate twiddle_factor does not exceed 6
     * 
     * @param lhs_terms a 2D array of BigNum
     * @param lhs_flags a 2D array of sign flags
     * @param rhs_terms a 2D array of BigNum
     * @param rhs_flags a 2D array of sign flags
     * @param linear_terms an array of BigNum
     * @param linear_flags an array of sign flags
     **/
    fn evaluate_quadratic_expression<let LHS_N: u64, let RHS_N: u64, let NUM_PRODUCTS: u64, let ADD_N: u64>(
        self,
        lhs_terms: [[BigNum<N, Params>; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[BigNum<N, Params>; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [BigNum<N, Params>; ADD_N],
        linear_flags: [bool; ADD_N]
    ) {
        // use an unconstrained function to compute the value of the quotient
        let (quotient, _, borrow_flags): (BigNum<N, Params>, BigNum<N, Params>, ArrayX<Field, N, 2>) = self.__compute_quadratic_expression_with_borrow_flags(
            lhs_terms,
            lhs_flags,
            rhs_terms,
            rhs_flags,
            linear_terms,
            linear_flags
        );
        // constrain the quotient to be in the range [0, ..., 2^{m} - 1], where `m` is log2(modulus) rounded up.
        // Additionally, validate quotient limbs are also in the range [0, ..., 2^{120} - 1]
        quotient.validate_quotient_in_range();
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        // (should be a compile-time check...unconstrained function?)

        // Compute the linear sums that represent lhs_1, rhs_1, lhs_2, rhs_2, add
        let mut t0: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
        let mut t1: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
        let mut t4: [Field; N] = [0; N];

        // TODO: this is super nasty as it requires a multiplication
        let double_modulus: [Field; N] = self.double_modulus;
        for k in 0..NUM_PRODUCTS {
            for i in 0..N {
                for j in 0..LHS_N {
                    // note: if is_negative is not known at comptime this is very expensive
                    if (lhs_flags[k][j]) {
                        t0[k][i] -= lhs_terms[k][j].limbs[i];
                        t0[k][i] += double_modulus[i];
                    } else {
                        t0[k][i] += lhs_terms[k][j].limbs[i];
                    }
                }
                for j in 0..RHS_N {
                    if (rhs_flags[k][j]) {
                        t1[k][i] -= rhs_terms[k][j].limbs[i];
                        t1[k][i] += double_modulus[i];
                    } else {
                        t1[k][i] += rhs_terms[k][j].limbs[i];
                    }
                }
            }
        }
        for i in 0..N {
            for j in 0..ADD_N {
                if (linear_flags[j]) {
                    t4[i] -= linear_terms[j].limbs[i];
                    t4[i] += double_modulus[i];
                } else {
                    t4[i] += linear_terms[j].limbs[i];
                }
            }
        }

        // We want to evaluate that t0 * t1 + t2 * t3 + t4 - Quotient * Modulus = 0, evaluated over the integers
        // For this we need to be able to borrow values from more-significant limbs into less-significant limbs,
        // so that we can ensure that no limbs will underflow for an honest Prover
        let mut product_limbs: ArrayX<Field, N,2> = ArrayX::new();
        //       let fff: [Field; N] = quotient.limbs;
        //      let mut borrow_flags: ArrayX<Field, N,2> = BigNum::get_borrow_flags3(t0, t1, t2, t3, t4, fff, self.modulus);

        // Compute the product t0 * t1 + t2 * t3 + t4 - Quotient * Modulus
        // TODO: this is super nasty as it requires a multiplication
        for i in 0..N {
            for j in 0..N {
                for k in 0..NUM_PRODUCTS {
                    if k == 0 {
                        let new_term = t0[k][i] * t1[k][j] - quotient.limbs[i] * self.modulus[j];
                        std::as_witness(new_term); // width-4 optimization (n.b. might not be optimal if t2, t3 input arrays are nonzero)
                        product_limbs.add_assign(i + j, new_term);
                    } else {
                        product_limbs.add_assign(i + j, t0[k][i] * t1[k][j]);
                    }
                }
                if (NUM_PRODUCTS == 0) {
                    product_limbs.sub_assign(i + j, quotient.limbs[i] * self.modulus[j]);
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

    fn validate_in_field(self, val: BigNum<N, Params>) {
        // N.B. need to combine with validate_in_range if `self` limbs have not been range constrained
        let mut p_minus_self: [Field; N] = [0; N];
        let modulus: [Field; N] = self.modulus;
        for i in 0..N {
            p_minus_self[i] = modulus[i] - val.limbs[i];
        }
        let borrow_flags = self.__validate_in_field_compute_borrow_flags(val);
        let two_pow_120: Field = 0x1000000000000000000000000000000;
        p_minus_self[0] += borrow_flags[0] as Field * two_pow_120;
        for i in 1..N - 1 {
            p_minus_self[i] += (borrow_flags[i] as Field * two_pow_120 - borrow_flags[i-1] as Field);
        }
        p_minus_self[N - 1] -= borrow_flags[N - 2] as Field;
        let mut compare = val;
        compare.limbs = p_minus_self;
        compare.validate_in_range();
    }

    /**
     * @brief Validate self != other
     * @details If A == B, then A == B mod N.
     *          We can efficiently evaluate A == B mod N where N = circuit modulus
     *          This method is *sound*, but not *complete* (i.e. A != B but A == B mod N)
     *          However the probability of an honest Prover being unable to satisfy this check is tiny!
     *          (todo: compute how tiny)
     **/
    fn assert_is_not_equal(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) {
        let mut l: Field = 0;
        let mut r: Field = 0;
        let mut modulus_mod_n: Field = 0;
        let mut two_pow_120: Field = 0x1000000000000000000000000000000;
        let modulus = self.modulus;
        for i in 0..N {
            l *= two_pow_120;
            r *= two_pow_120;
            modulus_mod_n *= two_pow_120;
            l += lhs.limbs[N - i - 1];
            r += rhs.limbs[N - i - 1] ;
            modulus_mod_n += modulus[N - i - 1];
        }

        // lhs can be either X mod N or P + X mod N
        // rhs can be either Y mod N or P + Y mod N
        // If lhs - rhs = 0 mod P then lhs - rhs = 0, P or -P mod N
        let mut diff = l - r;
        let mut target = diff * (diff + modulus_mod_n) * (diff - modulus_mod_n);
        assert(target != 0, "asssert_is_not_equal fail");
    }

    fn eq(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) -> bool {
        let diff = self.sub(lhs, rhs);
        // if self == other, possible values of `diff` will be `p` or `0`
        // (the subtract operator constrains diff to be < ceil(log(p)))
        // TODO: can do this more efficiently via witngen in unconstrained functions?
        let mut is_equal_modulus: bool = true;
        let mut is_equal_zero: bool = true;
        for i in 0..N {
            is_equal_modulus = is_equal_modulus & (diff.limbs[i] == self.modulus[i]);
            is_equal_zero = is_equal_zero & (diff.limbs[i] == 0);
        }
        is_equal_modulus | is_equal_zero
    }

    fn neg(self, val: BigNum<N, Params>) -> BigNum<N, Params> {
        // so we do... p - x - r = 0 and there might be borrow flags
        let (result, borrow_flags) = self.__neg_with_flags(val);
        result.validate_in_range();
        let modulus = self.modulus;
        let borrow_shift = 0x1000000000000000000000000000000;
        let result_limb = modulus[0] - val.limbs[0] - result.limbs[0] + (borrow_flags[0] as Field * borrow_shift);
        assert(result_limb == 0);
        for i in 1..N - 1 {
            let result_limb = modulus[i] - val.limbs[i] - result.limbs[i] - borrow_flags[i - 1] as Field
                + (borrow_flags[i] as Field * borrow_shift);
            assert(result_limb == 0);
        }
        let result_limb = modulus[N - 1] - val.limbs[N - 1] - result.limbs[N - 1] - borrow_flags[N - 2] as Field;
        assert(result_limb == 0);
        result
    }

    fn add(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) -> BigNum<N, Params> {
        // so we do... p - x - r = 0 and there might be borrow flags
        let (result, carry_flags, borrow_flags, overflow_modulus) = self.__add_with_flags(lhs, rhs);
        result.validate_in_range();
        let modulus = self.modulus;
        let borrow_shift = 0x1000000000000000000000000000000;
        let carry_shift = 0x1000000000000000000000000000000;

        let mut subtrahend: [Field; N] = [0; N];
        if (overflow_modulus) {
            subtrahend = modulus;
        }
        let result_limb = lhs.limbs[0] + rhs.limbs[0] - subtrahend[0] - result.limbs[0]
            + (borrow_flags[0] as Field * borrow_shift)
            - (carry_flags[0] as Field * carry_shift);
        assert(result_limb == 0);
        for i in 1..N - 1 {
            let result_limb = lhs.limbs[i] + rhs.limbs[i]
                - subtrahend[i]
                - result.limbs[i]
                - borrow_flags[i - 1] as Field
                + carry_flags[i - 1] as Field
                + ((borrow_flags[i] as Field - carry_flags[i] as Field) * borrow_shift);
            assert(result_limb == 0);
        }
        let result_limb = lhs.limbs[N - 1] + rhs.limbs[N - 1]
            - subtrahend[N - 1]
            - result.limbs[N - 1]
            - borrow_flags[N - 2] as Field
            + carry_flags[N - 2] as Field;
        assert(result_limb == 0);
        result
    }

    // validate that lhs - rhs does not underflow i.e. lhs > rhs
    fn validate_gt(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) {
        // so we do... p - x - r = 0 and there might be borrow flags

        // a - b = r
        // p + a - b - r = 0
        let (result, carry_flags, borrow_flags) = self.__validate_gt_remainder(lhs, rhs);

        result.validate_in_range();

        let borrow_shift = 0x1000000000000000000000000000000;
        let carry_shift = 0x1000000000000000000000000000000;

        let mut addend: [Field; N] = [0; N];
        let result_limb = lhs.limbs[0] - rhs.limbs[0] + addend[0] - result.limbs[0] - 1
            + (borrow_flags[0] as Field * borrow_shift)
            - (carry_flags[0] as Field * carry_shift);
        assert(result_limb == 0);
        for i in 1..N - 1 {
            let result_limb = lhs.limbs[i] - rhs.limbs[i] + addend[i] - result.limbs[i] - borrow_flags[i - 1] as Field
                + carry_flags[i - 1] as Field
                + ((borrow_flags[i] as Field - carry_flags[i] as Field) * borrow_shift);
            assert(result_limb == 0);
        }
        let result_limb = lhs.limbs[N - 1] - rhs.limbs[N - 1] + addend[N - 1]
            - result.limbs[N - 1]
            - borrow_flags[N - 2] as Field
            + carry_flags[N - 2] as Field;
        assert(result_limb == 0);
    }

    fn sub(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) -> BigNum<N, Params> {
        // so we do... p - x - r = 0 and there might be borrow flags

        // a - b = r
        // p + a - b - r = 0
        let (result, carry_flags, borrow_flags, underflow) = self.__sub_with_flags(lhs, rhs);
        result.validate_in_range();
        let modulus = self.modulus;
        let borrow_shift = 0x1000000000000000000000000000000;
        let carry_shift = 0x1000000000000000000000000000000;

        let mut addend: [Field; N] = [0; N];
        if (underflow) {
            addend = modulus;
        }
        let result_limb = lhs.limbs[0] - rhs.limbs[0] + addend[0] - result.limbs[0]
            + (borrow_flags[0] as Field * borrow_shift)
            - (carry_flags[0] as Field * carry_shift);
        assert(result_limb == 0);
        for i in 1..N - 1 {
            let result_limb = lhs.limbs[i] - rhs.limbs[i] + addend[i] - result.limbs[i] - borrow_flags[i - 1] as Field
                + carry_flags[i - 1] as Field
                + ((borrow_flags[i] as Field - carry_flags[i] as Field) * borrow_shift);
            assert(result_limb == 0);
        }
        let result_limb = lhs.limbs[N - 1] - rhs.limbs[N - 1] + addend[N - 1]
            - result.limbs[N - 1]
            - borrow_flags[N - 2] as Field
            + carry_flags[N - 2] as Field;
        assert(result_limb == 0);
        result
    }
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    // e.g. performing a sum of multiple multiplications and additions via `evaluate_quadratic_expression`
    //      will create much fewer constraints than calling `mul` and `add` directly
    fn mul(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) -> BigNum<N, Params> {
        let result = self.__mul(lhs, rhs);
        self.evaluate_quadratic_expression([[lhs]], [[false]], [[rhs]], [[false]], [result], [true]);
        result
    }
    // Note: this method is expensive! Witness computation is extremely expensive as it requires modular exponentiation
    fn div(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) -> BigNum<N, Params> {
        assert(Params::has_multiplicative_inverse(), "BigNum has no multiplicative inverse. Use udiv for unsigned integer division");
        let result = self.__div(lhs, rhs);
        self.evaluate_quadratic_expression([[result]], [[false]], [[rhs]], [[false]], [lhs], [true]);
        result
    }

    /**
     * @brief __udiv_mod performs *unconstrained* integer division between numerator, divisor 
     *
     * i.e. 1. floor(numerator / divisor) = quotient
     *      2. numerator % divisor = remainder
     *      3. divisor * quotient + remainder = numerator
     **/
    fn __udiv_mod(self, numerator: BigNum<N, Params>, divisor: BigNum<N, Params>) -> (BigNum<N, Params>, BigNum<N, Params>) {
        self.__udiv_mod_impl(numerator, divisor)
    }
    /**
     * @brief udiv_mod performs integer division between numerator, divisor 
     *
     * i.e. 1. floor(numerator / divisor) = quotient
     *      2. numerator % divisor = remainder
     *      3. divisor * quotient + remainder = numerator
     **/
    fn udiv_mod(self, numerator: BigNum<N, Params>, divisor: BigNum<N, Params>) -> (BigNum<N, Params>, BigNum<N, Params>) {
        let (quotient, remainder) = BigNumInstance::__udiv_mod_impl(self, numerator, divisor);

        // self / divisor = quotient rounded
        // quotient * divisor + remainder - self = 0
        self.evaluate_quadratic_expression(
            [[quotient]],
            [[false]],
            [[divisor]],
            [[false]],
            [numerator, remainder],
            [true, false]
        );
        // we need (remainder < divisor)
        // implies (divisor - remainder > 0)
        self.validate_gt(divisor, remainder);
        (quotient, remainder)
    }

    /**
     * @brief udiv_mod performs integer division between numerator, divisor 
     *
     * i.e. return param is floor(numerator / divisor)
     **/
    fn udiv(self, numerator: BigNum<N, Params>, divisor: BigNum<N, Params>) -> BigNum<N, Params> {
        self.udiv_mod(numerator, divisor).0
    }

    /**
     * @brief udiv_mod performs integer modular reduction
     *
     * i.e. 1. numerator % divisor = return value
     **/
    fn umod(self, numerator: BigNum<N, Params>, divisor: BigNum<N, Params>) -> BigNum<N, Params> {
        self.udiv_mod(numerator, divisor).1
    }

}

impl<let N: u64, Params> BigNumInstance<N, Params> where Params: BigNumParamsTrait<N> {

    // ####################################################################################################################
    // ####################################################################################################################
    // ### C  O  N  S  T  R  U  C  T  O  R  S
    // ####################################################################################################################
    // ####################################################################################################################

    fn new(modulus: [Field; N], redc_param: [Field; N]) -> Self {
        Self {
            redc_param,
            modulus,
            modulus_u60: U60Repr::from(modulus),
            modulus_u60_x4: U60Repr::from(modulus),
            double_modulus: get_double_modulus(modulus)
        }
    }

    unconstrained fn __derive_from_seed_impl<let SeedBytes: u64>(self, seed: [u8; SeedBytes]) -> BigNum<N, Params> {
        let mut rolling_seed = seed;

        let mut to_reduce: ArrayX<Field, N, 2> = ArrayX { segments: [[0; N], [0; N]] };

        let mut double_modulus_bits = Params::modulus_bits() * 2;
        let mut double_modulus_bytes = (double_modulus_bits) / 8 + (double_modulus_bits % 8 != 0) as u64;

        let mut last_limb_bytes = double_modulus_bytes % 15;
        if (last_limb_bytes == 0) {
            last_limb_bytes = 15;
        }
        let mut last_limb_bits = double_modulus_bits % 8;
        if (last_limb_bits == 0) {
            last_limb_bits = 8;
        }

        for i in 0..(N - 1) {
            let hash: [u8; 32] = std::hash::sha256(rolling_seed);
            let mut lo: Field = 0;
            let mut hi: Field = 0;
            for j in 0..15 {
                hi *= 256;
                lo *= 256;

                if (i < 2 * N - 2) {
                    lo += hash[j + 15] as Field;
                    hi += hash[j] as Field;
                }
            }
            to_reduce.set(2 * i, lo);
            to_reduce.set(2 * i + 1, hi);
            rolling_seed[0] += 1;
        }

        {
            let hash: [u8; 32] = std::hash::sha256(rolling_seed);
            let mut hi: Field = 0;
            for j in 0..(last_limb_bytes - 1) {
                hi *= 256;
                hi += hash[j] as Field;
            }
            hi *= 256;
            let last_byte = hash[last_limb_bytes - 1];
            let mask = (1 as u64 << (last_limb_bits) as u8) - 1;
            let last_bits = last_byte as u64 & mask;
            hi += last_bits as Field;
            to_reduce.set(2 * N - 2, hi);
        }

        let (_, remainder) = __barrett_reduction(
            to_reduce,
            self.redc_param,
            Params::modulus_bits(),
            self.modulus,
            self.modulus_u60_x4
        );
        let mut result = BigNum::new();
        result.limbs = remainder;
        result
    }

    // ####################################################################################################################
    // ####################################################################################################################
    // ### U N C O N S T R A I N E D    F U N C T I O N S
    // ####################################################################################################################
    // ####################################################################################################################

    unconstrained fn __validate_in_field_compute_borrow_flags(self: Self, val: BigNum<N, Params>) -> [bool; N] {
        let mut flags: [bool; N] = [false; N];
        let modulus: [Field; N] = self.modulus;
        flags[0] = modulus[0].lt(val.limbs[0]);
        for i in 1..N - 1 {
            flags[i] = modulus[i].lt(val.limbs[i] + flags[i - 1] as Field);
        }
        flags
    }

    unconstrained fn __pow_impl(self, val: BigNum<N, Params>, exponent: BigNum<N, Params>) -> BigNum<N, Params> {
        let x: U60Repr<N, 2> = U60Repr::from(exponent.limbs);

        let num_bits = Params::modulus_bits() + 1;

        let mut accumulator: BigNum<N, Params> = BigNum::one();

        for i in 0..num_bits {
            accumulator = self.__mul(accumulator, accumulator);
            if x.get_bit(num_bits - i - 1) {
                accumulator = self.__mul(accumulator, val);
            }
        }
        accumulator
    }

    unconstrained fn __mul_with_quotient(
        self,
        lhs: BigNum<N, Params>,
        rhs: BigNum<N, Params>
    ) -> (BigNum<N, Params>, BigNum<N, Params>) {
        let mut mul: ArrayX<Field, N, 2> = ArrayX::new();
        for i in 0..N {
            for j in 0..N {
                mul.add_assign(i + j, lhs.limbs[i] * rhs.limbs[j]);
            }
        }
        let (q, r) = __barrett_reduction(
            mul.__normalize_limbs(N + N),
            self.redc_param,
            Params::modulus_bits(),
            self.modulus,
            self.modulus_u60_x4
        );

        let mut quotient = BigNum::from_array(q);
        let mut remainder = BigNum::from_array(r);
        (quotient, remainder)
    }

    unconstrained fn __mul_impl(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) -> BigNum<N, Params> {
        let (_, b) = self.__mul_with_quotient(lhs, rhs);
        b
    }

    unconstrained fn __add_impl(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) -> BigNum<N, Params> {
        let x_u60 : U60Repr<N, 2> = U60Repr::from(lhs.limbs);
        let y_u60 : U60Repr<N, 2> = U60Repr::from(rhs.limbs);

        let mut z_u60 = x_u60 + y_u60;

        if z_u60.gte(self.modulus_u60) {
            z_u60 = z_u60 - self.modulus_u60;
        }
        let mut result = BigNum::from_array(U60Repr::into(z_u60));
        result
    }

    /**
     * @brief given an input `x`, compute `2p - x` (unconstrained)
     *
     * @description we subtract the input from double the modulus, because all constrained BigNum operations
     *              only guarantee that the output is in the range [0, ceil(log2(p))].
     *              I.E. the input may be larger than the modulus `p`.
     *              In order to ensure this operation does not underflow, we compute `2p - x` instead of `p - x`.
     *              N.B. constrained BigNum operations do not fully constrain outputs to be in the range [0, p-1]
     *              because such a check is expensive and usually unneccesary.
     */
    unconstrained fn __neg_impl(self, val: BigNum<N, Params>) -> BigNum<N, Params> {
        let f: [Field; N] = val.limbs;
        let x_u60 : U60Repr<N, 2> = U60Repr::from(f);
        let mut result = BigNum::from_array(U60Repr::into(self.modulus_u60 - x_u60));
        result
    }

    unconstrained fn __add_with_flags(
        self,
        lhs: BigNum<N, Params>,
        rhs: BigNum<N, Params>
    ) -> (BigNum<N, Params>, [bool; N], [bool; N], bool) {
        let a_u60 : U60Repr<N, 2> = U60Repr::from(lhs.limbs);
        let b_u60 : U60Repr<N, 2> = U60Repr::from(rhs.limbs);
        let add_u60 = a_u60 + b_u60;

        let overflow = add_u60.gte(self.modulus_u60);

        let mut subtrahend_u60 : U60Repr<N, 2> = U60Repr { limbs: ArrayX::new() };
        let mut result_u60 : U60Repr<N, 2> = U60Repr { limbs: ArrayX::new() };

        if overflow {
            subtrahend_u60 = self.modulus_u60;
        }

        let mut carry: u64 = 0;
        let mut carry_in: u64 = 0;
        let mut borrow: u64 = 0;
        let mut borrow_in: u64 = 0;
        let mut borrow_flags: [bool; N] = [false; N];
        let mut carry_flags: [bool; N] = [false; N];
        for j in 0..2 {
            for i in 0..N {
                let mut add_term: u64 = a_u60.limbs.segments[j][i] + b_u60.limbs.segments[j][i] + carry_in;
                carry = (add_term >= 0x1000000000000000) as u64;
                add_term -= (carry as u64 * 0x1000000000000000);
                result_u60.limbs.segments[j][i] = add_term;
                carry_in = carry as u64;
                borrow = ((subtrahend_u60.limbs.segments[j][i] + borrow_in) > result_u60.limbs.segments[j][i]) as u64;
                let sub = (borrow << 60) + result_u60.limbs.segments[j][i]
                    - subtrahend_u60.limbs.segments[j][i]
                    - borrow_in;
                result_u60.limbs.segments[j][i] = sub;
                borrow_in = borrow;

                if ((j * N + i) & 1 == 1) {
                    let idx = (j * N + i - 1) / 2;
                    if (carry & borrow == 1) {
                        carry = 0;
                        borrow = 0;
                    }
                    carry_flags[idx] = carry as bool;
                    borrow_flags[idx] = borrow as bool;
                }
            }
        }
        let mut result = BigNum::from_array(U60Repr::into(result_u60));

        (result, carry_flags, borrow_flags, overflow)
    }

    unconstrained fn __validate_gt_remainder(
        _: Self,
        lhs: BigNum<N, Params>,
        rhs: BigNum<N, Params>
    ) -> (BigNum<N, Params>, [bool; N], [bool; N]) {
        let a_u60 : U60Repr<N, 2> = U60Repr::from(lhs.limbs);
        let mut b_u60 : U60Repr<N, 2> = U60Repr::from(rhs.limbs);

        let underflow = b_u60.gte(a_u60);
        b_u60 += U60Repr::one();
        assert(underflow == false, "BigNum::validate_gt check fails");
        let mut addend_u60 : U60Repr<N, 2> = U60Repr { limbs: ArrayX::new() };
        let mut result_u60 : U60Repr<N, 2> = U60Repr { limbs: ArrayX::new() };

        let mut carry: u64 = 0;
        let mut carry_in: u64 = 0;
        let mut borrow: u64 = 0;
        let mut borrow_in: u64 = 0;
        let mut borrow_flags: [bool; N] = [false; N];
        let mut carry_flags: [bool; N] = [false; N];
        for j in 0..2 {
            for i in 0..N {
                let mut add_term: u64 = a_u60.limbs.segments[j][i] + addend_u60.limbs.segments[j][i] + carry_in;
                carry = (add_term >= 0x1000000000000000) as u64;
                add_term -= (carry as u64 * 0x1000000000000000);
                result_u60.limbs.segments[j][i] = add_term;
                carry_in = carry as u64;
                borrow = ((b_u60.limbs.segments[j][i] + borrow_in) > result_u60.limbs.segments[j][i]) as u64;
                let sub = (borrow << 60) + result_u60.limbs.segments[j][i]
                    - b_u60.limbs.segments[j][i]
                    - borrow_in;
                result_u60.limbs.segments[j][i] = sub;
                borrow_in = borrow;

                if ((j * N + i) & 1 == 1) {
                    let idx = (j * N + i - 1) / 2;
                    if (carry & borrow == 1) {
                        carry = 0;
                        borrow = 0;
                    }
                    carry_flags[idx] = carry as bool;
                    borrow_flags[idx] = borrow as bool;
                }
            }
        }
        let mut result = BigNum::from_array(U60Repr::into(result_u60));
        (result, carry_flags, borrow_flags)
    }


    unconstrained fn __sub_with_flags(
        self,
        lhs: BigNum<N, Params>,
        rhs: BigNum<N, Params>
    ) -> (BigNum<N, Params>, [bool; N], [bool; N], bool) {
        let a_u60 : U60Repr<N, 2> = U60Repr::from(lhs.limbs);
        let b_u60 : U60Repr<N, 2> = U60Repr::from(rhs.limbs);

        let underflow = b_u60.gte(a_u60 + U60Repr::one());

        let mut addend_u60 : U60Repr<N, 2> = U60Repr { limbs: ArrayX::new() };
        let mut result_u60 : U60Repr<N, 2> = U60Repr { limbs: ArrayX::new() };

        if underflow {
            addend_u60 = self.modulus_u60;
        }

        let mut carry: u64 = 0;
        let mut carry_in: u64 = 0;
        let mut borrow: u64 = 0;
        let mut borrow_in: u64 = 0;
        let mut borrow_flags: [bool; N] = [false; N];
        let mut carry_flags: [bool; N] = [false; N];
        for j in 0..2 {
            for i in 0..N {
                let mut add_term: u64 = a_u60.limbs.segments[j][i] + addend_u60.limbs.segments[j][i] + carry_in;
                carry = (add_term >= 0x1000000000000000) as u64;
                add_term -= (carry as u64 * 0x1000000000000000);
                result_u60.limbs.segments[j][i] = add_term;
                carry_in = carry as u64;
                borrow = ((b_u60.limbs.segments[j][i] + borrow_in) > result_u60.limbs.segments[j][i]) as u64;
                let sub = (borrow << 60) + result_u60.limbs.segments[j][i]
                    - b_u60.limbs.segments[j][i]
                    - borrow_in;
                result_u60.limbs.segments[j][i] = sub;
                borrow_in = borrow;

                if ((j * N + i) & 1 == 1) {
                    let idx = (j * N + i - 1) / 2;
                    if (carry & borrow == 1) {
                        carry = 0;
                        borrow = 0;
                    }
                    carry_flags[idx] = carry as bool;
                    borrow_flags[idx] = borrow as bool;
                }
            }
        }
        let mut result = BigNum::from_array(U60Repr::into(result_u60));
        (result, carry_flags, borrow_flags, underflow)
    }

    unconstrained fn __neg_with_flags(self, val: BigNum<N, Params>) -> (BigNum<N, Params>, [bool; N]) {
        let f: [Field; N] = val.limbs;
        let x_u60 : U60Repr<N, 2> = U60Repr::from(f);
        let mut result_u60 : U60Repr<N, 2> = U60Repr { limbs: ArrayX::new() };

        let mut borrow: u64 = 0;
        let mut borrow_in: u64 = 0;

        let mut borrow_flags: [bool; N] = [false; N];
        for j in 0..2 {
            for i in 0..N {
                borrow = ((x_u60.limbs.segments[j][i] + borrow_in) > self.modulus_u60.limbs.segments[j][i]) as u64;
                let sub = (borrow << 60) + self.modulus_u60.limbs.segments[j][i]
                    - x_u60.limbs.segments[j][i]
                    - borrow_in;
                result_u60.limbs.segments[j][i] = sub;
                borrow_in = borrow;
                if ((j * N + i) & 1 == 1) {
                    let idx = (j * N + i - 1) / 2;
                    borrow_flags[idx] = borrow as bool;
                }
            }
        }
        let mut result = BigNum::from_array(U60Repr::into(result_u60));
        (result, borrow_flags)
    }

    /**
     * @brief given inputs `x, y` compute 2p + x - y (unconstrained)
     * @description see `__neg` for why we use 2p instead of p
     **/
    unconstrained fn __sub_impl(self, lhs: BigNum<N, Params>, rhs: BigNum<N, Params>) -> BigNum<N, Params> {
        self.__add(lhs, self.__neg(rhs))
    }

    unconstrained fn __invmod_impl(self, val: BigNum<N, Params>) -> BigNum<N, Params> {
        let one: BigNum<N, Params> = BigNum::one();
        let one_u60: U60Repr<N, 2> = U60Repr::from(one.limbs);
        let exponent = self.modulus_u60.sub(one_u60.add(one_u60));
        let mut result = BigNum::from_array(U60Repr::into(exponent));
        self.__pow(val, result)
    }

    unconstrained fn batch_invert_impl<let M: u64>(self, x: [BigNum<N, Params>; M]) -> [BigNum<N, Params>; M] {
        // TODO: ugly! Will fail if input slice is empty
        let mut accumulator: BigNum<N, Params> = BigNum::one();
        let mut result: [BigNum<N, Params>; M] = [BigNum::new(); M];
        let mut temporaries: [BigNum<N, Params>] = &[];
        for i in 0..x.len() {
            temporaries = temporaries.push_back(accumulator);
            if (x[i].__is_zero() == false) {
                accumulator = self.__mul(accumulator, x[i]);
            }
        }

        accumulator = self.__invmod(accumulator);
        let mut T0: BigNum<N, Params> = BigNum::new();
        T0.limbs = [0; N];
        for i in 0..x.len() {
            let idx = x.len() - 1 - i;
            if (x[idx].__is_zero() == false) {
                T0 = self.__mul(accumulator, temporaries[idx]);
                accumulator = self.__mul(accumulator, x[idx]);
                result[idx] = T0;
            }
        }
        result
    }

    unconstrained fn batch_invert_slice_impl(self, x: [BigNum<N, Params>]) -> [BigNum<N, Params>] {
        // TODO: ugly! Will fail if input slice is empty
        let mut accumulator: BigNum<N, Params> = BigNum::one();
        let mut result: [BigNum<N, Params>] = [BigNum::new()];
        let mut temporaries: [BigNum<N, Params>] = &[];
        for i in 0..x.len() {
            temporaries = temporaries.push_back(accumulator);
            if (x[i].__is_zero() == false) {
                accumulator = self.__mul(accumulator, x[i]);
            }
            result = result.push_back(BigNum::new());
        }

        accumulator = self.__invmod(accumulator);
        let mut T0: BigNum<N, Params> = BigNum::new();
        T0.limbs = [0; N];
        for i in 0..x.len() {
            let idx = x.len() - 1 - i;
            if (x[idx].__is_zero() == false) {
                T0 = self.__mul(accumulator, temporaries[idx]);
                accumulator = self.__mul(accumulator, x[idx]);
                result[idx] = T0;
            }
        }
        result
    }

    unconstrained fn __div_impl(self, numerator: BigNum<N, Params>, divisor: BigNum<N, Params>) -> BigNum<N, Params> {
        let t0 = self.__invmod(divisor);
        self.__mul(numerator, t0)
    }

    /**
     * @brief Computes the result of a linear combination of (possibly negative) BigNum values (unconstrained)
     **/
    // NOTE: modulus2 is structured such that all limbs will be greater than 0, even when subtracting.
    // To do this, when computing `p - x`, we ensure that each limb in `p` is greater than each limb in `x`.
    // We know that, for a valid bignum element, the limbs in `x` will be <2^{120}
    // Therefore each of the limbs in `p` (except the most significant) will borrow 2^{120} from the more significant limb.
    // Finally, to ensure we do not underflow in the most significant limb, we use `2p` instead of `p`
    unconstrained fn __add_linear_expression<let M: u64>(
        self,
        x: [BigNum<N, Params>; M],
        flags: [bool; M]
    ) -> ([Field; N]) {
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        let mut sum: [Field; N] = [0; N];
        // TODO: ugly! Will fail if input array is empty
        let modulus2: [Field;N] = self.double_modulus;
        for i in 0..M {
            if (flags[i]) {
                for j in 0..N {
                    sum[j] = sum[j] + modulus2[j] - x[i].limbs[j];
                    assert(x[i].limbs[j].lt(modulus2[j]));
                }
            } else {
                for j in 0..N {
                    sum[j] = sum[j] + x[i].limbs[j];
                }
            }
        }
        // problem if we normalize when used in computing quotient
        sum
        //   let result_p: ArrayX<Field, N, 1> = BigNum::__normalize_limbs(ArrayX::from_array(lhs_sum_p), N);
        //  let result_n: ArrayX<Field, N, 1> = BigNum::__normalize_limbs(ArrayX::from_array(lhs_sum_n), N);
        //  (result_p.segments[0], result_n.segments[0])
    }

    /**
     * @brief computes the limb products of a quadratic expression
     * @details see __compute_quadratic_expression_with_borrow_flags for full description
     **/
    unconstrained fn __compute_quadratic_expression_product<let LHS_N: u64, let RHS_N: u64, let NUM_PRODUCTS: u64, let ADD_N: u64>(
        self,
        lhs_terms: [[BigNum<N, Params>; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[BigNum<N, Params>; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [BigNum<N, Params>; ADD_N],
        linear_flags: [bool; ADD_N]
    ) -> ArrayX<Field, N, 2> {
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        let mut lhs: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
        let mut rhs: [[Field; N]; NUM_PRODUCTS] = [[0; N]; NUM_PRODUCTS];
        let mut add: [Field; N] = [0; N];

        for i in 0..NUM_PRODUCTS {
            lhs[i] = self.__add_linear_expression(lhs_terms[i], lhs_flags[i]);
            rhs[i]= self.__add_linear_expression(rhs_terms[i], rhs_flags[i]);
        }

        let add: [Field; N] = self.__add_linear_expression(linear_terms, linear_flags);

        let mut mulout: ArrayX<Field, N,2> = ArrayX::new();

        for i in 0..N {
            for j in 0..N {
                for k in 0..NUM_PRODUCTS {
                    mulout.add_assign(i + j, (lhs[k][i] * rhs[k][j]));
                }
            }
            mulout.add_assign(i, add[i]);
        }
        mulout
    }

    /**
     * @brief computes the quotient/remainder of a quadratic expression
     * @details see __compute_quadratic_expression_with_borrow_flags for full description
     **/
    unconstrained fn __compute_quadratic_expression_impl<let LHS_N: u64, let RHS_N: u64, let NUM_PRODUCTS: u64, let ADD_N: u64>(
        self,
        lhs_terms: [[BigNum<N, Params>; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[BigNum<N, Params>; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [BigNum<N, Params>; ADD_N],
        linear_flags: [bool; ADD_N]
    ) -> (BigNum<N, Params>, BigNum<N, Params>) {
        // TODO, validate we do not overflow N2 when multiplying and N when adding
        let mulout = self.__compute_quadratic_expression_product(
            lhs_terms,
            lhs_flags,
            rhs_terms,
            rhs_flags,
            linear_terms,
            linear_flags
        );
        let relation_result: ArrayX<Field, N, 2> = mulout.__normalize_limbs(N + N);

        // TODO: ugly! Will fail if input slice is empty
        let k  = Params::modulus_bits();

        let (quotient, remainder) = __barrett_reduction(
            relation_result,
            self.redc_param,
            k,
            self.modulus,
            self.modulus_u60_x4
        );

        let mut q = BigNum::from_array(quotient);
        let mut r = BigNum::from_array(remainder);
        (q, r)
    }

    /**
     * @brief Given a degree-2 BigNum expression that is equal to 0 mod p, compute the quotient and borrow flags 
     * @description The expression is of the form:
     *
     * \sum_{i=0}^{NUM_PRODUCTS - 1} ((\sum_{j=0}^{LHS_N-1}lhs[i][j]) * (\sum_{j=0}^{RHS_N-1}rhs[i][j])) + \sum_{i=0}^{ADD_N - 1}linear_terms[i] = quotient * modulus
     *
     * The intent is to capture an arbitrary degree-2 expression within the limitations of Noir (no efficient dynamically-sized vectors)
     *
     * When performing BigNum arithmetic, we want to represent desired BigNum operations in a way that minimizes the number of modular reductions that are required.
     * This can be achieved by minimizing the number of degree-2 relations required.
     *
     * The borrow flags describe whether individual Field limbs will underflow when evaluating the above relation.
     * For example, when computing the product a * b - q * p = 0, it is possible that:
     *      1. a[0]*b[0] - p[0]*q[0] = -2^{120}
     *      2. a[0]*b[1] + a[1]*b[0] - p[0]*q[1] - p[1]*q[0] = 1
     * In the above example, the value represented by these two limbs is zero despite each limb being nonzero.
     * In this case, to correctly constrain the result, we must add (at least) 2^{120} from the first limb and subtract 1 from the second.
     *
     * @param lhs_terms a 2D array of BigNum
     * @param lhs_flags a 2D array of sign flags
     * @param rhs_terms a 2D array of BigNum
     * @param rhs_flags a 2D array of sign flags
     * @param linear_terms an array of BigNum
     * @param linear_flags an array of sign flags
     **/
    unconstrained fn __compute_quadratic_expression_with_borrow_flags<let LHS_N: u64, let RHS_N: u64, let NUM_PRODUCTS: u64, let ADD_N: u64>(
        self,
        lhs_terms: [[BigNum<N, Params>; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[BigNum<N, Params>; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [BigNum<N, Params>; ADD_N],
        linear_flags: [bool; ADD_N]
    ) -> (BigNum<N, Params>, BigNum<N, Params>, ArrayX<Field, N, 2>) {
        // TODO, validate we do not overflow N2 when multiplying and N when adding

        let mut mulout_p = self.__compute_quadratic_expression_product(
            lhs_terms,
            lhs_flags,
            rhs_terms,
            rhs_flags,
            linear_terms,
            linear_flags
        );
        let mut mulout_n: ArrayX<Field, N,2> = ArrayX::new();

        let relation_result: ArrayX<Field, N, 2> = mulout_p.__normalize_limbs(N + N);
        let modulus: [Field; N] = self.modulus;
        let (quotient, remainder) = __barrett_reduction(
            relation_result,
            self.redc_param,
            Params::modulus_bits(),
            modulus,
            self.modulus_u60_x4
        );
        assert(remainder == [0; N]);

        for i in 0..N {
            for j in 0..N {
                mulout_n.add_assign(i + j, quotient[i] * modulus[j]);
            }
        }

        // compute borrow flags from mulout_p and mulout_n
        let mut borrow_flags: ArrayX<Field, N, 2> = ArrayX::new();
        let borrow_shift: Field = 0x40000000000000000000000000000000000000000000000000000000000000; // 2^{246}
        let borrow_carry: Field = 0x40000000000000000000000000000000; // 2^{246 - 120} = 2^{126}
        let two_pow_120: Field = 0x1000000000000000000000000000000;
        let downshift: Field = 1 / two_pow_120;

        // determine whether we need to borrow from more significant limbs.
        // initial limb is "simple" comparison operation
        // TODO: check how expensive `lt` operator is w.r.t. witness generation
        borrow_flags.set(0, mulout_p.get(0).lt(mulout_n.get(0)) as Field);
        // we have 2N - 2 borrow flags. The number of limbs from our product computation is 2N - 1
        // and there is nothing to borrow against for the final limb.
        let mut hi_bits = (mulout_p.get(0) - mulout_n.get(0) + (borrow_flags.get(0) * borrow_shift)) * downshift;
        for i in 1..(N + N - 2) {
            // compute the contribution from limb `i-1` that gets added into limb `i`, and add into limb `i`
            // let hi_bits = (mulout_p.get(i - 1) - mulout_n.get(i - 1) + (borrow_flags.get(i - 1) * borrow_shift))
            //     * downshift;
            mulout_p.add_assign(i, hi_bits);

            // determine whether negative limb values are greater than positive limb values
            let underflow: Field = mulout_p.get(i).lt(mulout_n.get(i) + (borrow_flags.get(i - 1) * borrow_carry)) as Field;
            borrow_flags.set(i, underflow);

            hi_bits = (mulout_p.get(i) - mulout_n.get(i) + (borrow_flags.get(i) * borrow_shift)
                - (borrow_flags.get(i - 1) * borrow_carry)) * downshift;
        }

        let mut q = BigNum::from_array(quotient);
        let mut r = BigNum::from_array(remainder);
        (q, r, borrow_flags)
    }

    unconstrained fn __udiv_mod_impl(_: Self, numerator: BigNum<N, Params>, divisor: BigNum<N, Params>) -> (BigNum<N, Params>, BigNum<N, Params>) {


        let mut quotient_u60: U60Repr<N, 2> = U60Repr::from([0; N]);
        let mut remainder_u60: U60Repr<N, 2> = U60Repr::from(numerator.limbs);
       
        let mut divisor_u60: U60Repr<N, 2> = U60Repr::from(divisor.limbs);
        let b = divisor_u60;

        let mut bit_difference = remainder_u60.get_msb() - divisor_u60.get_msb();

        let mut accumulator_u60: U60Repr<N, 2> = U60Repr::one();
        divisor_u60 = divisor_u60.shl(bit_difference);
        accumulator_u60 = accumulator_u60.shl(bit_difference);

        if (divisor_u60.gte(remainder_u60 + U60Repr::one()))
        {
            divisor_u60 .shr1();
            accumulator_u60.shr1();
        }
        for _ in 0..(N * 120) {
            if (remainder_u60.gte(b) == false)
            {
                break;
            }

            // we've shunted 'divisor' up to have the same bit length as our remainder.
            // If remainder >= divisor, then a is at least '1 << bit_difference' multiples of b
            if (remainder_u60.gte(divisor_u60)) {
                remainder_u60 -= divisor_u60;
                // we can use OR here instead of +, as
                // accumulator is always a nice power of two
                quotient_u60 = quotient_u60 + accumulator_u60;
            }
            divisor_u60.shr1();// >>= 1;
            accumulator_u60.shr1();//  >>= 1;
        }

        (BigNum::from_array(U60Repr::into(quotient_u60)), BigNum::from_array(U60Repr::into(remainder_u60)))
    }
}

fn get_double_modulus<let N: u64>(modulus: [Field; N]) -> [Field; N] {
    let TWO_POW_120: Field = 0x1000000000000000000000000000000;
    let m: U60Repr<N, 2> = U60Repr::from(modulus);
    let mut result: [Field; N] = U60Repr::into(m + m);

    result[0] += TWO_POW_120;
    for i in 1..N - 1 {
        result[i] += (TWO_POW_120 - 1);
    }
    result[N - 1] -= 1;
    result
}

unconstrained fn __barrett_reduction<let N: u64>(
    x: ArrayX<Field, N, 2>,
    redc_param: [Field; N],
    k: u64,
    modulus: [Field; N],
    modulus_u60: U60Repr<N, 4>
) -> ([Field; N], [Field; N]) {
    let mut mulout: ArrayX<Field, N, 3>  = ArrayX { segments: [[0; N]; 3] };
    for i in 0..(N + N) {
        for j in 0..N {
            mulout.add_assign(i + j, x.get(i) * redc_param[j]);
        }
    }
    mulout = mulout.__normalize_limbs(3 * N - 1);
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

    for i in 0..(N + N) {
        let (lo, hi) = split_bits::split_120_bits(quotient_mul_modulus.get(i));
        quotient_mul_modulus_normalized.set(i, lo);
        // TODO: what is faster, leaving this if statement in or out?
        // (array is size-1 too large so we can tolerate adding 0 into max element)
        if (i + 1 < N + N) {
            quotient_mul_modulus.add_assign(i + 1, hi);
        }
    }
    let quotient_mul_modulus_u60: U60Repr<N, 4> = U60Repr::new(quotient_mul_modulus_normalized);

    let x_u60 : U60Repr<N, 4> = U60Repr::new(x);
    let mut remainder_u60 = x_u60 - quotient_mul_modulus_u60;

    if (remainder_u60.gte(modulus_u60)) {
        remainder_u60 = remainder_u60 - modulus_u60;
        quotient_u60.increment();
    } else {}

    let q: [Field; N] = U60Repr::into(quotient_u60);
    let r: [Field; N] = U60Repr::into(remainder_u60);

    (q, r)
}
