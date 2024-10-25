use crate::utils::u60_representation::U60Repr;

#[test]
unconstrained fn test_conversion() {
    let p = 0xffffffffffffffffffffffffffffff; // 2^120 - 1
    let expected: [Field; 3 * 2] = [p, p - 1, p - 2, p - 3, p - 4, p - 5];
    let u60repr: U60Repr<3, 4> = unsafe { U60Repr::new(expected) };
    let result = unsafe { u60repr.into_field_array() };
    assert(result == expected);
}

// 1010 = A
// 0101 = 5

#[test]
fn test_shr() {
    // 120 bits of 10101010 (repeating)
    let X = 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    // 120 bits of 01010101 (repeating)
    let Y = 0x555555555555555555555555555555;
    let input: [Field; 6] = [X, X, X, X, X, X];
    let u60repr: U60Repr<3, 6> = unsafe { U60Repr::new(input) };

    let result = u60repr.shr(121);
    let expected: U60Repr<3, 6> = unsafe { U60Repr::new([Y, Y, Y, Y, Y, 0]) };
    assert(result == expected);

    let noshift = u60repr.shr(0);
    assert(noshift == u60repr);
}

#[test]
fn test_shl() {
    // 120 bits of 10101010 (repeating)
    let X = 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    // 120 bits of 01010101 (repeating)
    let Y = 0x555555555555555555555555555555;
    let input: [Field; 6] = [Y, Y, Y, Y, Y, Y];
    let u60repr: U60Repr<3, 6> = unsafe { U60Repr::new(input) };

    let result = u60repr.shl(121);
    let expected: U60Repr<3, 6> = unsafe { U60Repr::new([0, X, X, X, X, X, X, 0, 0]) };
    assert(result == expected);

    let noshift = u60repr.shr(0);
    assert(noshift == u60repr);
}

#[test]
fn test_get_bit() {
    // 0x8000 = b1000000000000000 (16th bit is high)
    // 256th bit of input should be high
    let input: [Field; 6] = [0, 0, 0x8000, 0, 0, 0];
    let u60repr: U60Repr<3, 6> = unsafe { U60Repr::new(input) };
    for i in 0..720 {
        if i == 255 {
            assert(u60repr.get_bit(i) == true);
        } else {
            assert(u60repr.get_bit(i) == false);
        }
    }
}

#[test]
unconstrained fn test_gte() {
    let p = 0xffffffffffffffffffffffffffffff; // 2^120 - 1
    let input: [Field; 6] = [p, p - 1, p - 2, p - 3, p - 4, p - 5];
    let lhs: U60Repr<3, 6> = unsafe { U60Repr::new(input) };

    {
        let rhs = lhs;
        assert(unsafe { lhs.gte(rhs) });
    }
    {
        // make rhs smaller by 1
        let mut rhs: U60Repr<3, 6> = lhs;
        rhs.limbs[0] -= 1;
        assert(unsafe { lhs.gte(rhs) });
    }
    {
        // make rhs greater by 1
        let mut rhs = lhs;
        rhs.limbs[0] += 1;
        assert(!unsafe { lhs.gte(rhs) });
    }
}
