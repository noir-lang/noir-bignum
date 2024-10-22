use dep::std;
use crate::utils::map::map;

use crate::params::BigNumParams;
use crate::constrained_ops::{
    derive_from_seed, conditional_select, assert_is_not_equal, eq, validate_in_field, validate_in_range,
    neg, add, sub, mul, div, udiv_mod, udiv, umod
};
use crate::unconstrained_ops::{
    __derive_from_seed, __eq, __is_zero, __neg, __add, __sub, __mul, __div, __udiv_mod, __invmod, __pow,
    __batch_invert, __batch_invert_slice //, __tonelli_shanks_sqrt
};
use crate::expressions::{__compute_quadratic_expression, evaluate_quadratic_expression};
use crate::serialization::{from_be_bytes, to_le_bytes};

pub struct RuntimeBigNum<let N: u32, let MOD_BITS: u32> {
    limbs: [Field; N],
    params: BigNumParams<N, MOD_BITS>,
}

impl<let N: u32, let MOD_BITS: u32> RuntimeBigNum<N, MOD_BITS> {}

// All functions prefixed `__` are unconstrained!
// They're not actually decorated as `unconstrained` because to return the `params` (as part of Self) from an `unconstrained` fn would cause range constraints. Instead, each `__` fn wraps a call to an unconstrained fn, so that the already-range-constrained `params` can be inserted into Self after the unconstrained call.
pub(crate) trait RuntimeBigNumTrait<let N: u32, let MOD_BITS: u32> {
    fn new(params: BigNumParams<N, MOD_BITS>) -> Self;
    fn one(params: BigNumParams<N, MOD_BITS>) -> Self;
    fn derive_from_seed<let SeedBytes: u32>(params: BigNumParams<N, MOD_BITS>, seed: [u8; SeedBytes]) -> Self;
    fn __derive_from_seed<let SeedBytes: u32>(params: BigNumParams<N, MOD_BITS>, seed: [u8; SeedBytes]) -> Self;
    fn from_slice(params: BigNumParams<N, MOD_BITS>, limbs: [Field]) -> Self;
    fn from_array(params: BigNumParams<N, MOD_BITS>, limbs: [Field; N]) -> Self;
    fn from_be_bytes<let NBytes: u32>(params: BigNumParams<N, MOD_BITS>, x: [u8; NBytes]) -> Self;

    fn to_le_bytes<let NBytes: u32>(self) -> [u8; NBytes];

    fn modulus(self) -> Self;
    fn modulus_bits(self) -> u32;
    fn num_limbs() -> u32;
    // fn get(self) -> [Field];
    fn get_limbs(self) -> [Field; N];
    fn get_limb(self, idx: u32) -> Field;
    fn set_limb(&mut self, idx: u32, value: Field);

    unconstrained fn __eq(self, other: Self) -> bool;
    unconstrained fn __is_zero(self) -> bool;

    fn __neg(self) -> Self;
    fn __add(self, other: Self) -> Self;
    fn __sub(self, other: Self) -> Self;
    fn __mul(self, other: Self) -> Self;
    fn __div(self, other: Self) -> Self;
    fn __udiv_mod(self, divisor: Self) -> (Self, Self);
    fn __invmod(self) -> Self;
    fn __pow(self, exponent: Self) -> Self;

    fn __batch_invert<let M: u32>(x: [Self; M]) -> [Self; M];
    unconstrained fn __batch_invert_slice<let M: u32>(to_invert: [Self]) -> [Self];

    // unconstrained fn __tonelli_shanks_sqrt(self) -> (bool, Self);

    fn __compute_quadratic_expression<let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
        params: BigNumParams<N, MOD_BITS>,
        lhs_terms: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [Self; ADD_N],
        linear_flags: [bool; ADD_N]
    ) -> (Self, Self);

    fn evaluate_quadratic_expression<let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
        params: BigNumParams<N, MOD_BITS>,
        lhs_terms: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [Self; ADD_N],
        linear_flags: [bool; ADD_N]
    );

    fn eq(lhs: Self, rhs: Self) -> bool { lhs == rhs }
    fn assert_is_not_equal(self, other: Self);
    fn validate_in_field(self);
    fn validate_in_range(self);
    // fn validate_gt(self, lhs: Self, rhs: Self);

    fn neg(self) -> Self;
    fn add(lhs: Self, rhs: Self) -> Self { lhs + rhs }
    fn sub(lhs: Self, rhs: Self) -> Self { lhs - rhs }
    fn mul(lhs: Self, rhs: Self) -> Self { lhs * rhs }
    fn div(lhs: Self, rhs: Self) -> Self { lhs / rhs }
    fn udiv_mod(numerator: Self, divisor: Self) -> (Self, Self);
    fn udiv(numerator: Self, divisor: Self) -> Self;
    fn umod(numerator: Self, divisor: Self) -> Self;

    fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self;
}

impl<let N: u32, let MOD_BITS: u32> RuntimeBigNumTrait<N, MOD_BITS> for RuntimeBigNum<N, MOD_BITS> {

    fn new(params: BigNumParams<N, MOD_BITS>) -> Self {
        let limbs: [Field; N] = [0; N];
        Self { limbs, params }
    }

    fn one(params: BigNumParams<N, MOD_BITS>) -> Self {
        let mut result = RuntimeBigNum::new(params);
        result.limbs[0] = 1;
        result
    }

    fn derive_from_seed<let SeedBytes: u32>(params: BigNumParams<N, MOD_BITS>, seed: [u8; SeedBytes]) -> Self {
        let limbs = unsafe {
            derive_from_seed::<_, MOD_BITS, _>(params, seed)
        };
        Self { limbs, params }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    fn __derive_from_seed<let SeedBytes: u32>(params: BigNumParams<N, MOD_BITS>, seed: [u8; SeedBytes]) -> Self {
        let limbs = unsafe {
            __derive_from_seed::<_, MOD_BITS, _>(params, seed)
        };
        Self { limbs, params }
    }

    fn from_slice(params: BigNumParams<N, MOD_BITS>, limbs: [Field]) -> Self {
        Self { limbs: limbs.as_array(), params }
    }

    fn from_array(params: BigNumParams<N, MOD_BITS>, limbs: [Field; N]) -> Self {
        Self { limbs, params }
    }

    fn from_be_bytes<let NBytes: u32>(params: BigNumParams<N, MOD_BITS>, x: [u8; NBytes]) -> Self {
        Self { limbs: from_be_bytes::<_, MOD_BITS, _>(params, x), params }
    }

    fn to_le_bytes<let NBytes: u32>(self) -> [u8; NBytes] {
        to_le_bytes::<_, MOD_BITS, _>(self.params, self.limbs)
    }

    fn modulus(self) -> Self {
        let params = self.params;
        Self { limbs: params.modulus, params }
    }

    fn modulus_bits(self) -> u32 {
        MOD_BITS
    }

    fn num_limbs() -> u32 {
        N
    }

    // fn get(self) -> [Field] {
    //     self.get_limbs()
    // }

    fn get_limbs(self) -> [Field; N] {
        self.limbs
    }

    fn get_limb(self, idx: u32) -> Field {
        self.limbs[idx]
    }

    fn set_limb(&mut self, idx: u32, value: Field) {
        self.limbs[idx] = value;
    }

    unconstrained fn __eq(self, other: Self) -> bool {
        __eq(self.limbs, other.limbs)
    }

    unconstrained fn __is_zero(self) -> bool {
        __is_zero(self.limbs)
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    fn __neg(self) -> Self {
        let params = self.params;
        let limbs = unsafe {
            __neg(params, self.limbs)
        };
        Self { params, limbs }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    fn __add(self, other: Self) -> Self {
        let params = self.params;
        let limbs = unsafe {
            __add(params, self.limbs, other.limbs)
        };
        Self { params, limbs }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    fn __sub(self, other: Self) -> Self {
        let params = self.params;
        let limbs = unsafe {
            __sub(params, self.limbs, other.limbs)
        };
        Self { params, limbs }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    fn __mul(self, other: Self) -> Self {
        let params = self.params;
        let limbs = unsafe {
            __mul::<_, MOD_BITS>(params, self.limbs, other.limbs)
        };
        Self { params, limbs }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    fn __div(self, divisor: Self) -> Self {
        let params = self.params;
        let limbs = unsafe {
            __div::<_, MOD_BITS>(params, self.limbs, divisor.limbs)
        };
        Self { params, limbs }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    fn __udiv_mod(self, divisor: Self) -> (Self, Self) {
        let params = self.params;
        let (q, r) = unsafe {
            __udiv_mod(self.limbs, divisor.limbs)
        };
        (Self { limbs: q, params }, Self { limbs: r, params })
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    fn __invmod(self) -> Self {
        let params = self.params;
        assert(params.has_multiplicative_inverse);
        let limbs = unsafe {
            __invmod::<_, MOD_BITS>(params, self.limbs)
        };
        Self { limbs, params }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    fn __pow(self, exponent: Self) -> Self {
        let params = self.params;
        let limbs = unsafe {
            __pow::<_, MOD_BITS>(params, self.limbs, exponent.limbs)
        };
        Self { limbs, params }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    fn __batch_invert<let M: u32>(x: [Self; M]) -> [Self; M] {
        let params = x[0].params;
        assert(params.has_multiplicative_inverse);
        let all_limbs = unsafe {
            __batch_invert::<_, MOD_BITS, _>(params, x.map(|bn| Self::get_limbs(bn)))
        };
        all_limbs.map(|limbs| Self { limbs, params })
    }

    // Note: can't return a slice from this unconstrained to a constrained function.
    unconstrained fn __batch_invert_slice<let M: u32>(x: [Self]) -> [Self] {
        let params = x[0].params;
        assert(params.has_multiplicative_inverse);
        let all_limbs = unsafe {
            let inv_slice = __batch_invert_slice::<_, MOD_BITS>(params, x.map(|bn| Self::get_limbs(bn)));
            inv_slice.as_array()
        };
        all_limbs.map(|limbs| Self { limbs, params })
    }

    // @dev We intentionally don't use std::option::Option, because the Option::none() case doesn't propagate the `params`, so the code breaks. Specifically, the code stops evaluating modulus_bits = self.params.modulus_bits_getter() as constant, which then breaks calls to `validate_in_range()` (e.g. via calls to `==` on `self`), because `validate_in_range` calls `assert_max_bit_size` on a value derived from `modulus_bits`. I'm not sure why it stops evaluating the getter's return value as constant if we return a std::Option, really.
    // unconstrained fn __tonelli_shanks_sqrt(self) -> (bool, Self) {
    //     let params = self.params;
    //     let maybe_limbs = unsafe {
    //         __tonelli_shanks_sqrt(params, self.limbs)
    //     };
    //     let result: (bool, Self) = if maybe_limbs.is_some() {
    //         (true, Self { limbs: maybe_limbs.unwrap_unchecked(), params })
    //     } else {
    //         (false, Self::new(params))
    //     };
    //     result
    // }

    // UNCONSTRAINED! (Hence `__` prefix).
    fn __compute_quadratic_expression<let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
        params: BigNumParams<N, MOD_BITS>,
        lhs_terms: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [Self; ADD_N],
        linear_flags: [bool; ADD_N]
    ) -> (Self, Self) {
        let (q_limbs, r_limbs) = unsafe {
            __compute_quadratic_expression::<_, MOD_BITS, _, _, _, _>(
                params,
                map(lhs_terms, |bns| map(bns, |bn| Self::get_limbs(bn))),
                lhs_flags,
                map(rhs_terms, |bns| map(bns, |bn| Self::get_limbs(bn))),
                rhs_flags,
                map(linear_terms, |bn| Self::get_limbs(bn)),
                linear_flags
            )
        };
        (Self { limbs: q_limbs, params }, Self { limbs: r_limbs, params })
    }

    fn evaluate_quadratic_expression<let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
        params: BigNumParams<N, MOD_BITS>,
        lhs_terms: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [Self; ADD_N],
        linear_flags: [bool; ADD_N]
    ) {
        evaluate_quadratic_expression::<_, MOD_BITS, _, _, _, _>(
            params,
            map(lhs_terms, |bns| map(bns, |bn| Self::get_limbs(bn))),
            lhs_flags,
            map(rhs_terms, |bns| map(bns, |bn| Self::get_limbs(bn))),
            rhs_flags,
            map(linear_terms, |bn| Self::get_limbs(bn)),
            linear_flags
        )
    }

    fn validate_in_field(self: Self) {
        let params = self.params;
        validate_in_field::<_, MOD_BITS>(params, self.limbs);
    }

    fn validate_in_range(self) {
        let params = self.params;
        validate_in_range::<_, MOD_BITS>(params, self.limbs);
    }

    fn assert_is_not_equal(self, other: Self) {
        let params = self.params;
        assert_is_not_equal(params, self.limbs, other.limbs);
    }

    fn neg(self) -> Self {
        let params = self.params;
        Self { limbs: neg::<_, MOD_BITS>(params, self.limbs), params }
    }

    fn udiv_mod(self, divisor: Self) -> (Self, Self) {
        let params = self.params;
        let (q, r) = udiv_mod::<_, MOD_BITS>(params, self.limbs, divisor.limbs);
        (Self { limbs: q, params }, Self { limbs: r, params })
    }

    fn udiv(self, divisor: Self) -> Self {
        let params = self.params;
        Self { limbs: udiv::<_, MOD_BITS>(params, self.limbs, divisor.limbs), params }
    }

    fn umod(self, divisor: Self) -> Self {
        let params = self.params;
        Self { limbs: umod::<_, MOD_BITS>(params, self.limbs, divisor.limbs), params }
    }

    fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self {
        let params = lhs.params;
        Self { limbs: conditional_select(lhs.limbs, rhs.limbs, predicate), params }
    }
}

impl<let N: u32, let MOD_BITS: u32> std::ops::Add for RuntimeBigNum<N, MOD_BITS> {
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    fn add(self, other: Self) -> Self {
        let params = self.params;
        Self { limbs: add::<_, MOD_BITS>(params, self.limbs, other.limbs), params }
    }
}

impl<let N: u32, let MOD_BITS: u32> std::ops::Sub for RuntimeBigNum<N, MOD_BITS> {
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    fn sub(self, other: Self) -> Self {
        let params = self.params;
        Self { limbs: sub::<_, MOD_BITS>(params, self.limbs, other.limbs), params }
    }
}

impl<let N: u32, let MOD_BITS: u32> std::ops::Mul for RuntimeBigNum<N, MOD_BITS> {
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    // e.g. performing a sum of multiple multiplications and additions via `evaluate_quadratic_expression`
    //      will create much fewer constraints than calling `mul` and `add` directly
    fn mul(self, other: Self) -> Self {
        let params = self.params;
        Self { limbs: mul::<_, MOD_BITS>(params, self.limbs, other.limbs), params }
    }
}

impl<let N: u32, let MOD_BITS: u32> std::ops::Div for RuntimeBigNum<N, MOD_BITS> {
    // Note: this method is expensive! Witness computation is extremely expensive as it requires modular exponentiation
    fn div(self, divisor: Self) -> Self {
        let params = self.params;
        Self { limbs: div::<_, MOD_BITS>(params, self.limbs, divisor.limbs), params }
    }
}

impl<let N: u32, let MOD_BITS: u32> std::cmp::Eq for RuntimeBigNum<N, MOD_BITS> {
    fn eq(self, other: Self) -> bool {
        let params = self.params;
        eq::<_, MOD_BITS>(params, self.limbs, other.limbs)
    }
}
