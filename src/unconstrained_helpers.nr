use crate::utils::u60_representation::U60Repr;
use crate::utils::split_bits;

use crate::params::BigNumParams as P;

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

unconstrained pub(crate) fn __validate_in_field_compute_borrow_flags<let N: u32>(params: P<N>, val: [Field; N]) -> [bool; N] {
    let mut flags: [bool; N] = [false; N];
    let modulus: [Field; N] = params.modulus;
    flags[0] = modulus[0].lt(val[0]);
    for i in 1..N - 1 {
        flags[i] = modulus[i].lt(val[i] + flags[i - 1] as Field);
    }
    flags
}

unconstrained pub(crate) fn __validate_gt_remainder<let N: u32>(lhs: [Field; N], rhs: [Field; N]) -> ([Field; N], [bool; N], [bool; N]) {
    let a_u60 : U60Repr<N, 2> = U60Repr::from(lhs);
    let mut b_u60 : U60Repr<N, 2> = U60Repr::from(rhs);

    let underflow = b_u60.gte(a_u60);
    b_u60 += U60Repr::one();
    assert(underflow == false, "BigNum::validate_gt check fails");
    let mut addend_u60 : U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };
    let mut result_u60 : U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };

    let mut carry: u64 = 0;
    let mut carry_in: u64 = 0;
    let mut borrow: u64 = 0;
    let mut borrow_in: u64 = 0;
    let mut borrow_flags: [bool; N] = [false; N];
    let mut carry_flags: [bool; N] = [false; N];
    for i in 0..2 * N {
        let mut add_term: u64 = a_u60.limbs[i] + addend_u60.limbs[i] + carry_in;
        carry = (add_term >= 0x1000000000000000) as u64;
        add_term -= (carry as u64 * 0x1000000000000000);
        result_u60.limbs[i] = add_term;
        carry_in = carry as u64;
        borrow = ((b_u60.limbs[i] + borrow_in) > result_u60.limbs[i]) as u64;
        let sub = (borrow << 60) + result_u60.limbs[i] - b_u60.limbs[i] - borrow_in;
        result_u60.limbs[i] = sub;
        borrow_in = borrow;

        if ((i & 1) == 1) {
            if (carry & borrow == 1) {
                carry = 0;
                borrow = 0;
            }
            carry_flags[i/2] = carry as bool;
            borrow_flags[i/2] = borrow as bool;
        }
    }

    let result = U60Repr::into(result_u60);
    (result, carry_flags, borrow_flags)
}

unconstrained pub(crate) fn __neg_with_flags<let N: u32>(params: P<N>, val: [Field; N]) -> ([Field; N], [bool; N]) {
    let x_u60 : U60Repr<N, 2> = U60Repr::from(val);
    let mut result_u60 : U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };

    let mut borrow: u64 = 0;
    let mut borrow_in: u64 = 0;

    let mut borrow_flags: [bool; N] = [false; N];
    for i in 0..2 * N {
        borrow = ((x_u60.limbs[i] + borrow_in) > params.modulus_u60.limbs[i]) as u64;
        let sub = (borrow << 60) + params.modulus_u60.limbs[i] - x_u60.limbs[i] - borrow_in;
        result_u60.limbs[i] = sub;
        borrow_in = borrow;
        if ((i & 1) == 1) {
            borrow_flags[i / 2] = borrow as bool;
        }
    }
    let result = U60Repr::into(result_u60);
    (result, borrow_flags)
}

unconstrained pub(crate) fn __add_with_flags<let N: u32>(params: P<N>, lhs: [Field; N], rhs: [Field; N]) -> ([Field; N], [bool; N], [bool; N], bool) {
    let a_u60 : U60Repr<N, 2> = U60Repr::from(lhs);
    let b_u60 : U60Repr<N, 2> = U60Repr::from(rhs);
    let add_u60 = a_u60 + b_u60;

    let overflow = add_u60.gte(params.modulus_u60);

    let mut subtrahend_u60 : U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };
    let mut result_u60 : U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };

    if overflow {
        subtrahend_u60 = params.modulus_u60;
    }

    let mut carry: u64 = 0;
    let mut carry_in: u64 = 0;
    let mut borrow: u64 = 0;
    let mut borrow_in: u64 = 0;
    let mut borrow_flags: [bool; N] = [false; N];
    let mut carry_flags: [bool; N] = [false; N];
    for i in 0..2 * N {
        let mut add_term: u64 = a_u60.limbs[i] + b_u60.limbs[i] + carry_in;
        carry = (add_term >= 0x1000000000000000) as u64;
        add_term -= (carry as u64 * 0x1000000000000000);
        result_u60.limbs[i] = add_term;
        carry_in = carry as u64;
        borrow = ((subtrahend_u60.limbs[i] + borrow_in) > result_u60.limbs[i]) as u64;
        let sub = (borrow << 60) + result_u60.limbs[i] - subtrahend_u60.limbs[i] - borrow_in;
        result_u60.limbs[i] = sub;
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

unconstrained pub(crate) fn __sub_with_flags<let N: u32>(params: P<N>, lhs: [Field; N], rhs: [Field; N]) -> ([Field; N], [bool; N], [bool; N], bool) {
    let a_u60 : U60Repr<N, 2> = U60Repr::from(lhs);
    let b_u60 : U60Repr<N, 2> = U60Repr::from(rhs);

    let underflow = b_u60.gte(a_u60 + U60Repr::one());

    let mut addend_u60 : U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };
    let mut result_u60 : U60Repr<N, 2> = U60Repr { limbs: [0; 2 * N] };

    if underflow {
        addend_u60 = params.modulus_u60;
    }

    let mut carry: u64 = 0;
    let mut carry_in: u64 = 0;
    let mut borrow: u64 = 0;
    let mut borrow_in: u64 = 0;
    let mut borrow_flags: [bool; N] = [false; N];
    let mut carry_flags: [bool; N] = [false; N];
    for i in 0..2 * N {
        let mut add_term: u64 = a_u60.limbs[i] + addend_u60.limbs[i] + carry_in;
        carry = (add_term >= 0x1000000000000000) as u64;
        add_term -= (carry as u64 * 0x1000000000000000);
        result_u60.limbs[i] = add_term;
        carry_in = carry as u64;
        borrow = ((b_u60.limbs[i] + borrow_in) > result_u60.limbs[i]) as u64;
        let sub = (borrow << 60) + result_u60.limbs[i] - b_u60.limbs[i] - borrow_in;
        result_u60.limbs[i] = sub;
        borrow_in = borrow;

        if ((i & 1) == 1) {
            if (carry & borrow == 1) {
                carry = 0;
                borrow = 0;
            }
            carry_flags[i/2] = carry as bool;
            borrow_flags[i/2] = borrow as bool;
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

unconstrained pub(crate) fn __barrett_reduction<let N: u32>(
    x: [Field; 2 * N],
    redc_param: [Field; N],
    k: u32,
    modulus: [Field; N],
    modulus_u60: U60Repr<N, 4>
) -> ([Field; N], [Field; N]) {
    let mut mulout: [Field; 3 * N]  = [0; 3 * N];
    for i in 0..(N + N) {
        for j in 0..N {
            mulout[i + j] += x[i] * redc_param[j];
        }
    }
    mulout = split_bits::__normalize_limbs(mulout, 3 * N - 2);
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
    let mut quotient_mul_modulus: [Field; 2 * N]  = [0; 2 * N];
    let mut quotient_mul_modulus_normalized: [Field; 2 * N]  = [0; 2 * N];
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


// /**
//     * @brief compute the log of the size of the primitive root
//     * @details find the maximum value k where x^k = 1, where x = primitive root
//     *          This is needed for our Tonelli-Shanks sqrt algorithm
//     **/
// unconstrained fn primitive_root_log_size(self) -> u32 {
//     let mut target: U60Repr<N, 2> = self.modulus_u60 - U60Repr::one();
//     let mut result: u32 = 0;
//     for _ in 0..Params::modulus_bits() {
//         let lsb_is_one = (target.limbs[0] & 1) == 1;
//         if (!lsb_is_one) {
//             result += 1;
//             target.shr1();
//         } else {
//             break;
//         }
//     }
//     result
// }
// /**
//     * @brief inner loop fn for `find_multiplive_generator`
//     * @details recursive function to get around the lack of a `while` keyword
//     **/
// unconstrained fn recursively_find_multiplicative_generator(
//     self,
//     target: BigNum<N, Params>,
//     p_minus_one_over_two: BigNum<N, Params>
// ) -> (bool, BigNum<N, Params>) {
//     let exped = (self.__pow(target, p_minus_one_over_two));
//     let found = exped.__eq(self.__neg(BigNum::one()));
//     let mut result: (bool, BigNum<N, Params>) = (found, target);
//     if (!found) {
//         let _target = unsafe {
//             self.__add(target, BigNum::one())
//         };
//         result = self.recursively_find_multiplicative_generator(_target, p_minus_one_over_two);
//     }
//     result
// }
// /**
//     * @brief find multiplicative generator `g` where `g` is the smallest value that is not a quadratic residue
//     *        i.e. smallest g where g^2 = -1
//     * @note WARNING if multiplicative generator does not exist, this function will enter an infinite loop!
//     **/
// unconstrained fn multiplicative_generator(self) -> BigNum<N, Params> {
//     let mut target = BigNum::one();
//     let p_minus_one_over_two: U60Repr<N, 2> = (self.modulus_u60 - U60Repr::one()).shr(1);
//     let p_minus_one_over_two: BigNum<N, Params> = BigNum::from_array(U60Repr::into(p_minus_one_over_two));
//     let (_, target) = self.recursively_find_multiplicative_generator(target, p_minus_one_over_two);
//     target
// }
// unconstrained fn __tonelli_shanks_sqrt_inner_loop_check(self, t2m: BigNum<N, Params>, i: u32) -> u32 {
//     let is_one = t2m.__eq(BigNum::one());
//     let mut result = i;
//     if (!is_one) {
//         let t2m = self.__mul(t2m, t2m);
//         let i = i + 1;
//         result = self.__tonelli_shanks_sqrt_inner_loop_check(t2m, i);
//     }
//     result
// }

// /**
// * @brief compute a modular square root using the Tonelli-Shanks algorithm
// * @details only use for prime fields! Function may infinite loop if used for non-prime fields
// * @note this is unconstrained fn. To constrain a square root, validate that output^2 = self
// * TODO: create fn that constrains nonexistence of square root (i.e. find x where x^2 = -self)
// **/
// unconstrained fn __tonelli_shanks_sqrt(
//     self,
//     input: BigNum<N, Params>
// ) -> std::option::Option<BigNum<N, Params>> {
//     // Tonelli-shanks algorithm begins by finding a field element Q and integer S,
//     // such that (p - 1) = Q.2^{s}
//     // We can compute the square root of a, by considering a^{(Q + 1) / 2} = R
//     // Once we have found such an R, we have
//     // R^{2} = a^{Q + 1} = a^{Q}a
//     // If a^{Q} = 1, we have found our square root.
//     // Otherwise, we have a^{Q} = t, where t is a 2^{s-1}'th root of unity.
//     // This is because t^{2^{s-1}} = a^{Q.2^{s-1}}.
//     // We know that (p - 1) = Q.w^{s}, therefore t^{2^{s-1}} = a^{(p - 1) / 2}
//     // From Euler's criterion, if a is a quadratic residue, a^{(p - 1) / 2} = 1
//     // i.e. t^{2^{s-1}} = 1
//     // To proceed with computing our square root, we want to transform t into a smaller subgroup,
//     // specifically, the (s-2)'th roots of unity.
//     // We do this by finding some value b,such that
//     // (t.b^2)^{2^{s-2}} = 1 and R' = R.b
//     // Finding such a b is trivial, because from Euler's criterion, we know that,
//     // for any quadratic non-residue z, z^{(p - 1) / 2} = -1
//     // i.e. z^{Q.2^{s-1}} = -1
//     // => z^Q is a 2^{s-1}'th root of -1
//     // => z^{Q^2} is a 2^{s-2}'th root of -1
//     // Since t^{2^{s-1}} = 1, we know that t^{2^{s - 2}} = -1
//     // => t.z^{Q^2} is a 2^{s - 2}'th root of unity.
//     // We can iteratively transform t into ever smaller subgroups, until t = 1.
//     // At each iteration, we need to find a new value for b, which we can obtain
//     // by repeatedly squaring z^{Q}
//     let one: U60Repr<N, 2> = unsafe {
//         U60Repr::one()
//     };
//     let primitive_root_log_size = self.primitive_root_log_size();
//     let mut Q = (self.modulus_u60 - one).shr(primitive_root_log_size - 1);
//     let mut Q_minus_one_over_two = (Q - one).shr(2);
//     let mut Q_minus_one_over_two = BigNum::from_array(U60Repr::into(Q_minus_one_over_two));
//     let mut z = self.multiplicative_generator(); // the generator is a non-residue
//     let mut b = self.__pow(input, Q_minus_one_over_two);
//     let mut r = self.__mul(input, b);
//     let mut t = self.__mul(r, b);
//     let mut check: BigNum<N, Params> = t;
//     for _ in 0..primitive_root_log_size - 1 {
//         check = self.__mul(check, check);
//     }
//     let mut found_root = false;
//     if (check.__eq(BigNum::one()) == false) {} else {
//         let mut t1 = self.__pow(z, Q_minus_one_over_two);
//         let mut t2 = self.__mul(t1, z);
//         let mut c = self.__mul(t2, t1);
//         let mut m: u32 = primitive_root_log_size;
//         // tonelli shanks inner 1
//         // (if t2m == 1) then skip
//         // else increase i and square t2m and go again
//         // algorithm runtime should only be max the number of bits in modulus
//         let num_bits: u32 = Params::modulus_bits();
//         for _ in 0..num_bits {
//             if (t.__eq(BigNum::one())) {
//                 found_root = true;
//                 break;
//             }
//             let mut t2m = t;
//             // while loop time
//             let i = self.__tonelli_shanks_sqrt_inner_loop_check(t2m, 0);
//             let mut j = m - i - 1;
//             b = c;
//             for _ in 0..j { // how big
//                 if (j == 0) {
//                     break;
//                 }
//                 b = self.__mul(b, b);
//                 //j -= 1;
//             }
//             c = self.__mul(b, b);
//             t = self.__mul(t, c);
//             r = self.__mul(r, b);
//             m = i;
//         }
//     }
//     let mut result = std::option::Option { _value: r, _is_some: found_root };
//     result
// }
