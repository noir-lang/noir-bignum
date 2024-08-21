# noir-bignum

An optimized big number library for Noir. Evaluate modular arithmetic for large integers of any length.

This library predefines parameters for common moduli, but it also allows for the creation of custom parameter sets, either at compile-time or at runtime.

## Quickstart

### Prerequisites

- Noir ≥v0.32.0
- Barretenberg ≥v0.46.1

Refer to [Noir's docs](https://noir-lang.org/docs/getting_started/installation/) and [Barretenberg's docs](https://github.com/AztecProtocol/aztec-packages/blob/master/barretenberg/cpp/src/barretenberg/bb/readme.md#installation) for installation steps.

### Add dependency

In your _Nargo.toml_ file, add the version of this library you would like to install under dependency:

```
[dependencies]
bignum = { tag = "v0.3.0", git = "https://github.com/noir-lang/noir-bignum" }
```

### Import

Add imports at the top of your Noir code, for example:

```rust
use dep::bignum::fields::U256::U256Params;
use dep::bignum::BigNum;
```
### Addition in U256

A simple 1 + 2 = 3 check in 256-bit unsigned integers. Note that for performing multiple arithmetic operations up to degree 2 it is recommended to use `evaluate_quadratic_expression` (see explanation below). 

```rust
use dep::bignum::fields::U256::U256Params;
use dep::bignum::BigNum;

type U256 = BigNum<3, U256Params>;

fn main() {
    let one: U256 = BigNum::from_array([1, 0, 0]);
    let two: U256 = BigNum::from_array([2, 0, 0]);
    let three: U256 = BigNum::from_array([3, 0, 0]);
    assert((one + two) == three);
}
```

## Concepts

### BigNum definition

A BigNum is a number modulo `modulus` and is represented as an array of 120-bit limbs in little endian format. 

```rust
struct BigNum<let N: u64, Params> {
    limbs: [Field; N]
}
```
- `N` is the number of limbs needed to represent the number. Each limb is a `Field`, which contains max 120 bits (a field has 254 bits)
- `Params` is the parameters associated with the big number. The `modulus` is defined here. 

This library includes predefined parameter sets. Refer to below for preset info and how to customize the `Params` correctly. 

The actual value of a BigNum can be calculated by multiplying each limb by an increasing power of $2^{120}$. For example `[1,20,300]` represents $1 \cdot 2^{120\cdot0} + 20 \cdot 2^{120 \cdot 1} + 300 \cdot 2^{120 \cdot 2}$. We say that the BigNum is represented in radix- $2^{120}$. 

NOTE: `N` must be defined at compile-time. The `modulus` can be defined at compile-time or runtime. See further explanation below. 

### BigNum methods

The library offers all standard modular arithmetic operations, constrained and unconstrained. When evaluating more than 1 arithmetic operations, it is recommended to perform unconstrained arithmetic operations and then constrain using `evaluate_quadratic_expression`. See further explanation below. 

Additionally there are some convenient methods to manipulate a BigNum or make assertions about it. 

#### Constrained functions

Constrained arithmetic operations. These perform the expected arithmetic operations and reduce the result modulo `modulus`:
- `add`
- `sub`
- `mul`
- `neg`
- `div` - Expensive!
  - Note: this method is only available for Fields, i.e if all elements have a multiplicative inverse. If this is not the case, use `udiv`
- `udiv`/`udiv_mod` - Expensive!
  - Note: only use if you're not working with a Field
- `umod` - Expensive!
  - Integer modular reduction which uses `udiv`

For compile-time known moduli (see explanation below), these methods can be used using operators (`+`, `-`, `*`, `/`). 

> **Note:** `div`, `udiv` and `umod` are expensive due to requiring modular exponentiations during witness computation. It is worth modifying witness generation algorithms to minimize the number of modular exponentiations required. (for example, using batch inverses)


Other constrained functions:
- `new`, returns a BigNum with value 0
- `one`, returns a BigNum with value 1
- `modulus`, returns `modulus` from the parameters
- `modulus_bits`, returns nr of bits from the parameters
- `num_limbs`, returns N, the number of limbs needed to represent the BigNum for the current parameters
- `evaluate_quadratic_expression`, more explanation below
- `validate_in_range`, validates the BigNum doesn't have more bits than `modulus_bits`
- `validate_in_field(val)`, validates `val` < `modulus`
- `assert_is_not_equal`, assert 2 BigNums are distinct
- `eq`, also available with `==` for compile-time known moduli
- `get(idx)`, return value of limbs `idx` (this is a field)
- `set_limb(idx, value)`, set limbs `idx` to new value
- `conditional_select(lhs, rhs, predicate)`, if `predicate` is 0 returns `lhs`, else if `predicate` is 1 returns `rhs` 
- `to_le_bytes`, returns the little-endian byte representation of a BigNum

#### Unconstrained functions

All the constrained arithmetic methods have their unconstrained counterpart and there is an unconstrained method for exponentiation. The unconstrained methods are prefixed with `__`:
- `__add`
- `__sub`
- `__mul`
- `__neg`
- `__div`
  - Note: this method is only available for fields, i.e if all elements have a multiplicative inverse. If this is not the case, use `__udiv`
- `__udiv`/`__udiv_mod`
  - Note: only use if you're not working with a field
- `__pow`

> **Note:** `__div`, `__udiv` and `__pow` are expensive due to requiring modular exponentiations during witness computation. It is worth modifying witness generation algorithms to minimize the number of modular exponentiations required. (for example, using batch inverses, mentioned below)


For better performance, try to accumulate multiple arithmetic operations (up to degree 2), for example `a*b+c*e+d` and then constrain it once with `evaluate_quadratic_expression`. Find instructions on how to use that method below.

Use the following unconstrained operations only when working with a field (otherwise the inverse is not defined):

- `__invmod`, returns inverse of element
- `__batch_invert`, input is fixed size array. Returns inverses of all elements
- `__batch_invert_slice`, input is dynamically sized array. Returns inverses of all elements

Other useful unconstrained functions:
- `__derive_from_seed`, only use for test purposes. Not cryptographically secure
- `__is_zero`
- `__eq`

#### `evaluate_quadratic_expression`

For a lower gatecount and thus better performance use `BigNumInstance::evaluate_quadratic_expression`. The goal is to perform multiple unconstrained arithmetic operations and then constrain with this function. E.g. if we wanted to compute `a * b + (c + d) * e + f = g`, instead of calling all five arithmetic operations in their constrained form, compute `g` via unconstrained functions and then constrain it at once with `evaluate_quadratic_expression`. 

Unconstrained functions `__mul, __add, __sub, __div, __pow` can be used to compute witnesses that can then be fed into `evaluate_quadratic_expression`.

The method `evaluate_quadratic_expression` has the following interface:

```rust
    fn evaluate_quadratic_expression<let LHS_N: u64, let RHS_N: u64, let NUM_PRODUCTS: u64, let ADD_N: u64>(
        self,
        lhs_terms: [[BN; LHS_N]; NUM_PRODUCTS],
        lhs_flags: [[bool; LHS_N]; NUM_PRODUCTS],
        rhs_terms: [[BN; RHS_N]; NUM_PRODUCTS],
        rhs_flags: [[bool; RHS_N]; NUM_PRODUCTS],
        linear_terms: [BN; ADD_N],
        linear_flags: [bool; ADD_N]
    );
```

`NUM_PRODUCTS` represents the number of multiplications being summed.

`LHS_N, RHS_N` represents the number of `BigNum` objects being summed in the left and right operands of each product. 

`ADD_N` represents the number of `BigNum` objects being added

The flag parameters `lhs_flags, rhs_flags, add_flags` define whether an operand in the expression will be negated. 

For example, for the earlier example we wanted to calculate `a * b + (c + d) * e + f = g`. To constrain this, we pass `a * b + (c + d) * e + f - g = 0` to `evaluate_quadratic_expression`. The parameters then become:
- `NUM_PRODUCTS` = 2. The products are `a * b` and `(c + d) * e`
- `LHS_N` = 2, `RHS_N` = 1. For the left hand side the first multiplication has 1 operand and the other 2, so take the upper limit and pad with zeroes
- `ADD_N` = 2. The linear terms are `f` and `-g`


To constrain the example, first calculate `g = a * b + (c + d) * e + f` in unconstrained functions.
```rust
// First product term a * b
let t0 = a.__mul(b);
// Second product term (c + d) * e
let t1 = (c.__add(d)).__mul(e); 
let g = t0.__add(t1).__add(f);
```



Then define the terms and flags to constrain `a * b + (c + d) * e + f - g = 0` and call `evaluate_quadratic_expression`. 
```rust
// (a + 0) * b
let lhs_terms = [[a, BigNum::new()], [c, d]];
let lhs_flags = [[false, false], [false, false]];
// (c + d) * e 
let rhs_terms = [[b], [e]];
let rhs_flags = [[false], [false]];
// + f + (-g)
let add_terms = [f, g];
let add_flags = [false, true];

BigNum::evaluate_quadratic_expression(lhs_terms, lhs_flags, rhs_terms, rhs_flags, linear_terms, linear_flags);
```

##### Example usage evaluate_quadratic_expression

In the base field of Ed25519, which is the integers mod $2^{255}-19$, perform simple arithmetic operations `(x1 * x2) + x3` and assert this equals `expected`. 

```rust
use dep::bignum::fields::ed25519Fq::{ED25519_Fq_Params, ED25519_Fq_Instance};
use dep::bignum::runtime_bignum::BigNumInstance;
use dep::bignum::BigNum;

// Prime field mod 2^255-19
type Fq = BigNum<3, ED25519_Fq_Params>;

// Check that (x1 * x2) + x3 equals `expected`
fn main(x1: Fq, x2: Fq, x3: Fq, expected: Fq) {
    // Step 1: calculate res = (x1 * x2) + x3 in unconstrained functions 
    let res = x1.__mul(x2).__add(x3);

    // Step 2: Constrain (x1 * x2) + x3 - res == 0 mod 2^255-19
    // (until now we have value res, but "unchecked")

    // `evaluate_quadratic_expression` takes: 
    // (1) x1, `false` sign flag
    // (2) x2, `false` sign flag
    // (3) 
    //  - x3, `false` sign flag
    //  - res, `true` sign flag
    // Combines to: (x1 * x2) + x3 + (-res)
    BigNum::evaluate_quadratic_expression([[x1]], [[false]], [[x2]], [[false]], [x3, res], [false, true]);

    // Step 3: check res equals `expected`
    assert(res == expected); // Equality operation on BigNums
}
```

See `bignum_test.nr` for more examples.

### Types

BigNum operations are evaluated using two structs and a trait: `BigNumParamsTrait`, `BigNum<N, Params>`, `BigNumInstance<N, Params>`.

`BigNumParamsTrait` defines the compile-time properties of a BigNum instance: the number of modulus bits and the Barret reduction parameter `k` (TODO: these two values should be the same?!)

`BigNumInstance` is a generator type that is used to create `BigNum` objects and evaluate operations on `BigNum` objects. It wraps BigNum parameters that may not be known at compile time (the `modulus` and a reduction parameter required for Barret reductions (`redc_param`)).

If your field modulus is _not_ known at compile-time (e.g. RSA verification), use the traits and structs defined in `runtime_bignum`: `runtime_bignum::BigNumTrait` and `runtime_bignum::BigNumInstanceTrait`. 

A `runtime_bignum::BigNumInstance` wraps the bignum modulus (as well as a derived parameter used internally to perform Barret reductions). A `BigNumInstance` object is required to evaluate most bignum operations.


### `modulus`

The modulus can be either known at compile-time or run-time. 

#### Compile-time known modulus

For a modulus that is known at compile-time there are 2 options: 
- use a predefined set of parameters, which are defined in `bignum/fields`. These are commonly used fields and unsigned integers
- create a new parameterset. For this you need to implement the `RuntimeBigNumParamsTrait` and `BigNumParamsTrait`, and create a `BigNumInstance`. [This tool](https://github.com/noir-lang/noir-bignum-paramgen) can be used, and see the predefined parameter sets mentioned in previous point to see examples

In the case of a compile-time known modulus, the arithmetic can be executed directly on the BigNums themselves:

```rust
let a: U256 = BigNum::from_array([10, 0, 0]);
let b: U256 = BigNum::from_array([2, 0, 0]);

let c = a * b; // <- operator use only possible when modulus is known at compile-time

assert(c == BigNum::from_array([20, 0, 0]));
```

##### Predefined Unsigned Integers

BigNum supports operations over unsigned integers, with predefined types for 256, 384, 512, 768, 1024, 2048, 4096 and 8192 bit integers. Keep in mind these are not Fields.

All arithmetic operations are supported including integer div and mod functions (make sure to use udiv, umod). Bit shifts and comparison operators are not yet implemented.

```rust
use dep::bignum::fields::U256::U256Params;
use dep::bignum::BigNum;

type U256 = BigNum<3, U256Params>;

fn foo(x: U256, y: U256) -> U256 {
    x.udiv(y)
}
```

##### Predefined Fields

This library includes the follow field presets:

| Curve       | Base Field Instance                | Scalar Field Instance              |
|-------------|------------------------------------|------------------------------------|
| [BLS12-377](https://eprint.iacr.org/2020/351)   | `BLS12_377_Fq_Instance`            | `BLS12_377_Fr_Instance`            |
| [BLS12-381](https://electriccoin.co/blog/new-snark-curve/)   | `BLS12_381_Fq_Instance`            | `BLS12_381_Fr_Instance`            |
| [BN254](https://zips.z.cash/protocol/protocol.pdf)   | `BN254INSTANCE`                    | (Scalar field is the native field in Noir) |
| [Curve25519](https://cr.yp.to/ecdh/curve25519-20060209.pdf)  | `ED25519_Fq_Instance`              | `ED25519_Fr_Instance`              |
| [MNT4-753](https://eprint.iacr.org/2014/595)    | `MNT4_753_Fq_Instance`             | `MNT4_753_Fr_Instance`             |
| [MNT6-753](https://eprint.iacr.org/2014/595)    | `MNT6_753_Fq_Instance`             | `MNT6_753_Fr_Instance`             |
| [Pallas](https://electriccoin.co/blog/the-pasta-curves-for-halo-2-and-beyond/)*      | `Pallas_Fr_Instance` | `Pallas_Fq_Instance` |
| [Secp256k1](https://en.bitcoin.it/wiki/Secp256k1) | `Secp256k1_Fq_Instance`            | `Secp256k1_Fr_Instance`            |
| [Secp256r1](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-4.pdf) | `Secp256r1_Fq_Instance`            | `Secp256r1_Fr_Instance`            |
| [Secp384r1](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-4.pdf) | `Secp384r1_Fq_Instance`            | `Secp384r1_Fr_Instance`            |

* TODO: this should probably be adjusted, to avoid confusion

Feature requests and/or pull requests welcome for missing fields you need.

#### Run-time known modulus

To define the custom modulus (e.g. those used in RSA verification) at run-time it is necessary to create a parameterset and a `BigNumInstance` with the following data:
(Tip: use the  paramgen tool linked at the end of this section)

- `modulus` represents the BigNum modulus, encoded as an array of `Field` elements that each encode 120 bits of the modulus. The first array element represents the least significant 120 bits

- `redc_param` is equal to `(1 << (2 * Params::modulus_bits())) / modulus` . This must be computed outside of the circuit and provided either as a private witness or hardcoded constant. (computing it via an unconstrained function would be very expensive until noir witness computation times improve)

- `double_modulus` is derived via the method `compute_double_modulus` in `runtime_bignum.nr`. If you want to provide this value as a compile-time constant (see `fields/bn254Fq.nr` for an example), follow the algorithm `compute_double_modulus` as this parameter is _not_ structly 2 \* modulus. Each limb except the most significant limb borrows 2^120 from the next most significant limb. This ensure that when performing limb subtractions `double_modulus.limbs[i] - x.limbs[i]`, we know that the result will not underflow

BigNumInstance parameters can be derived from a known modulus using the rust crate `noir-bignum-paramgen` (https://crates.io/crates/noir-bignum-paramgen).

##### Example defining custom modulus parameterset & bignum instance
For example, to work with RSA and a run-time defined modulus of 1024 bits, your Noir program will need to receive a `BigNumInstance` as an argument. This object will be used to perform the arithmetic operations on the given BigNums. 

```rust
pub fn verify_add<BNInstance, BN>(
    instance: BNInstance,
    a: BN,
    b: BN,
    expected: BN
) where BN: BigNumTrait, BNInstance: BigNumInstanceTrait<BN> {
    let c = instance.add(a, b);
    assert(instance.eq(expected, c));
}
```

Note that in this case, performing `a*b` or `expected == c` is not possible directly; rather, the arithmetic operations must be executed using the `BigNumInstance`. 

At run-time, the modulus is determined and the parameterset has to be defined as follows:
- modulus has 1024 bits
- N = 9 (ceil(1024/120) = 9)
- using your custom `modulus`, generate the actual values needed for `BigNumInstance` (`double_modulus`, `redc_param` etc) using the [paramgen tool](https://github.com/noir-lang/noir-bignum-paramgen)

```rust
struct RSA1024Params {}

impl RuntimeBigNumParamsTrait<9> for RSA1024Params {
    fn modulus_bits() -> u32 {
        1024
    }
    fn has_multiplicative_inverse() -> bool { false }

}
impl BigNumParamsTrait<9> for RSA1024Params {
    fn get_instance() -> BigNumInstance<9, Self> {
        MyMod_Instance
    }
    fn modulus_bits() -> u32 {
        1024
    }
    fn has_multiplicative_inverse() -> bool { false }
}

// insert real values here
let MyMod_Instance: BigNumInstance<9, RSA1024Params> = BigNumInstance::new {
        modulus: [..],
        double_modulus: [..],
        modulus_u60: ..,
        modulus_u60_x4: ..,
        redc_param: [..]
};
```

Now the initial function can be called using the `RSA1024Params` and `MyMod_Instance`. Here we show this in a Noir test. 

```rust
type RSA1024 = BigNum<9, RSA1024Params>;

#[test]
fn test_add() {
    let mut a: RSA1024 = BigNum::new();
    a.limbs[0] = 10;
    let mut b: RSA1024 = BigNum::new();
    b.limbs[0] = 20;

    let mut expected: RSA1024 = BigNum::new();
    expected.limbs[0] = 30;

    verify_add(MyMod_Instance, a, b, expected);
}
```

TODO: should modulus and redc_param be passed in as witnesses? Because of this comment:
> BigNumInstance parameters (`modulus`, `redc_param`) can be provided at runtime via witnesses (e.g. RSA verification). The `redc_param` is only used in unconstrained functions and does not need to be derived from `modulus` in-circuit.

## Benchmarks

Benchmarks can be run using [this repo](https://github.com/hashcloak/noir-bigint-bench/). 

A full benchmark report based on that repo can be found [here](https://docs.google.com/spreadsheets/d/1KBc6mhMZ4iQYIZhsyF8E6-juhob7mM94sBKqVKS-v-8/edit?gid=0#gid=0). Below a few numbers are repeated. 

Number of gates:
| BigNum |  100 mult  | 100 add/sub |
|:-----|:--------:|:------:|
| **U256**   | 8507 | 5510 |
| **U1024**   |  31960  | 11832 |
| **U2048**   | 86935 | 20857 |

Proving time, UP = UltraPlonk, UH = UltraHonk, in milliseconds:

| BigNum |  100 mult UP  | 100 add UP | 100 mult HP  | 100 add HP |
|:-----|:--------:|:------:|:--------:|:------:|
| **U256**   | 548.6 | 313.1 | 329.8 | 208 | 
| **U1024**   |  1026.1  | 498.4 | 614.1 | 292 | 
| **U2048**   | 3101.2 | 842.3 | 1404.4 | 436.9 | 


## Additional usage example

Elliptic curve point doubling using `evaluate_quadratic_expression`:

```rust
use dep::bignum::fields::bn254Fq::BNParams;
use dep::bignum::fields::bn254Fq::BN254INSTANCE;
use dep::bignum::BigNum;
use dep::bignum::runtime_bignum::BigNumInstance;

type Fq = BigNum<3, BNParams>;

fn example_ecc_double(x: Fq, y: Fq) -> (Fq, Fq) {
    // Step 1: construct witnesses
    // lambda = 3*x*x / 2y
    let mut lambda_numerator = x.__mul(x);
    lambda_numerator = lambda_numerator.__add(lambda_numerator.__add(lambda_numerator));
    let lambda_denominator = y.__add(y);
    let lambda = lambda_numerator / lambda_denominator;
    // x3 = lambda * lambda - x - x
    let x3 = lambda.__mul(lambda).__sub(x.__add(x));
    // y3 = lambda * (x - x3) - y
    let y3 = lambda.__mul(x.__sub(x3)).__sub(y);

    // Step 2: constrain witnesses to be correct using minimal number of modular reductions (3)
    // 2y * lambda - 3*x*x = 0
    BigNum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[y,y]],
        [[false, false]],
        [x,x,x],
        [true, true, true]
    );
    // lambda * lambda - x - x - x3 = 0
    BigNum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[lambda]],
        [[false]],
        [x3,x,x],
        [true, true, true]
    );
    // lambda * (x - x3) - y = 0
     BigNum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[x, x3]],
        [[false, true]],
        [y],
        [true]
    );
    (x3, y3)
}
```
