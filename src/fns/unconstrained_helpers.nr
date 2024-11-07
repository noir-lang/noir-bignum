use crate::utils::split_bits;
use crate::utils::u60_representation::U60Repr;

use crate::fns::unconstrained_ops::{__add, __eq, __mul, __neg, __one, __pow};
use crate::params::BigNumParams as P;

global TWO_POW_60: u64 = 0x1000000000000000;

/**
 * In this file:
 *
 * __validate_in_field_compute_borrow_flags
 * __validate_gt_remainder
 * __neg_with_flags
 * __add_with_flags
 * __sub_with_flags
 * __barrett_reduction
 * __tonelli_shanks_sqrt
 */

pub(crate) unconstrained fn __validate_in_field_compute_borrow_flags<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    val: [Field; N],
) -> [bool; N] {
    let mut flags: [bool; N] = [false; N];
    let modulus: [Field; N] = params.modulus;
    flags[0] = modulus[0].lt(val[0]);
    for i in 1..N - 1 {
        flags[i] = modulus[i].lt(val[i] + flags[i - 1] as Field);
    }
    flags
}

pub(crate) unconstrained fn __validate_gt_remainder<let N: u32>(
    lhs: [Field; N],
    rhs: [Field; N],
) -> ([Field; N], [bool; N], [bool; N]) {
    let a_u60: U60Repr<N, 2> = U60Repr::from(lhs);
    let mut b_u60: U60Repr<N, 2> = U60Repr::from(rhs);

    let underflow = b_u60.gte(a_u60);
    b_u60 += U60Repr::one();
    assert(underflow == false, "BigNum::validate_gt check fails");
    let mut result_u60: U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };

    let mut carry_in: u64 = 0;
    let mut borrow_in: u64 = 0;
    let mut borrow_flags: [bool; N] = [false; N];
    let mut carry_flags: [bool; N] = [false; N];
    for i in 0..2 * N {
        let mut add_term: u64 = a_u60.limbs[i] + carry_in;
        let mut carry = (add_term >= TWO_POW_60) as u64;
        add_term -= carry * TWO_POW_60;
        carry_in = carry;

        let sub_term = b_u60.limbs[i] + borrow_in;
        let mut borrow = (sub_term > add_term) as u64;
        result_u60.limbs[i] = borrow * TWO_POW_60 + add_term - sub_term;

        borrow_in = borrow;

        if ((i & 1) == 1) {
            if (carry & borrow == 1) {
                carry = 0;
                borrow = 0;
            }
            carry_flags[i / 2] = carry as bool;
            borrow_flags[i / 2] = borrow as bool;
        }
    }
    let result = U60Repr::into(result_u60);
    (result, carry_flags, borrow_flags)
}

pub(crate) unconstrained fn __neg_with_flags<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    val: [Field; N],
) -> ([Field; N], [bool; N]) {
    let x_u60: U60Repr<N, 2> = U60Repr::from(val);
    let mut result_u60: U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };

    let mut borrow_in: u64 = 0;

    let mut borrow_flags: [bool; N] = [false; N];
    for i in 0..2 * N {
        let sub_term = x_u60.limbs[i] + borrow_in;
        let borrow = (sub_term > params.modulus_u60.limbs[i]) as u64;
        result_u60.limbs[i] = borrow * TWO_POW_60 + params.modulus_u60.limbs[i] - sub_term;

        borrow_in = borrow;
        if ((i & 1) == 1) {
            borrow_flags[i / 2] = borrow as bool;
        }
    }
    let result = U60Repr::into(result_u60);
    (result, borrow_flags)
}

pub(crate) unconstrained fn __add_with_flags<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [Field; N],
    rhs: [Field; N],
) -> ([Field; N], [bool; N], [bool; N], bool) {
    let a_u60: U60Repr<N, 2> = U60Repr::from(lhs);
    let b_u60: U60Repr<N, 2> = U60Repr::from(rhs);
    let add_u60 = a_u60 + b_u60;

    let overflow = add_u60.gte(params.modulus_u60);

    let mut subtrahend_u60: U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };
    let mut result_u60: U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };

    if overflow {
        subtrahend_u60 = params.modulus_u60;
    }

    let mut carry_in: u64 = 0;
    let mut borrow_in: u64 = 0;
    let mut borrow_flags: [bool; N] = [false; N];
    let mut carry_flags: [bool; N] = [false; N];
    for i in 0..2 * N {
        let mut add_term: u64 = a_u60.limbs[i] + b_u60.limbs[i] + carry_in;
        let mut carry = (add_term >= TWO_POW_60) as u64;
        add_term -= carry * TWO_POW_60;
        carry_in = carry;

        let sub_term = subtrahend_u60.limbs[i] + borrow_in;
        let mut borrow = (sub_term > add_term) as u64;
        result_u60.limbs[i] = borrow * TWO_POW_60 + add_term - sub_term;
        borrow_in = borrow;

        if ((i & 1) == 1) {
            let idx = (i - 1) / 2;
            if (carry & borrow == 1) {
                carry = 0;
                borrow = 0;
            }
            carry_flags[idx] = carry as bool;
            borrow_flags[idx] = borrow as bool;
        }
    }
    let result = U60Repr::into(result_u60);

    (result, carry_flags, borrow_flags, overflow)
}

pub(crate) unconstrained fn __sub_with_flags<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    lhs: [Field; N],
    rhs: [Field; N],
) -> ([Field; N], [bool; N], [bool; N], bool) {
    let a_u60: U60Repr<N, 2> = U60Repr::from(lhs);
    let b_u60: U60Repr<N, 2> = U60Repr::from(rhs);

    let underflow = b_u60.gte(a_u60 + U60Repr::one());

    let addend_u60: U60Repr<N, 2> = if underflow {
        params.modulus_u60
    } else {
        U60Repr { limbs: [0; 2 * N] }
    };
    let mut result_u60: U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };

    let mut carry_in: u64 = 0;
    let mut borrow_in: u64 = 0;
    let mut borrow_flags: [bool; N] = [false; N];
    let mut carry_flags: [bool; N] = [false; N];
    for i in 0..2 * N {
        let mut add_term: u64 = a_u60.limbs[i] + addend_u60.limbs[i] + carry_in;
        let mut carry = (add_term >= TWO_POW_60) as u64;
        add_term -= carry * TWO_POW_60;
        carry_in = carry;

        let sub_term = b_u60.limbs[i] + borrow_in;
        let mut borrow = (sub_term > add_term) as u64;
        result_u60.limbs[i] = borrow * TWO_POW_60 + add_term - sub_term;
        borrow_in = borrow;

        if ((i & 1) == 1) {
            if (carry & borrow == 1) {
                carry = 0;
                borrow = 0;
            }
            carry_flags[i / 2] = carry as bool;
            borrow_flags[i / 2] = borrow as bool;
        }
    }
    let result = U60Repr::into(result_u60);
    (result, carry_flags, borrow_flags, underflow)
}

/**
 * @brief BARRETT_REDUCTION_OVERFLOW_BITS defines how large an input to barrett reduction can be
 * @details maximum value = modulus^2 <<BARRETT_REDUCTION_OVERFLOW_BITS
 *          see __barrett_reduction for more details
 **/
comptime global BARRETT_REDUCTION_OVERFLOW_BITS: u32 = 4;

pub(crate) unconstrained fn __barrett_reduction<let N: u32>(
    x: [Field; 2 * N],
    redc_param: [Field; N],
    k: u32,
    modulus: [Field; N],
    modulus_u60: U60Repr<N, 4>,
) -> ([Field; N], [Field; N]) {
    // for each i in 0..(N + N), adds x[i] * redc_param[j] to mulout[i + j] for each j in 0..N
    let mut mulout: [Field; 3 * N] = [0; 3 * N];
    for i in 0..(N + N) {
        for j in 0..N {
            mulout[i + j] += x[i] * redc_param[j];
        }
    }

    mulout = split_bits::__normalize_limbs(mulout, 3 * N - 1);
    let mulout_u60: U60Repr<N, 6> = U60Repr::new(mulout);

    // When we apply the barrett reduction, the maximum value of the output will be
    // <= p * (1 + x/2^{2k})
    // where p = modulus,
    //       x = reduction input
    // if x > p * p, we need k to be larger than modulus_bits()
    // we hardcode k = 4, which means that the maximum value of x is approx. 16 * p * p
    // this should be larger than most values put into `evaluate_quadratic_expression`
    // TODO: try and detect cases where x might be too large at comptime
    // N.B. BARRETT_REDUCTION_OVERFLOW_BITS affects how `redc_param` is generated.
    // `redc_param` = 2^{modulus_bits() * 2 + BARRETT_REDUCTION_OVERFLOW_BITS} / modulus
    // NOTE: very niche edge case error that we need to be aware of:
    //       N must be large enough to cover the modulus *plus* BARRETT_REDUCTION_OVERFLOW_BITS
    //       i.e. a 359-bit prime needs (I think) 4 limbs to represent or we may overflow when calling __barrett_reduction
    let mut quotient_u60 = mulout_u60.shr((k + k + BARRETT_REDUCTION_OVERFLOW_BITS));

    // N.B. we assume that the shifted quotient cannot exceed 2 times original bit size.
    //      (partial_quotient should be just slightly larger than the modulus, we could probably represent with a size N+1 array)
    let partial_quotient_full: [Field; 3 * N] = quotient_u60.into_field_array();
    let mut partial_quotient: [Field; 2 * N] = [0; 2 * N];
    for i in 0..2 * N {
        partial_quotient[i] = partial_quotient_full[i];
    }
    // quotient_mul_modulus can never exceed input value `x` so can fit into size-2 array
    let mut quotient_mul_modulus: [Field; 2 * N] = [0; 2 * N];
    let mut quotient_mul_modulus_normalized: [Field; 2 * N] = [0; 2 * N];
    for j in 0..N {
        for i in 0..(N + N - j) {
            quotient_mul_modulus[i + j] += partial_quotient[i] * modulus[j];
        }
    }

    for i in 0..(N + N) {
        let (lo, hi) = split_bits::split_120_bits(quotient_mul_modulus[i]);
        quotient_mul_modulus_normalized[i] = lo;
        // TODO: what is faster, leaving this if statement in or out?
        // (array is size-1 too large so we can tolerate adding 0 into max element)
        if (i + 1 < N + N) {
            quotient_mul_modulus[i + 1] += hi;
        }
    }
    let quotient_mul_modulus_u60: U60Repr<N, 4> = U60Repr::new(quotient_mul_modulus_normalized);

    // convert the input into U60Repr
    let x_u60: U60Repr<N, 4> = U60Repr::new(x);
    let mut remainder_u60 = x_u60 - quotient_mul_modulus_u60;
    // barrett reduction is quircky so might need to remove a few modulus_u60 from the remainder
    if (remainder_u60.gte(modulus_u60)) {
        remainder_u60 = remainder_u60 - modulus_u60;
        quotient_u60.increment();
    } else {}
    if (remainder_u60.gte(modulus_u60)) {
        remainder_u60 = remainder_u60 - modulus_u60;
        quotient_u60.increment();
    }
    if (remainder_u60.gte(modulus_u60)) {
        remainder_u60 = remainder_u60 - modulus_u60;
        quotient_u60.increment();
    }

    let q: [Field; N] = U60Repr::into(quotient_u60);
    let r: [Field; N] = U60Repr::into(remainder_u60);

    (q, r)
}

/**
* @brief compute the log of the size of the primitive root
* @details find the maximum value k where x^k = 1, where x = primitive root
*          This is needed for our Tonelli-Shanks sqrt algorithm
**/
pub(crate) unconstrained fn __primitive_root_log_size<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
) -> u32 {
    let mut target: U60Repr<N, 2> = params.modulus_u60 - U60Repr::one();
    let mut result: u32 = 0;
    for _ in 0..MOD_BITS {
        let lsb_is_one = (target.limbs[0] & 1) == 1;
        if (!lsb_is_one) {
            result += 1;
            target.shr1();
        } else {
            break;
        }
    }
    result
}

/**
* @brief inner loop fn for `find_multiplive_generator`
* @details recursive function to get around the lack of a `while` keyword
**/
unconstrained fn __recursively_find_multiplicative_generator<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    target: [Field; N],
    p_minus_one_over_two: [Field; N],
) -> (bool, [Field; N]) {
    let exped = __pow(params, target, p_minus_one_over_two);
    let one: [Field; N] = __one();
    let neg_one = __neg(params, one);
    let found = __eq(exped, neg_one);
    let mut result: (bool, [Field; N]) = (found, target);
    if (!found) {
        let _target = unsafe { __add(params, target, one) };
        result = __recursively_find_multiplicative_generator::<_, MOD_BITS>(
            params,
            _target,
            p_minus_one_over_two,
        );
    }
    result
}

/**
* @brief find multiplicative generator `g` where `g` is the smallest value that is not a quadratic residue
*        i.e. smallest g where g^2 = -1
* @note WARNING if multiplicative generator does not exist, this function will enter an infinite loop!
**/
pub(crate) unconstrained fn __multiplicative_generator<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
) -> [Field; N] {
    let mut target: [Field; N] = __one();
    let p_minus_one_over_two: U60Repr<N, 2> = (params.modulus_u60 - U60Repr::one()).shr(1);
    let p_minus_one_over_two: [Field; N] = U60Repr::into(p_minus_one_over_two);
    let (_, target) = __recursively_find_multiplicative_generator::<_, MOD_BITS>(
        params,
        target,
        p_minus_one_over_two,
    );
    target
}

pub(crate) unconstrained fn __tonelli_shanks_sqrt_inner_loop_check<let N: u32, let MOD_BITS: u32>(
    params: P<N, MOD_BITS>,
    t2m: [Field; N],
    i: u32,
) -> u32 {
    let one: [Field; N] = __one();
    let is_one = __eq(t2m, one);
    let mut result = i;
    if (!is_one) {
        let t2m = __mul::<_, MOD_BITS>(params, t2m, t2m);
        let i = i + 1;
        result = __tonelli_shanks_sqrt_inner_loop_check::<_, MOD_BITS>(params, t2m, i);
    }
    result
}
