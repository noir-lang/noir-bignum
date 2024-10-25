# noir-bignum

> [!WARNING]  
> If you're updating from release 0.3.7 to 0.4.0, please read these [migration notes](./migration_notes.md), because there are significant breaking changes.

An optimized big number library for Noir.

noir-bignum evaluates modular arithmetic for large integers of any length.

BigNum instances are parametrised by a struct that satisfies BigNumParamsTrait.

Multiplication operations for a 2048-bit prime field cost approx. 930 gates.

bignum can evaluate large integer arithmetic by defining a modulus() that is a power of 2.

## Benchmarks

TODO

## Dependencies

- Noir ≥v0.36.0
- Barretenberg ≥v0.56.1

Refer to [Noir's docs](https://noir-lang.org/docs/getting_started/installation/) and [Barretenberg's docs](https://github.com/AztecProtocol/aztec-packages/blob/master/barretenberg/cpp/src/barretenberg/bb/readme.md#installation) for installation steps.

## Installation

In your _Nargo.toml_ file, add the version of this library you would like to install under dependency:

```
[dependencies]
bignum = { tag = "v0.2.2", git = "https://github.com/noir-lang/noir-bignum" }
```

### Import

Add imports at the top of your Noir code, for example:

```rust
use dep::bignum::fields::U256::U256Params;
use dep::bignum::BigNum;
```

## `bignum`

BigNum members are represented as arrays of 120-bit limbs. The number of 120-bit limbs required to represent a given BigNum object must be defined at compile-time.

If your field moduli is _also_ known at compile-time, use the `BigNumTrait` definition in `lib.nr`

### BigNum struct

Big numbers are instantiated with the BigNum struct:

```rust
struct BigNum<let N: u32, let MOD_BITS: u32, Params> {
    limbs: [Field; N]
}
```

- `N` is the number of `Field` limbs together holding the value of the big number
- `MOD_BITS` is the bit-length of the modulus of the big number.
- `Params` is the parameters associated with the big number; refer to sections below for presets and customizations

### Usage

#### Example

A simple 1 + 2 = 3 check in 256-bit unsigned integers:

```rust
use dep::bignum::fields::U256::U256Params;
use dep::bignum::BigNum;

type U256 = BigNum<3, 257, U256Params>;

fn main() {
    let one: U256 = BigNum::from_array([1, 0, 0]);
    let two: U256 = BigNum::from_array([2, 0, 0]);
    let three: U256 = BigNum::from_array([3, 0, 0]);
    assert((one + two) == three);
}
```

#### Methods

TODO: Document all available methods

#### Moduli presets

##### Big Unsigned Integers

BigNum supports operations over unsigned integers, with predefined types for 256, 384, 512, 768, 1024, 2048, 4096 and 8192 bit integers.

All arithmetic operations are supported including integer div and mod functions (`udiv`, `umod`). Bit shifts and comparison operators are not yet implemented.

e.g.

```rust
use dep::bignum::fields::U256::U256Params;
use dep::bignum::BigNum;

type U256 = BigNum<3, 257, U256Params>;

fn foo(x: U256, y: U256) -> U256 {
    x.udiv(y)
}
```

##### Fields

`BigNum::fields` contains `BigNumParams` for common fields.

Feature requests and/or pull requests welcome for missing fields you need.

TODO: Document existing field presets (e.g. bls, ed25519, secp256k1)

## `RuntimeBigNum`

If your field moduli is _not_ known at compile-time (e.g. RSA verification), use the `RuntimeBigNum` struct defined in `runtime_bignum.nr`: `runtime_bignum::RuntimeBigNum`.

```rust
use dep::bignum::fields::bn254Fq::BN254_Fq_Params;

// Notice how we don't provide the params here, because we're pretending they're
// not known at compile-time, for illustration purposes.
type My_RBN = RuntimeBigNum<3, 254>;

fn main() {
    let params = BN254_Fq_Params::get_params(); // or some other params known at runtime.

    // Notice how we feed the params in, because we're pretending they're not
    // known at compile-time.
    let one: My_RBN = RuntimeBigNum::from_array(params, [1, 0, 0]);
    let two: My_RBN = RuntimeBigNum::from_array(params, [2, 0, 0]);
    let three: My_RBN = RuntimeBigNum::from_array(params, [3, 0, 0]);

    assert((one + two) == three);
}
```

### Types

User-facing structs:

`BigNum`: big numbers whose parameters are all known at compile-time.

`RuntimeBigNum`: big numbers whose parameters are only known at runtime. (Note: the number of bits of the modulus of the bignum must be known at compile-time).

If creating custom bignum params:

`BigNumParams` is needed, to declare your params. These parameters (`modulus`, `redc_param`) can be provided at runtime via witnesses (e.g. RSA verification). The `redc_param` is only used in unconstrained functions and does not need to be derived from `modulus` in-circuit.

`BigNumParamsGetter` is a convenient wrapper around params, which is needed if declaring a new type of `BigNum`.

#### Methods

##### Arithmetics

Basic expressions can be evaluated using the `BigNum` and `RuntimeBigNum` operators `+`,`-`,`*`,`/`. However, when evaluating relations (up to degree 2) that are more complex than single operations, the static methods `BigNum::evaluate_quadratic_expression` or `RuntimeBigNum::evaluate_quadratic_expression` are much more efficient (due to needing only a single modular reduction).

##### Unconstrained arithmetics

Unconstrained functions `__mul, __add, __sub, __div, __pow` etc. can be used to compute witnesses that can then be fed into `BigNumInstance::evaluate_quadratic_expression`.

> **Note:** `__div`, `__pow` and `div` are expensive due to requiring modular exponentiations during witness computation. It is worth modifying witness generation algorithms to minimize the number of modular exponentiations required. (for example, using batch inverses).

e.g. if we wanted to compute `(a + b) * c + (d - e) * f = g` by evaluating the above example, `g` can be derived via:

```rust
let a: BigNumInstance<3, 254, BN254_Fq_Params> = BigNum::new();
let t0 = c.__mul(a.__add(b));
let t1 = f.__mul(d.__sub(e));
let g = bn.__add(t0, t1);
```

then the values can be arranged and fed-into `evaluate_quadratic_expression`.

See `bignum_test.nr` and `runtime_bignum_test.nr` for more examples.

##### `evaluate_quadratic_expression`

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

`NUM_PRODUCTS` represents the number of multiplications being summed (e.g. for `a*b + c*d == 0`, `NUM_PRODUCTS` = 2).

`LHS_N, RHS_N` represents the number of `BigNum` objects being summed in the left and right operands of each product. For example, for `(a + b) * c + (d + e) * f == 0`, `LHS_N = 2`, `RHS_N = 1`.

`ADD_N` represents the number of `BigNum` objects being added into the product (e.g. for `a * b + c + d == 0`, `ADD_N = 2`).

The flag parameters `lhs_flags, rhs_flags, add_flags` define whether an operand in the expression will be negated. For example, for `(a + b) * c + (d - e) * f - g == 0`, we would have:

```rust
let lhs_terms = [[a, b], [d, e]];
let lhs_flags = [[false, false], [false, true]];
let rhs_terms = [[c], [f]];
let rhs_flags = [[false], [false]];
let add_terms = [g];
let add_flags = [true];
BigNum::evaluate_quadratic_expresson(lhs_terms, lhs_flags, rhs_terms, rhs_flags, linear_terms, linear_flags);
```

##### TODO: Document other available methods

#### Deriving BigNumParams parameters: `modulus`, `redc_param`

For common fields, BigNumParams parameters can be pulled from the presets in `bignum/fields/`.

For other moduli (e.g. those used in RSA verification), both `modulus` and `redc_param` must be computed and formatted according to the following speficiations:

`modulus` represents the BigNum modulus, encoded as an array of `Field` elements that each encode 120 bits of the modulus. The first array element represents the least significant 120 bits.

`redc_param` is equal to `(1 << (2 * Params::modulus_bits())) / modulus` . This must be computed outside of the circuit and provided either as a private witness or hardcoded constant. (computing it via an unconstrained function would be very expensive until noir witness computation times improve)

`double_modulus` is derived via the method `compute_double_modulus` in `runtime_bignum.nr`. If you want to provide this value as a compile-time constant (see `fields/bn254Fq.nr` for an example), follow the algorithm `compute_double_modulus` as this parameter is _not_ structly 2 \* modulus. Each limb except the most significant limb borrows 2^120 from the next most significant limb. This ensure that when performing limb subtractions `double_modulus.limbs[i] - x.limbs[i]`, we know that the result will not underflow.

BigNumParams parameters can be derived from a known modulus using the rust crate `noir-bignum-paramgen` (https://crates.io/crates/noir-bignum-paramgen)

## Additional usage examples

```rust
use dep::bignum::fields::bn254Fq::BN254_Fq_Params;

use dep::bignum::BigNum;

type Fq = BigNum<3, 254, BN254_Fq_Params>;

fn example_mul(Fq a, Fq b) -> Fq {
    a * b
}

fn example_ecc_double(Fq x, Fq y) -> (Fq, Fq) {
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
