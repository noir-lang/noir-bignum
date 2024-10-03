use crate::utils::u60_representation::U60Repr;
use crate::utils::split_bits;

use crate::params::BigNumParams as P;

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
    mulout = split_bits::__normalize_limbs(mulout, 3 * N - 1);
    let mulout_u60: U60Repr<N, 6> = U60Repr::new(mulout);
    let mut quotient_u60 = mulout_u60.shr((k + k));

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
