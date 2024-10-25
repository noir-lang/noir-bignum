# Migration notes: 0.3.7 to 0.4.0

This lib got a big refactor for release 0.4.0.

Here's a summary of changes that will hopefull help you update.

For a quick overview, see the updated [README](./README.md).

## An extra generic param

Previously, a BigNum type was declared as:

`type MyBigNum = BigNum<3, MyParams>;`

where `3` was the number of limbs of your bignum, and `MyParams` is either a prebuild struct of `Params` from the `fields/` dir of this library, or your own custom set of params.

Now, we need to also specify an extra param: the number of bits in the modulus.

E.g.

`type MyBigNum = BigNum<3, 254, MyParams>;`

## Runtime BigNums are very different

Recall that runtime bignums need to be used instead of `BigNum`, if the parameters of the bignum (e.g. the modulus) are not known at compile-time, but instead only known at runtime.

Headlines:
- Runtime BigNums now have their own dedicated struct: `RuntimeBigNum`, instead of using `BigNum` for this purpose.
- `RuntimeBigNum` values can be operated-on with overloaded operators `==,+,-,*,/`, 
    - But heed the warning (which was also true in the old version of bignum): that usage of these operators might not be as efficient (constraint-wise) as saving-up operations and instead executing `evaluate_quadratic_constraint()`.
- An instance of the runtime-known `params: BigNumParams` needs to be passed into the constructors of `RuntimeBigNum`s.
- `BigNum` and `RuntimeBigNum` now have the same set of methods available to them, it's just that `RuntimeBigNum` constructors will need to be given some runtime-computed `params: BigNumParams`.


### Example

Previously, runtime bignum operations were executed via an instance of a `BigNumInstance`.

Old code:

```rust
fn test_sub() {
    // Get some params, which we assume in this example are only known at runtime.
    let bn = MyParams::get_instance();

    // Notice the extra "modulus bits" generic param of 254.
    let mut a: BigNum<3, 254, MyParams> = BigNum::new(); // 0
    let mut b: BigNum<3, 254, MyParams> = BigNum::one(); // 1

    // Notice how the `sub` operation is orchestrated via the `bn` instance:
    let result = bn.sub(a, b);

    let mut expected: BigNum<3, MyParams> = bn.modulus();
    expected.limbs[0] -= 1; // p - 1

    // Notice how the `eq`  operation is orchestrated via the `bn` instance:
    assert(bn.eq(result, expected));
}
```

New code:

The above code would need to be changed to something like this:

```rust
fn test_sub() {
    // Get some params, which we assume in this example are only known at runtime.
    let params = MyParams::get_params(); // Notice the changed function name.

    // Notice there is a new struct called `RuntimeBigNum` specifically for bignums
    // whose parameters are not known at compile-time, instead of using `BigNum` in 
    // this scenario.

    // Notice the extra "modulus bits" generic param of 254.

    // Notice the runtime-known `params` need to be passed into RuntimeBigNum constructors.
    let mut a: RuntimeBigNum<3, 254> = RuntimeBigNum::new(params); // 0 
    let mut b: RuntimeBigNum<3, 254> = RuntimeBigNum::one(params); // 1

    // Notice, you can operate on `a` and `b` without a "big num instance" 
    // orchestrating it.

    // Notice, `a` and `b` can be operated-on via overloaded operators ==,+,-,*,/, 
    // just like their `BigNum` counterparts. 
    
    // But heed the warning (which was also true in the old version of bignum): that 
    // usage of these operators might not be as efficient (constraint-wise)
    // as saving-up operations and instead executing `evaluate_quadratic_constraint()`.
    let result = a - b;

    let mut expected: RuntimeBigNum<3, 254> = RuntimeBigNum { limbs: params.modulus, params };
    expected.limbs[0] -= 1; // p - 1
    // Alternatively to this line, you could do:
    // let mut expected = a.modulus();
    // expected.limbs[0] -= 1; // p - 1
    // (we just wanted to show a bit more machinery in this example)

    // Notice that RuntimeBigNum supports ==, +, -, *, /.
    assert(result == expected);
}
```