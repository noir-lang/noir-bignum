use crate::utils::map::map;
use std::cmp::Ordering;

use crate::params::{BigNumParams, BigNumParamsGetter};

use crate::fields::bn254Fq::BN254_Fq;

use crate::fns::{
    constrained_ops::{
        add, assert_is_not_equal, cmp, conditional_select, derive_from_seed, div, eq, from_field,
        is_zero, limbs_to_field, mul, neg, sub, udiv, udiv_mod, umod, validate_in_field,
        validate_in_range,
    },
    expressions::{__compute_quadratic_expression, evaluate_quadratic_expression},
    serialization::{from_be_bytes, to_le_bytes},
    unconstrained_ops::{
        __add, __batch_invert, __batch_invert_slice, __derive_from_seed, __div, __eq, __invmod,
        __is_zero, __mul, __neg, __pow, __sub, __tonelli_shanks_sqrt, __udiv_mod,
    },
};
use std::ops::{Add, Div, Mul, Neg, Sub};

pub struct BigNum<let N: u32, let MOD_BITS: u32, Params> {
    pub limbs: [u128; N],
}
// We aim to avoid needing to add a generic parameter to this trait, for this reason we do not allow
// accessing the limbs of the bignum except through slices.
pub trait BigNumTrait: Neg + Add + Sub + Mul + Div + Eq {
    // TODO: this crashes the compiler? v0.32
    // fn default() -> Self { std::default::Default::default  () }
    fn new() -> Self;
    fn zero() -> Self;
    fn one() -> Self;
    fn derive_from_seed<let SeedBytes: u32>(seed: [u8; SeedBytes]) -> Self;
    unconstrained fn __derive_from_seed<let SeedBytes: u32>(seed: [u8; SeedBytes]) -> Self;
    fn from_slice(limbs: [u128]) -> Self;
    fn from_be_bytes<let NBytes: u32>(x: [u8; NBytes]) -> Self;
    fn to_le_bytes<let NBytes: u32>(self) -> [u8; NBytes];

    fn modulus() -> Self;
    fn modulus_bits(self) -> u32;
    fn num_limbs(self) -> u32;
    fn get_limbs_slice(self) -> [u128];
    fn get_limb(self, idx: u32) -> u128;

    unconstrained fn __eq(self, other: Self) -> bool;
    unconstrained fn __is_zero(self) -> bool;

    unconstrained fn __neg(self) -> Self;
    unconstrained fn __add(self, other: Self) -> Self;
    unconstrained fn __sub(self, other: Self) -> Self;
    unconstrained fn __mul(self, other: Self) -> Self;
    unconstrained fn __div(self, other: Self) -> Self;
    unconstrained fn __udiv_mod(self, divisor: Self) -> (Self, Self);
    unconstrained fn __invmod(self) -> Self;
    unconstrained fn __pow(self, exponent: Self) -> Self;

    unconstrained fn __batch_invert<let M: u32>(to_invert: [Self; M]) -> [Self; M];
    unconstrained fn __batch_invert_slice<let M: u32>(to_invert: [Self]) -> [Self];

    unconstrained fn __tonelli_shanks_sqrt(self) -> std::option::Option<Self>;

    unconstrained fn __compute_quadratic_expression<let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
        lhs: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        add: [Self; ADD_N],
        add_flags: [bool; ADD_N],
    ) -> (Self, Self);

    fn evaluate_quadratic_expression<let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
        lhs: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        add: [Self; ADD_N],
        add_flags: [bool; ADD_N],
    );

    fn assert_is_not_equal(self, other: Self);
    fn validate_in_range(self);
    fn validate_in_field(self);

    fn udiv_mod(self, divisor: Self) -> (Self, Self);
    fn udiv(self, divisor: Self) -> Self;
    fn umod(self, divisor: Self) -> Self;

    fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self;
    fn is_zero(self) -> bool;
}

pub(crate) trait LimbedObject<let N: u32, let MOD_BITS: u32> {
    fn from_limbs(limbs: [u128; N]) -> Self;
    fn get_limbs(self) -> [u128; N];
    fn set_limb(self: &mut Self, idx: u32, value: u128);
    fn params() -> BigNumParams<N, MOD_BITS>;
}

impl<T, let N: u32, let MOD_BITS: u32> BigNumTrait for T
where
    T: Neg + Add + Sub + Mul + Div + Eq + LimbedObject<N, MOD_BITS>,
{
    fn new() -> Self {
        Self::zero()
    }

    fn zero() -> Self {
        T::from_limbs([0; N])
    }

    fn one() -> Self {
        let mut limbs = [0; N];
        limbs[0] = 1;
        T::from_limbs(limbs)
    }

    fn derive_from_seed<let SeedBytes: u32>(seed: [u8; SeedBytes]) -> Self {
        let params = T::params();
        T::from_limbs(derive_from_seed::<_, MOD_BITS, _>(params, seed))
    }

    unconstrained fn __derive_from_seed<let SeedBytes: u32>(seed: [u8; SeedBytes]) -> Self {
        let params = T::params();
        T::from_limbs(__derive_from_seed::<_, MOD_BITS, _>(params, seed))
    }

    fn from_slice(limbs: [u128]) -> Self {
        T::from_limbs(limbs.as_array())
    }

    fn from_be_bytes<let NBytes: u32>(x: [u8; NBytes]) -> Self {
        T::from_limbs(from_be_bytes::<_, MOD_BITS, _>(x))
    }

    fn to_le_bytes<let NBytes: u32>(self: Self) -> [u8; NBytes] {
        to_le_bytes::<_, MOD_BITS, _>(self.get_limbs())
    }

    fn modulus() -> Self {
        T::from_limbs(T::params().modulus)
    }

    fn modulus_bits(_: Self) -> u32 {
        MOD_BITS
    }

    fn num_limbs(_: Self) -> u32 {
        N
    }

    fn get_limbs_slice(self: T) -> [u128] {
        self.get_limbs()
    }

    fn get_limb(self: T, idx: u32) -> u128 {
        self.get_limbs()[idx]
    }

    unconstrained fn __eq(self, other: Self) -> bool {
        __eq(self.get_limbs(), other.get_limbs())
    }

    unconstrained fn __is_zero(self) -> bool {
        __is_zero(self.get_limbs())
    }

    unconstrained fn __neg(self) -> Self {
        let params = T::params();
        T::from_limbs(__neg(params, self.get_limbs()))
    }

    unconstrained fn __add(self, other: Self) -> Self {
        let params = T::params();
        T::from_limbs(__add(params, self.get_limbs(), other.get_limbs()))
    }

    unconstrained fn __sub(self, other: Self) -> Self {
        let params = T::params();
        T::from_limbs(__sub(params, self.get_limbs(), other.get_limbs()))
    }

    unconstrained fn __mul(self, other: Self) -> Self {
        let params = T::params();
        T::from_limbs(
            __mul::<_, MOD_BITS>(params, self.get_limbs(), other.get_limbs()),
        )
    }

    unconstrained fn __div(self, divisor: Self) -> Self {
        let params = T::params();
        T::from_limbs(
            __div::<_, MOD_BITS>(params, self.get_limbs(), divisor.get_limbs()),
        )
    }

    unconstrained fn __udiv_mod(self, divisor: Self) -> (Self, Self) {
        let (q, r) = __udiv_mod(self.get_limbs(), divisor.get_limbs());
        (T::from_limbs(q), T::from_limbs(r))
    }

    unconstrained fn __invmod(self) -> Self {
        let params = T::params();
        assert(params.has_multiplicative_inverse);
        T::from_limbs(__invmod::<_, MOD_BITS>(params, self.get_limbs()))
    }

    unconstrained fn __pow(self, exponent: Self) -> Self {
        let params = T::params();
        T::from_limbs(
            __pow::<_, MOD_BITS>(params, self.get_limbs(), exponent.get_limbs()),
        )
    }

    unconstrained fn __batch_invert<let M: u32>(x: [Self; M]) -> [Self; M] {
        let params = T::params();
        assert(params.has_multiplicative_inverse);
        __batch_invert::<_, MOD_BITS, _>(params, x.map(|bn: Self| bn.get_limbs())).map(|limbs| {
            T::from_limbs(limbs)
        })
    }

    unconstrained fn __batch_invert_slice<let M: u32>(x: [Self]) -> [Self] {
        let params = T::params();
        assert(params.has_multiplicative_inverse);
        __batch_invert_slice::<_, MOD_BITS>(params, x.map(|bn: Self| bn.get_limbs())).map(|limbs| {
            T::from_limbs(limbs)
        })
    }

    unconstrained fn __tonelli_shanks_sqrt(self) -> std::option::Option<Self> {
        let params = T::params();
        let maybe_limbs = __tonelli_shanks_sqrt(params, self.get_limbs());
        maybe_limbs.map(|limbs| T::from_limbs(limbs))
    }

    unconstrained fn __compute_quadratic_expression<let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
        lhs_terms: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [Self; ADD_N],
        linear_flags: [bool; ADD_N],
    ) -> (Self, Self) {
        let params = T::params();
        let (q_limbs, r_limbs) = __compute_quadratic_expression::<_, MOD_BITS, _, _, _, _>(
            params,
            map(lhs_terms, |bns| map(bns, |bn: Self| bn.get_limbs())),
            lhs_flags,
            map(rhs_terms, |bns| map(bns, |bn: Self| bn.get_limbs())),
            rhs_flags,
            map(linear_terms, |bn: Self| bn.get_limbs()),
            linear_flags,
        );
        (T::from_limbs(q_limbs), T::from_limbs(r_limbs))
    }

    fn evaluate_quadratic_expression<let LHS_N: u32, let RHS_N: u32, let NUM_PRODUCTS: u32, let ADD_N: u32>(
        lhs_terms: [[Self; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[Self; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [Self; ADD_N],
        linear_flags: [bool; ADD_N],
    ) {
        let params = T::params();
        evaluate_quadratic_expression::<_, MOD_BITS, _, _, _, _>(
            params,
            map(lhs_terms, |bns| map(bns, |bn: Self| bn.get_limbs())),
            lhs_flags,
            map(rhs_terms, |bns| map(bns, |bn: Self| bn.get_limbs())),
            rhs_flags,
            map(linear_terms, |bn: Self| bn.get_limbs()),
            linear_flags,
        )
    }

    fn validate_in_field(self: Self) {
        let params = T::params();
        validate_in_field::<_, MOD_BITS>(params, self.get_limbs());
    }

    fn validate_in_range(self) {
        validate_in_range::<_, _, MOD_BITS>(self.get_limbs());
    }

    fn assert_is_not_equal(self, other: Self) {
        let params = T::params();
        assert_is_not_equal(params, self.get_limbs(), other.get_limbs());
    }

    fn udiv_mod(self, divisor: Self) -> (Self, Self) {
        let params = T::params();
        let (q, r) = udiv_mod::<_, MOD_BITS>(params, self.get_limbs(), divisor.get_limbs());
        (T::from_limbs(q), T::from_limbs(r))
    }

    fn udiv(self, divisor: Self) -> Self {
        let params = T::params();
        T::from_limbs(
            udiv::<_, MOD_BITS>(params, self.get_limbs(), divisor.get_limbs()),
        )
    }

    fn umod(self, divisor: Self) -> Self {
        let params = T::params();
        T::from_limbs(
            umod::<_, MOD_BITS>(params, self.get_limbs(), divisor.get_limbs()),
        )
    }

    fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self {
        T::from_limbs(
            conditional_select(lhs.get_limbs(), rhs.get_limbs(), predicate),
        )
    }

    fn is_zero(self) -> bool {
        is_zero::<N, MOD_BITS>(self.get_limbs())
    }
}

// we need macros that implement the LimbedObject, Default, From, Neg, Add, Sub, Mul, Div, Eq, Ord traits for BigNum
pub(crate) comptime fn make_bignum_impls(
    strukt: TypeDefinition,
    N: u32,
    MOD_BITS: u32,
    params: Quoted,
) -> Quoted {
    // let BigNumTrait = quote { crate::bignum::BigNumTrait };
    let LimbedObject = quote { crate::bignum::LimbedObject };
    let From = quote { std::convert::From };
    let Neg = quote { std::ops::Neg };
    let Add = quote { std::ops::Add };
    let Sub = quote { std::ops::Sub };
    let Mul = quote { std::ops::Mul };
    let Div = quote { std::ops::Div };
    let Eq = quote { std::cmp::Eq };
    let Ord = quote { std::cmp::Ord };
    let constrained_ops = quote { crate::fns::constrained_ops };
    let Ordering = quote { std::cmp::Ordering };
    let typ = strukt.as_type();

    quote {
        // implement LimbedObject for BigNum 
        impl $LimbedObject<$N, $MOD_BITS> for $typ {
            fn from_limbs(limbs: [u128; $N]) -> Self {
                $typ { limbs }
            }

            fn get_limbs(self: Self) -> [u128; $N] {
                self.limbs
            }

            fn set_limb(self: &mut Self, idx: u32, value: u128) {
                self.limbs[idx] = value;
            }

            fn params() -> crate::params::BigNumParams<$N, $MOD_BITS> {
                $params
            }
        }

        // implement Default for BigNum
        impl Default for $typ {
            fn default() -> Self {
                $LimbedObject::from_limbs([0; $N])
            }
        }

        // implement From for BigNum
        impl $From<[u128; $N]> for $typ {
            fn from(limbs: [u128; $N]) -> Self {
                $typ { limbs }
            }
        }

        impl $From<Field> for $typ {
            fn from(input: Field) -> Self {
                $typ { limbs: $constrained_ops::from_field::<$N, $MOD_BITS>(input) }
            }
        }

        impl $Neg for $typ {
            fn neg(self) -> Self {
                $typ { limbs: $constrained_ops::neg::<$N, $MOD_BITS>($params, self.limbs) }
            }
        }

        impl $Add for $typ {
            fn add(self, other: Self) -> Self {
                $typ { limbs: $constrained_ops::add::<$N, $MOD_BITS>($params, self.limbs, other.limbs) }
            }
        }

        impl $Sub for $typ {
            fn sub(self, other: Self) -> Self {
                $typ { limbs: $constrained_ops::sub::<$N, $MOD_BITS>($params, self.limbs, other.limbs) }
            }
        }

        impl $Mul for $typ {
            fn mul(self, other: Self) -> Self {
                $typ { limbs: $constrained_ops::mul::<$N, $MOD_BITS>($params, self.limbs, other.limbs) }
            }
        }

        impl $Div for $typ {
            fn div(self, other: Self) -> Self {
                $typ { limbs: $constrained_ops::div::<$N, $MOD_BITS>($params, self.limbs, other.limbs) }
            }
        }

        impl $Eq for $typ {
            fn eq(self, other: Self) -> bool {
                self.limbs == other.limbs
            }
        }

        impl $Ord for $typ {
            fn cmp(self, other: Self) -> $Ordering {
                $constrained_ops::cmp::<$N, $MOD_BITS>(self.limbs, other.limbs)
            }
        }

        

    }
}

// pub fn to_field<let N: u32, let MOD_BITS: u32, Params>(bn: BigNum<N, MOD_BITS, Params>) -> Field {
//     to_field::<N, MOD_BITS, Params>(bn.get_limbs())
// }
