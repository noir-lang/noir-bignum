use crate::params::BigNumParams;
use crate::utils::map::map;

use crate::fns::{
    constrained_ops::{
        add, assert_is_not_equal, cmp, derive_from_seed, div, eq, is_zero, mul, neg, sub, udiv,
        udiv_mod, umod, validate_in_field, validate_in_range,
    },
    serialization::{from_be_bytes, from_le_bytes, to_be_bytes, to_le_bytes},
    unconstrained_ops::{
        __add, __derive_from_seed, __div, __eq, __invmod, __is_zero, __mul, __neg, __pow, __sub,
        __tonelli_shanks_sqrt, __udiv_mod,
    },
};
use std::{cmp::Ordering, ops::Neg};

pub struct RuntimeBigNum<let N: u32, let MOD_BITS: u32> {
    pub limbs: [u128; N],
    pub params: BigNumParams<N, MOD_BITS>,
}

// All functions prefixed `__` are unconstrained!
// They're not actually decorated as `unconstrained` because to return the `params` (as part of Self) from an `unconstrained` fn would cause range constraints. Instead, each `__` fn wraps a call to an unconstrained fn, so that the already-range-constrained `params` can be inserted into Self after the unconstrained call.
impl<let N: u32, let MOD_BITS: u32> RuntimeBigNum<N, MOD_BITS> {

    pub fn zero(params: BigNumParams<N, MOD_BITS>) -> Self {
        let limbs: [u128; N] = [0; N];
        Self { limbs, params }
    }

    pub fn one(params: BigNumParams<N, MOD_BITS>) -> Self {
        let mut result = RuntimeBigNum::zero(params);
        result.limbs[0] = 1;
        result
    }

    pub fn derive_from_seed<let SeedBytes: u32>(
        params: BigNumParams<N, MOD_BITS>,
        seed: [u8; SeedBytes],
    ) -> Self {
        let limbs = derive_from_seed::<_, MOD_BITS, _>(params, seed);
        Self { limbs, params }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    pub unconstrained fn __derive_from_seed<let SeedBytes: u32>(
        params: BigNumParams<N, MOD_BITS>,
        seed: [u8; SeedBytes],
    ) -> Self {
        let limbs = __derive_from_seed::<_, MOD_BITS, _>(params, seed);
        Self { limbs, params }
    }

    pub fn from_slice(params: BigNumParams<N, MOD_BITS>, limbs: [u128]) -> Self {
        Self { limbs: limbs.as_array(), params }
    }

    pub fn from_array(params: BigNumParams<N, MOD_BITS>, limbs: [u128; N]) -> Self {
        Self { limbs, params }
    }

    pub fn from_be_bytes(params: BigNumParams<N, MOD_BITS>, x: [u8; (MOD_BITS + 7) / 8]) -> Self {
        Self { limbs: from_be_bytes::<_, MOD_BITS>(x), params }
    }

    pub fn from_le_bytes(params: BigNumParams<N, MOD_BITS>, x: [u8; (MOD_BITS + 7) / 8]) -> Self {
        Self { limbs: from_le_bytes::<_, MOD_BITS>(x), params }
    }

    pub fn to_be_bytes(self) -> [u8; (MOD_BITS + 7) / 8] {
        to_be_bytes::<_, MOD_BITS>(self.limbs)
    }

    pub fn to_le_bytes(self) -> [u8; (MOD_BITS + 7) / 8] {
        to_le_bytes::<_, MOD_BITS>(self.limbs)
    }

    pub fn modulus(self) -> Self {
        let params = self.params;
        Self { limbs: params.modulus, params }
    }

    pub fn modulus_bits() -> u32 {
        MOD_BITS
    }

    pub fn num_limbs() -> u32 {
        N
    }

    // fn get(self) -> [Field] {
    //     self.get_limbs()
    // }

    pub fn get_limbs(self) -> [u128; N] {
        self.limbs
    }

    pub fn get_limb(self, idx: u32) -> u128 {
        self.limbs[idx]
    }

    pub fn set_limb(&mut self, idx: u32, value: u128) {
        self.limbs[idx] = value;
    }

    pub unconstrained fn __eq(self, other: Self) -> bool {
        assert(self.params == other.params);
        __eq(self.limbs, other.limbs)
    }

    pub unconstrained fn __is_zero(self) -> bool {
        __is_zero(self.limbs)
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    pub fn __neg(self) -> Self {
        let params = self.params;
        let limbs = unsafe { __neg(params.modulus, self.limbs) };
        Self { params, limbs }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    pub fn __add(self, other: Self) -> Self {
        let params = self.params;
        assert(params == other.params);
        let limbs = unsafe { __add(params.modulus, self.limbs, other.limbs) };
        Self { params, limbs }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    pub fn __sub(self, other: Self) -> Self {
        let params = self.params;
        assert(params == other.params);
        let limbs = unsafe { __sub(params.modulus, self.limbs, other.limbs) };
        Self { params, limbs }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    pub fn __mul(self, other: Self) -> Self {
        let params = self.params;
        assert(params == other.params);
        let limbs = unsafe { __mul::<_, MOD_BITS>(params, self.limbs, other.limbs) };
        Self { params, limbs }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    pub fn __div(self, divisor: Self) -> Self {
        let params = self.params;
        assert(params == divisor.params);
        let limbs = unsafe { __div::<_, MOD_BITS>(params, self.limbs, divisor.limbs) };
        Self { params, limbs }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    pub fn __udiv_mod(self, divisor: Self) -> (Self, Self) {
        let params = self.params;
        assert(params == divisor.params);
        let (q, r) = unsafe { __udiv_mod(self.limbs, divisor.limbs) };
        (Self { limbs: q, params }, Self { limbs: r, params })
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    pub fn __invmod(self) -> Self {
        let params = self.params;
        assert(params.has_multiplicative_inverse);
        let limbs = unsafe { __invmod::<_, MOD_BITS>(params, self.limbs) };
        Self { limbs, params }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    pub fn __pow(self, exponent: Self) -> Self {
        let params = self.params;
        assert(params == exponent.params);
        let limbs = unsafe { __pow::<_, MOD_BITS>(params, self.limbs, exponent.limbs) };
        Self { limbs, params }
    }

    // UNCONSTRAINED! (Hence `__` prefix).
    pub fn __tonelli_shanks_sqrt(self) -> std::option::Option<Self> {
        let params = self.params;
        let maybe_limbs = unsafe { __tonelli_shanks_sqrt(params, self.limbs) };
        maybe_limbs.map(|limbs| Self { limbs, params })
    }

    pub fn validate_in_field(self: Self) {
        let params = self.params;
        validate_in_field::<_, MOD_BITS>(params, self.limbs);
    }

    pub fn validate_in_range(self) {
        validate_in_range::<_, _, MOD_BITS>(self.limbs);
    }

    pub fn assert_is_not_equal(self, other: Self) {
        let params = self.params;
        assert(params == other.params);
        assert_is_not_equal(params, self.limbs, other.limbs);
    }

    pub fn udiv_mod(self, divisor: Self) -> (Self, Self) {
        let params = self.params;
        assert(params == divisor.params);
        let (q, r) = udiv_mod::<_, MOD_BITS>(params, self.limbs, divisor.limbs);
        (Self { limbs: q, params }, Self { limbs: r, params })
    }

    pub fn udiv(self, divisor: Self) -> Self {
        let params = self.params;
        assert(params == divisor.params);
        Self { limbs: udiv::<_, MOD_BITS>(params, self.limbs, divisor.limbs), params }
    }

    pub fn umod(self, divisor: Self) -> Self {
        let params = self.params;
        assert(params == divisor.params);
        Self { limbs: umod::<_, MOD_BITS>(params, self.limbs, divisor.limbs), params }
    }

    pub fn is_zero(self) -> bool {
        is_zero::<N, MOD_BITS>(self.limbs)
    }
}

impl<let N: u32, let MOD_BITS: u32> std::ops::Add for RuntimeBigNum<N, MOD_BITS> {
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    fn add(self, other: Self) -> Self {
        let params = self.params;
        assert(params == other.params);
        Self { limbs: add::<_, MOD_BITS>(params, self.limbs, other.limbs), params }
    }
}

impl<let N: u32, let MOD_BITS: u32> std::ops::Sub for RuntimeBigNum<N, MOD_BITS> {
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    fn sub(self, other: Self) -> Self {
        let params = self.params;
        assert(params == other.params);
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
        assert(params == other.params);
        Self { limbs: mul::<_, MOD_BITS>(params, self.limbs, other.limbs), params }
    }
}

impl<let N: u32, let MOD_BITS: u32> std::ops::Div for RuntimeBigNum<N, MOD_BITS> {
    // Note: this method is expensive! Witness computation is extremely expensive as it requires modular exponentiation
    fn div(self, divisor: Self) -> Self {
        let params = self.params;
        assert(params == divisor.params);
        Self { limbs: div::<_, MOD_BITS>(params, self.limbs, divisor.limbs), params }
    }
}

impl<let N: u32, let MOD_BITS: u32> Neg for RuntimeBigNum<N, MOD_BITS> {
    fn neg(self) -> Self {
        let params = self.params;
        Self { limbs: neg::<_, MOD_BITS>(params, self.limbs), params }
    }
}

impl<let N: u32, let MOD_BITS: u32> std::cmp::Eq for RuntimeBigNum<N, MOD_BITS> {
    fn eq(self, other: Self) -> bool {
        let params = self.params;
        assert(params == other.params);
        eq::<_, MOD_BITS>(params, self.limbs, other.limbs)
    }
}

impl<let N: u32, let MOD_BITS: u32> std::cmp::Ord for RuntimeBigNum<N, MOD_BITS> {
    fn cmp(self, other: Self) -> Ordering {
        assert(self.params == other.params);
        cmp::<_, MOD_BITS>(self.limbs, other.limbs)
    }
}

// UNCONSTRAINED! (Hence `__` prefix).
pub fn __compute_quadratic_expression<let N: u32, let MOD_BITS: u32, let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs_terms: [[RuntimeBigNum<N, MOD_BITS>; LHS_N]; NUM_PRODUCTS],
    lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
    rhs_terms: [[RuntimeBigNum<N, MOD_BITS>; RHS_N]; NUM_PRODUCTS],
    rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
    linear_terms: [RuntimeBigNum<N, MOD_BITS>; ADD_N],
    linear_flags: [bool; ADD_N],
) -> (RuntimeBigNum<N, MOD_BITS>, RuntimeBigNum<N, MOD_BITS>) {
    let (q_limbs, r_limbs) = unsafe {
        crate::fns::expressions::compute_quadratic_expression::<_, MOD_BITS, _, _, _, _>(
            params,
            map(lhs_terms, |bns| map(bns, |bn| RuntimeBigNum::get_limbs(bn))),
            lhs_flags,
            map(rhs_terms, |bns| map(bns, |bn| RuntimeBigNum::get_limbs(bn))),
            rhs_flags,
            map(linear_terms, |bn| RuntimeBigNum::get_limbs(bn)),
            linear_flags,
        )
    };
    (RuntimeBigNum { limbs: q_limbs, params }, RuntimeBigNum { limbs: r_limbs, params })
}

pub fn evaluate_quadratic_expression<let N: u32, let MOD_BITS: u32, let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
    params: BigNumParams<N, MOD_BITS>,
    lhs_terms: [[RuntimeBigNum<N, MOD_BITS>; LHS_N]; NUM_PRODUCTS],
    lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
    rhs_terms: [[RuntimeBigNum<N, MOD_BITS>; RHS_N]; NUM_PRODUCTS],
    rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
    linear_terms: [RuntimeBigNum<N, MOD_BITS>; ADD_N],
    linear_flags: [bool; ADD_N],
) {
    crate::fns::expressions::evaluate_quadratic_expression::<_, MOD_BITS, _, _, _, _>(
        params,
        map(lhs_terms, |bns| map(bns, |bn| RuntimeBigNum::get_limbs(bn))),
        lhs_flags,
        map(rhs_terms, |bns| map(bns, |bn| RuntimeBigNum::get_limbs(bn))),
        rhs_flags,
        map(linear_terms, |bn| RuntimeBigNum::get_limbs(bn)),
        linear_flags,
    )
}

// UNCONSTRAINED! (Hence `__` prefix).
pub fn __batch_invert<let N: u32, let MOD_BITS: u32, let M: u32>(
    x: [RuntimeBigNum<N, MOD_BITS>; M],
) -> [RuntimeBigNum<N, MOD_BITS>; M] {
    let params = x[0].params;
    assert(params.has_multiplicative_inverse);
    let all_limbs = unsafe {
        crate::fns::unconstrained_ops::batch_invert::<_, MOD_BITS, _>(
            params,
            x.map(|bn| RuntimeBigNum::get_limbs(bn)),
        )
    };
    all_limbs.map(|limbs| RuntimeBigNum { limbs, params })
}

pub unconstrained fn __batch_invert_slice<let N: u32, let MOD_BITS: u32, let M: u32>(
    x: [RuntimeBigNum<N, MOD_BITS>],
) -> [RuntimeBigNum<N, MOD_BITS>] {
    let params = x[0].params;
    assert(params.has_multiplicative_inverse);
    let all_limbs = crate::fns::unconstrained_ops::batch_invert_slice::<_, MOD_BITS>(
        params,
        x.map(|bn| RuntimeBigNum::get_limbs(bn)),
    );

    all_limbs.map(|limbs| RuntimeBigNum { limbs, params })
}

pub fn conditional_select<let N: u32, let MOD_BITS: u32>(
    lhs: RuntimeBigNum<N, MOD_BITS>,
    rhs: RuntimeBigNum<N, MOD_BITS>,
    predicate: bool,
) -> RuntimeBigNum<N, MOD_BITS> {
    let params = lhs.params;
    assert(params == rhs.params);
    let limbs = if predicate { lhs.limbs } else { rhs.limbs };
    RuntimeBigNum { limbs: limbs, params }
}
