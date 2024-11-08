use crate::utils::map::map;

use crate::params::BigNumParamsGetter;

use crate::fns::{
    constrained_ops::{
        add, assert_is_not_equal, conditional_select, derive_from_seed, div, eq, mul, neg, sub,
        udiv, udiv_mod, umod, validate_in_field, validate_in_range,
    }, expressions::{__compute_quadratic_expression, evaluate_quadratic_expression},
    serialization::{from_be_bytes, to_le_bytes},
    unconstrained_ops::{
        __add, __batch_invert, __batch_invert_slice, __derive_from_seed, __div, __eq, __invmod,
        __is_zero, __mul, __neg, __pow, __sub, __tonelli_shanks_sqrt, __udiv_mod,
    },
};

pub struct BigNum<let N: u32, let MOD_BITS: u32, Params> {
    pub limbs: [Field; N],
}
// We aim to avoid needing to add a generic parameter to this trait, for this reason we do not allow
// accessing the limbs of the bignum except through slices.
pub trait BigNumTrait {
    // TODO: this crashes the compiler? v0.32
    // fn default() -> Self { std::default::Default::default  () }
    pub fn new() -> Self;
    pub fn one() -> Self;
    pub fn derive_from_seed<let SeedBytes: u32>(seed: [u8; SeedBytes]) -> Self;
    pub unconstrained fn __derive_from_seed<let SeedBytes: u32>(seed: [u8; SeedBytes]) -> Self;
    pub fn from_slice(limbs: [Field]) -> Self;
    pub fn from_be_bytes<let NBytes: u32>(x: [u8; NBytes]) -> Self;
    pub fn to_le_bytes<let NBytes: u32>(self) -> [u8; NBytes];

    pub fn modulus() -> Self;
    pub fn modulus_bits(self) -> u32;
    pub fn num_limbs(self) -> u32;
    pub fn get_limbs_slice(self) -> [Field];
    pub fn get_limb(self, idx: u32) -> Field;
    pub fn set_limb(&mut self, idx: u32, value: Field);

    pub unconstrained fn __eq(self, other: Self) -> bool;
    pub unconstrained fn __is_zero(self) -> bool;

    pub unconstrained fn __neg(self) -> Self;
    pub unconstrained fn __add(self, other: Self) -> Self;
    pub unconstrained fn __sub(self, other: Self) -> Self;
    pub unconstrained fn __mul(self, other: Self) -> Self;
    pub unconstrained fn __div(self, other: Self) -> Self;
    pub unconstrained fn __udiv_mod(self, divisor: Self) -> (Self, Self);
    pub unconstrained fn __invmod(self) -> Self;
    pub unconstrained fn __pow(self, exponent: Self) -> Self;

    pub unconstrained fn __batch_invert<let M: u32>(to_invert: [Self; M]) -> [Self; M];
    pub unconstrained fn __batch_invert_slice<let M: u32>(to_invert: [Self]) -> [Self];

    pub unconstrained fn __tonelli_shanks_sqrt(self) -> std::option::Option<Self>;

    pub unconstrained fn __compute_quadratic_expression<let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
        lhs: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        add: [Self; ADD_N],
        add_flags: [bool; ADD_N],
    ) -> (Self, Self);

    pub fn evaluate_quadratic_expression<let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
        lhs: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        add: [Self; ADD_N],
        add_flags: [bool; ADD_N],
    );

    pub fn eq(self, other: Self) -> bool {
        self == other
    }
    pub fn assert_is_not_equal(self, other: Self);
    pub fn validate_in_range(self);
    pub fn validate_in_field(self);

    pub fn neg(self) -> Self;
    pub fn add(self, other: Self) -> Self {
        self + other
    }
    pub fn sub(self, other: Self) -> Self {
        self - other
    }
    pub fn mul(self, other: Self) -> Self {
        self * other
    }
    pub fn div(self, other: Self) -> Self {
        self / other
    }
    pub fn udiv_mod(self, divisor: Self) -> (Self, Self);
    pub fn udiv(self, divisor: Self) -> Self;
    pub fn umod(self, divisor: Self) -> Self;

    pub fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self;
}

impl<let N: u32, let MOD_BITS: u32, Params> BigNumTrait for BigNum<N, MOD_BITS, Params>
where
    Params: BigNumParamsGetter<N, MOD_BITS>,
{

    fn new() -> Self {
        Self { limbs: [0; N] }
    }

    fn one() -> Self {
        let mut result = BigNum::new();
        result.limbs[0] = 1;
        result
    }

    fn derive_from_seed<let SeedBytes: u32>(seed: [u8; SeedBytes]) -> Self {
        let params = Params::get_params();
        Self { limbs: derive_from_seed::<_, MOD_BITS, _>(params, seed) }
    }

    unconstrained fn __derive_from_seed<let SeedBytes: u32>(seed: [u8; SeedBytes]) -> Self {
        let params = Params::get_params();
        Self { limbs: __derive_from_seed::<_, MOD_BITS, _>(params, seed) }
    }

    fn from_slice(limbs: [Field]) -> Self {
        Self { limbs: limbs.as_array() }
    }

    fn from_be_bytes<let NBytes: u32>(x: [u8; NBytes]) -> Self {
        Self { limbs: from_be_bytes::<_, MOD_BITS, _>(x) }
    }

    fn to_le_bytes<let NBytes: u32>(self) -> [u8; NBytes] {
        to_le_bytes::<_, MOD_BITS, _>(self.limbs)
    }

    fn modulus() -> Self {
        Self { limbs: Params::get_params().modulus }
    }

    fn modulus_bits(_: Self) -> u32 {
        MOD_BITS
    }

    fn num_limbs(_: Self) -> u32 {
        N
    }

    fn get_limbs_slice(self) -> [Field] {
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

    unconstrained fn __neg(self) -> Self {
        let params = Params::get_params();
        Self::from_slice(__neg(params, self.limbs))
    }

    unconstrained fn __add(self, other: Self) -> Self {
        let params = Params::get_params();
        Self::from_slice(__add(params, self.limbs, other.limbs))
    }

    unconstrained fn __sub(self, other: Self) -> Self {
        let params = Params::get_params();
        Self::from_slice(__sub(params, self.limbs, other.limbs))
    }

    unconstrained fn __mul(self, other: Self) -> Self {
        let params = Params::get_params();
        Self::from_slice(__mul::<_, MOD_BITS>(params, self.limbs, other.limbs))
    }

    unconstrained fn __div(self, divisor: Self) -> Self {
        let params = Params::get_params();
        Self::from_slice(__div::<_, MOD_BITS>(params, self.limbs, divisor.limbs))
    }

    unconstrained fn __udiv_mod(self, divisor: Self) -> (Self, Self) {
        let (q, r) = __udiv_mod(self.limbs, divisor.limbs);
        (Self { limbs: q }, Self { limbs: r })
    }

    unconstrained fn __invmod(self) -> Self {
        let params = Params::get_params();
        assert(params.has_multiplicative_inverse);
        Self { limbs: __invmod::<_, MOD_BITS>(params, self.limbs) }
    }

    unconstrained fn __pow(self, exponent: Self) -> Self {
        let params = Params::get_params();
        Self { limbs: __pow::<_, MOD_BITS>(params, self.limbs, exponent.limbs) }
    }

    unconstrained fn __batch_invert<let M: u32>(x: [Self; M]) -> [Self; M] {
        let params = Params::get_params();
        assert(params.has_multiplicative_inverse);
        __batch_invert::<_, MOD_BITS, _>(params, x.map(|bn| Self::get_limbs_slice(bn).as_array()))
            .map(|limbs| Self { limbs })
    }

    unconstrained fn __batch_invert_slice<let M: u32>(x: [Self]) -> [Self] {
        let params = Params::get_params();
        assert(params.has_multiplicative_inverse);
        __batch_invert_slice::<_, MOD_BITS>(
            params,
            x.map(|bn| Self::get_limbs_slice(bn).as_array()),
        )
            .map(|limbs| Self { limbs })
    }

    unconstrained fn __tonelli_shanks_sqrt(self) -> std::option::Option<Self> {
        let params = Params::get_params();
        let maybe_limbs = unsafe { __tonelli_shanks_sqrt(params, self.limbs) };
        maybe_limbs.map(|limbs| Self { limbs })
    }

    unconstrained fn __compute_quadratic_expression<let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
        lhs_terms: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [Self; ADD_N],
        linear_flags: [bool; ADD_N],
    ) -> (Self, Self) {
        let params = Params::get_params();
        let (q_limbs, r_limbs) = __compute_quadratic_expression::<_, MOD_BITS, _, _, _, _>(
            params,
            map(
                lhs_terms,
                |bns| map(bns, |bn| Self::get_limbs_slice(bn).as_array()),
            ),
            lhs_flags,
            map(
                rhs_terms,
                |bns| map(bns, |bn| Self::get_limbs_slice(bn).as_array()),
            ),
            rhs_flags,
            map(linear_terms, |bn| Self::get_limbs_slice(bn).as_array()),
            linear_flags,
        );
        (Self { limbs: q_limbs }, Self { limbs: r_limbs })
    }

    fn evaluate_quadratic_expression<let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
        lhs_terms: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [Self; ADD_N],
        linear_flags: [bool; ADD_N],
    ) {
        let params = Params::get_params();
        evaluate_quadratic_expression::<_, MOD_BITS, _, _, _, _>(
            params,
            map(
                lhs_terms,
                |bns| map(bns, |bn| Self::get_limbs_slice(bn).as_array()),
            ),
            lhs_flags,
            map(
                rhs_terms,
                |bns| map(bns, |bn| Self::get_limbs_slice(bn).as_array()),
            ),
            rhs_flags,
            map(linear_terms, |bn| Self::get_limbs_slice(bn).as_array()),
            linear_flags,
        )
    }

    fn validate_in_field(self: Self) {
        let params = Params::get_params();
        validate_in_field::<_, MOD_BITS>(params, self.limbs);
    }

    fn validate_in_range(self) {
        validate_in_range::<_, MOD_BITS>(self.limbs);
    }

    fn assert_is_not_equal(self, other: Self) {
        let params = Params::get_params();
        assert_is_not_equal(params, self.limbs, other.limbs);
    }

    fn neg(self) -> Self {
        let params = Params::get_params();
        Self { limbs: neg::<_, MOD_BITS>(params, self.limbs) }
    }

    fn udiv_mod(self, divisor: Self) -> (Self, Self) {
        let params = Params::get_params();
        let (q, r) = udiv_mod::<_, MOD_BITS>(params, self.limbs, divisor.limbs);
        (Self { limbs: q }, Self { limbs: r })
    }

    fn udiv(self, divisor: Self) -> Self {
        let params = Params::get_params();
        Self { limbs: udiv::<_, MOD_BITS>(params, self.limbs, divisor.limbs) }
    }

    fn umod(self, divisor: Self) -> Self {
        let params = Params::get_params();
        Self { limbs: umod::<_, MOD_BITS>(params, self.limbs, divisor.limbs) }
    }

    fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self {
        Self { limbs: conditional_select(lhs.limbs, rhs.limbs, predicate) }
    }
}

// impl<let N: u32, Params> BigNumTrait<N, Params> for BigNum<N, Params> where Params: BigNumParamsGetter<N> {}

impl<let N: u32, let MOD_BITS: u32, Params> std::ops::Add for BigNum<N, MOD_BITS, Params>
where
    Params: BigNumParamsGetter<N, MOD_BITS>,
{
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    fn add(self, other: Self) -> Self {
        let params = Params::get_params();
        Self { limbs: add::<_, MOD_BITS>(params, self.limbs, other.limbs) }
    }
}

impl<let N: u32, let MOD_BITS: u32, Params> std::ops::Sub for BigNum<N, MOD_BITS, Params>
where
    Params: BigNumParamsGetter<N, MOD_BITS>,
{
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    fn sub(self, other: Self) -> Self {
        let params = Params::get_params();
        Self { limbs: sub::<_, MOD_BITS>(params, self.limbs, other.limbs) }
    }
}

impl<let N: u32, let MOD_BITS: u32, Params> std::ops::Mul for BigNum<N, MOD_BITS, Params>
where
    Params: BigNumParamsGetter<N, MOD_BITS>,
{
    // Note: this method is expensive! Try to craft quadratic relations and directly evaluate them
    //       via evaluate_quadratic_expression
    // e.g. performing a sum of multiple multiplications and additions via `evaluate_quadratic_expression`
    //      will create much fewer constraints than calling `mul` and `add` directly
    fn mul(self, other: Self) -> Self {
        let params = Params::get_params();
        Self { limbs: mul::<_, MOD_BITS>(params, self.limbs, other.limbs) }
    }
}

impl<let N: u32, let MOD_BITS: u32, Params> std::ops::Div for BigNum<N, MOD_BITS, Params>
where
    Params: BigNumParamsGetter<N, MOD_BITS>,
{
    // Note: this method is expensive! Witness computation is extremely expensive as it requires modular exponentiation
    fn div(self, other: Self) -> Self {
        let params = Params::get_params();
        Self { limbs: div::<_, MOD_BITS>(params, self.limbs, other.limbs) }
    }
}

impl<let N: u32, let MOD_BITS: u32, Params> std::cmp::Eq for BigNum<N, MOD_BITS, Params>
where
    Params: BigNumParamsGetter<N, MOD_BITS>,
{
    fn eq(self, other: Self) -> bool {
        let params = Params::get_params();
        eq::<_, MOD_BITS>(params, self.limbs, other.limbs)
    }
}

