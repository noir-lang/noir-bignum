mod utils;
mod bignum_test;
mod fields;
mod runtime_bignum;
mod runtime_bignum_test;

use dep::std;
use crate::utils::u60_representation::U60Repr;
use crate::utils::arrayX::ArrayX;
use crate::utils::split_bits;
use crate::runtime_bignum::BigNumInstance as RuntimeBigNumInstance;
use crate::runtime_bignum::BigNumInstanceTrait as RuntimeBigNumInstanceTrait;
use crate::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use crate::runtime_bignum::BigNumTrait as RuntimeBigNumTrait;

struct BigNum<let N: u64, Params> {
    limbs: [Field; N]
}

/**
 * @brief BigNumParamsTrait defines a "field" with which to parametrise BigNum.
 * @description The "field" does not need to be prime, any value *should* work (TODO: test!)
**/
// 
// trait BigNumParamsTrait<let N: u64, Params> where Params: RuntimeBigNumParamsTrait<N>, RuntimeBigNumInstance<N, Params>: RuntimeBigNumInstanceTrait<BigNum<N, Params>> {
trait BigNumParamsTrait<let N: u64> where Self: RuntimeBigNumParamsTrait<N> {

    fn get_instance() -> RuntimeBigNumInstance<N, Self> where Self: RuntimeBigNumParamsTrait<N>;// <N, Params>;

    /**
     * @brief k used for __barrett_reduction. Should be at least modulus_bits() + 1
     **/
    fn k() -> u64;
    /**
     * @brief modulus_bits = log2(modulus) rounded up
     **/
    fn modulus_bits() -> u64;
}

trait BigNumTrait where BigNumTrait: std::ops::Add + std::ops::Sub + std::ops::Mul + std::ops::Div + std::ops::Eq + RuntimeBigNumTrait {
    // TODO: this crashes the compiler? v0.32
    // fn default() -> Self { std::default::Default::default  () }
    fn from(limbs: [Field]) -> Self { RuntimeBigNumTrait::from(limbs) }
    fn new() -> Self { RuntimeBigNumTrait::new() }
    fn one() -> Self { RuntimeBigNumTrait::one() }
    fn modulus() -> Self;
    fn modulus_bits(self) -> u64;
    fn num_limbs(self) -> u64;
    fn __derive_from_seed<let SeedBytes: u64>(seed: [u8; SeedBytes]) -> Self;
    fn __powmod(self, exponent: Self) -> Self;
    fn __negate(self) -> Self;
    fn __addmod(self, other: Self) -> Self;
    fn __submod(self, other: Self) -> Self;
    fn __mulmod(self, other: Self) -> Self;
    fn __divmod(self, other: Self) -> Self;
    fn __invmod(self) -> Self;
    fn __batch_invert<let M: u64>(to_invert: [Self; M]) -> [Self; M];
    fn __batch_invert_slice(x: [Self]) -> [Self];
    fn __is_zero(self) -> bool { RuntimeBigNumTrait::__is_zero(self) }
    fn __eq(self, other: Self) -> bool { RuntimeBigNumTrait::__eq(self, other) }
    fn __compute_quadratic_expression<let LHS_N: u64, let RHS_N: u64, let NUM_PRODUCTS: u64, let ADD_N: u64>(lhs: [[Self; LHS_N]; NUM_PRODUCTS], lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS], rhs: [[Self; RHS_N]; NUM_PRODUCTS], rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS], add: [Self; ADD_N], add_flags: [bool; ADD_N]) -> (Self, Self);
    fn evaluate_quadratic_expression<let LHS_N: u64, let RHS_N: u64, let NUM_PRODUCTS: u64, let ADD_N: u64>(lhs: [[Self; LHS_N]; NUM_PRODUCTS], lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS], rhs: [[Self; RHS_N]; NUM_PRODUCTS], rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS], add: [Self; ADD_N], add_flags: [bool; ADD_N]);
    fn validate_in_range(self){ RuntimeBigNumTrait::validate_in_range(self) }
    fn validate_in_field(self);
    fn assert_is_not_equal(self, other: Self);
    fn neg(self) -> Self;
    fn add(self, other: Self) -> Self { self + other }
    fn sub(self, other: Self) -> Self { self - other }
    fn mul(self, other: Self) -> Self { self * other }
    fn div(self, other: Self) -> Self { self / other }
    fn eq(self, other: Self) -> bool { self == other }
    fn get(self) -> [Field] { RuntimeBigNumTrait::get(self) }
    fn get_limb(self, idx: u64) -> Field  { RuntimeBigNumTrait::get_limb(self, idx) }
    fn set_limb(&mut self, idx: u64, value: Field)  { RuntimeBigNumTrait::set_limb(self, idx, value) }
    fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self { RuntimeBigNumTrait::conditional_select(lhs, rhs, predicate) }
    fn to_le_bytes<let X: u64>(self) -> [u8; X] { RuntimeBigNumTrait::to_le_bytes(self) }
}

impl<let N: u64, Params> BigNumTrait for BigNum<N, Params> where Params: BigNumParamsTrait<N> + RuntimeBigNumParamsTrait<N> {

    
    // Weird compiler issue where if we do not pass `Self` as a parameter to these methods,
    // then a generic struct that conforms to BigNumTrait cannot access these methods?
    // the Params: BigNumParamsTrait<N> needs to be satisfied, but the BigNumTrait has no knowledge of BigNumParamsTrait?
    // but...passing in a Self parameter seems to fix. really weird
    fn modulus_bits(_: Self) -> u64 {
        let r: u64 = Params::modulus_bits();
        r
    }
    fn num_limbs(_: Self) -> u64 { N }

    fn modulus() -> Self {
        Params::get_instance().modulus()
    }

    // ####################################################################################################################
    // ####################################################################################################################
    // ### C  O  N  S  T  R  U  C  T  O  R  S
    // ####################################################################################################################
    // ####################################################################################################################
    // fn new() -> Self {
    //     BigNum { limbs: [0; N] }
    // }

    // fn one() -> Self {
    //     let mut result = BigNum::new();
    //     result.limbs[0] = 1;
    //     result
    // }

    // ####################################################################################################################
    // ####################################################################################################################
    // ### U N C O N S T R A I N E D    F U N C T I O N S
    // ### NOTE: these functions call unconstrained internal implementations because trait impl modifiers are not supported 
    // ####################################################################################################################
    // ####################################################################################################################
    fn __derive_from_seed<let SeedBytes: u64>(seed: [u8; SeedBytes]) -> Self {
        Params::get_instance().__derive_from_seed(seed)
    }

    fn __negate(self) -> Self {
        Params::get_instance().__negate(self)
    }

    fn __addmod(self, rhs: Self) -> Self {
        Params::get_instance().__addmod(self, rhs)
    }

    fn __submod(self, rhs: Self) -> Self {
        Params::get_instance().__submod(self, rhs)
    }

    fn __mulmod(self, rhs: Self) -> Self {
        Params::get_instance().__mulmod(self, rhs)
    }

    fn __divmod(self, rhs: Self) -> Self {
        Params::get_instance().__divmod(self, rhs)
    }

    fn __batch_invert<let M: u64>(x: [Self; M]) -> [Self; M] {
        Params::get_instance().__batch_invert(x)
    }

    // n.b. needs to be declared unconstrained because we return a slice from an unconstrained runtime
    unconstrained fn __batch_invert_slice(x: [Self]) -> [Self] {
        Params::get_instance().__batch_invert_slice(x)
    }
    fn __invmod(self) -> Self {
        Params::get_instance().__invmod(self)
    }

    fn __powmod(self, exponent: Self) -> Self {
        Params::get_instance().__powmod(self, exponent)
    }

    fn __compute_quadratic_expression<let LHS_N: u64, let RHS_N: u64, let NUM_PRODUCTS: u64, let ADD_N: u64>(
        lhs_terms: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [Self; ADD_N],
        linear_flags: [bool; ADD_N]
    ) -> (Self, Self) {
        Params::get_instance().__compute_quadratic_expression(
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
     * @brief Constrain a degree-2 BigNum expression to be equal to 0 modulo Params::modulus()
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
        lhs_terms: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [Self; ADD_N],
        linear_flags: [bool; ADD_N]
    ) {
        Params::get_instance().evaluate_quadratic_expression(
            lhs_terms,
            lhs_flags,
            rhs_terms,
            rhs_flags,
            linear_terms,
            linear_flags
        )
    }

    fn validate_in_field(self: Self) {
        Params::get_instance().validate_in_field(self);
    }

    /**
     * @brief Validate self != other
     * @details If A == B, then A == B mod N.
     *          We can efficiently evaluate A == B mod N where N = circuit modulus
     *          This method is *sound*, but not *complete* (i.e. A != B but A == B mod N)
     *          However the probability of an honest Prover being unable to satisfy this check is tiny!
     *          (todo: compute how tiny)
     **/
    fn assert_is_not_equal(self, other: Self) {
        Params::get_instance().assert_is_not_equal(self, other);
    }

    fn neg(self) -> Self {
        Params::get_instance().neg(self)
    }
}

impl<let N: u64, Params> std::ops::Add for BigNum<N, Params> where Params: BigNumParamsTrait<N> + RuntimeBigNumParamsTrait<N>  {
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    fn add(self, other: Self) -> Self {
        Params::get_instance().add(self, other)
    }
}

impl<let N: u64, Params> std::ops::Sub for BigNum<N, Params> where Params: BigNumParamsTrait<N> + RuntimeBigNumParamsTrait<N>  {
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    fn sub(self, other: Self) -> Self {
        Params::get_instance().sub(self, other)
    }
}

impl<let N: u64, Params> std::ops::Mul for BigNum<N, Params> where Params: BigNumParamsTrait<N> + RuntimeBigNumParamsTrait<N>  {
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    // e.g. performing a sum of multiple multiplications and additions via `evaluate_quadratic_expression`
    //      will create much fewer constraints than calling `mul` and `add` directly
    fn mul(self, other: Self) -> Self {
        Params::get_instance().mul(self, other)
    }
}

impl<let N: u64, Params> std::ops::Div for BigNum<N, Params> where Params: BigNumParamsTrait<N> + RuntimeBigNumParamsTrait<N>  {
    // Note: this method is expensive! Witness computation is extremely expensive as it requires modular exponentiation
    fn div(self, other: Self) -> Self {
        Params::get_instance().div(self, other)
    }
}

impl<let N: u64, Params> std::cmp::Eq for BigNum<N, Params> where Params: BigNumParamsTrait<N> + RuntimeBigNumParamsTrait<N>  {

    fn eq(self, other: Self) -> bool {
        let bn: RuntimeBigNumInstance<N, Params> = Params::get_instance();
        bn.eq(self, other)
    }
}
