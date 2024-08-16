# noir-bignum

An optimized big number library for Noir. Evaluate modular arithmetic for large integers of any length.

This library predefines parameters for common moduli, but it also allows for the creation of custom parameter sets, either at compile-time or at runtime.

## Quickstart

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

A simple 1 + 2 = 3 check in 256-bit unsigned integers:

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

## Dependencies

- Noir ≥v0.32.0
- Barretenberg ≥v0.46.1

Refer to [Noir's docs](https://noir-lang.org/docs/getting_started/installation/) and [Barretenberg's docs](https://github.com/AztecProtocol/aztec-packages/blob/master/barretenberg/cpp/src/barretenberg/bb/readme.md#installation) for installation steps.


## `bignum`

A BigNum is a number mod `modulus` and is represented as an array of 120-bit limbs. 

```rust
struct BigNum<let N: u64, Params> {
    limbs: [Field; N]
}
```
- `N` is the number of limbs needed to represent the number. Each limb is a `Field` array
- `Params` is the parameters associated with the big number. The `modulus` is defined here. 

This library includes predefined parameter sets. Refer to below for preset info and how to customize the `Params` correctly. 

The actual value of a BigNum can be calculated by multiplying each limb by an increasing power of $2^{120}$. For example `[1,20,300]` represents $1*2^{120*0} + 20*2^{120*1} + 300*2^{120*2}$. It is represented in radix-$2^{120}$. 

NOTE: `N` must be defined at compile-time. The `modulus` can be defined at compile-time or runtime.


### Types

bignum operations are evaluated using two structs and a trait: `ParamsTrait`, `BigNum<N, Params>`, `BigNumInstance<N, Params>`.

`ParamsTrait` defines the compile-time properties of a BigNum instance: the number of modulus bits and the Barret reduction parameter `k` (TODO: these two values should be the same?!)

`BigNumInstance` is a generator type that is used to create `BigNum` objects and evaluate operations on `BigNum` objects. It wraps BigNum parameters that may not be known at compile time (the `modulus` and a reduction parameter required for Barret reductions (`redc_param`)).

The `BigNum` struct represents individual big numbers.

### Methods

TODO: Document all available methods
Or does this become redundant with text below?

### Define your own parameter set

For common fields, BigNumInstance parameters can be pulled from the presets in `BigNum::fields`, see below for further information. 

For other moduli (e.g. those used in RSA verification), both `modulus` and `redc_param` must be computed and formatted according to the following speficiations:

- `modulus` represents the BigNum modulus, encoded as an array of `Field` elements that each encode 120 bits of the modulus. The first array element represents the least significant 120 bits

- `redc_param` is equal to `(1 << (2 * Params::modulus_bits())) / modulus` . This must be computed outside of the circuit and provided either as a private witness or hardcoded constant. (computing it via an unconstrained function would be very expensive until noir witness computation times improve)

- `double_modulus` is derived via the method `compute_double_modulus` in `runtime_bignum.nr`. If you want to provide this value as a compile-time constant (see `fields/bn254Fq.nr` for an example), follow the algorithm `compute_double_modulus` as this parameter is _not_ structly 2 \* modulus. Each limb except the most significant limb borrows 2^120 from the next most significant limb. This ensure that when performing limb subtractions `double_modulus.limbs[i] - x.limbs[i]`, we know that the result will not underflow

BigNumInstance parameters can be derived from a known modulus using the rust crate `noir-bignum-paramgen` (https://crates.io/crates/noir-bignum-paramgen).


### Moduli presets

#### Big Unsigned Integers

BigNum supports operations over unsigned integers, with predefined types for 256, 384, 512, 768, 1024, 2048, 4096 and 8192 bit integers.

All arithmetic operations are supported including integer div and mod functions (`udiv`, `umod`). Bit shifts and comparison operators are not yet implemented.

e.g.

```rust
use dep::bignum::fields::U256::U256Params;
use dep::bignum::BigNum;

type U256 = BigNum<3, U256Params>;

fn foo(x: U256, y: U256) -> U256 {
    x.udiv(y)
}
```

#### Fields

`BigNum::fields` contains `BigNumInstance` constructors for common fields.

- [BLS12-377](https://eprint.iacr.org/2020/351) base field `BLS12_377_Fq_Instance` and scalar field `BLS12_377_Fr_Instance`
- [BLS12-381](https://electriccoin.co/blog/new-snark-curve/) base field `BLS12_381_Fq_Instance` and scalar field `BLS12_381_Fr_Instance`
- [BN254](https://zips.z.cash/protocol/protocol.pdf) base field `BN254INSTANCE` (the scalar field is the native field in Noir)
- [Curve25519](https://cr.yp.to/ecdh/curve25519-20060209.pdf) base field `ED25519_Fq_Instance` and scalar field `ED25519_Fr_Instance`
- TODO add other fields

Feature requests and/or pull requests welcome for missing fields you need.

Example: a single multiplication in base field `Fq` of [BLS12-381](https://electriccoin.co/blog/new-snark-curve/). (Note that executing multiple arithmetic operations should be combined and constrained with `evaluate_quadratic_expression` for performance reasons, see explanation below)

```rust
use dep::bignum::fields::bls12_381Fq::{BLS12_381_Fq_Params, BLS12_381_Fq_Instance};
use dep::bignum::runtime_bignum::BigNumInstance;
use dep::bignum::BigNum;

// Define the type of an element in the field
type Fq = BigNum<4, BLS12_381_Fq_Params>;

// returns a*b mod q (constrained)
fn bls12_381_mult(a: Fq, b: Fq) -> Fq {
    BLS12_381_Fq_Instance.mul(a, b)
}
```

## `runtime_bignum`

If your field modulus is _not_ known at compile-time (e.g. RSA verification), use the traits and structs defined in `runtime_bignum`: `runtime_bignum::BigNumTrait` and `runtime_bignum::BigNumInstanceTrait`. 

A `runtime_bignum::BigNumInstance` wraps the bignum modulus (as well as a derived parameter used internally to perform Barret reductions). A `BigNumInstance` object is required to evaluate most bignum operations.

BigNumInstance parameters (`modulus`, `redc_param`) can be provided at runtime via witnesses (e.g. RSA verification). The `redc_param` is only used in unconstrained functions and does not need to be derived from `modulus` in-circuit.


### Types

TODO clarify difference with bignum
 
### Example

TODO

### Methods

TODO how to clearly document methods for bignum and runtime-bignum

##### Arithmetics

Basic expressions can be evaluated using `BigNumInstance::add, BigNumInstance::sub, BigNumInstance::mul`. However, when evaluating relations (up to degree 2) that are more complex than single operations, the function `BigNumInstance::evaluate_quadratic_expression` is more efficient (due to needing only a single modular reduction).

##### Unconstrained arithmetics

Unconstrained functions `__mul, __add, __sub, __div, __pow` can be used to compute witnesses that can then be fed into `BigNumInstance::evaluate_quadratic_expression`.

> **Note:** `__div`, `__pow` and `div` are expensive due to requiring modular exponentiations during witness computation. It is worth modifying witness generation algorithms to minimize the number of modular exponentiations required. (for example, using batch inverses)

e.g. if we wanted to compute `(a + b) * c + (d - e) * f = g` by evaluating the above example, `g` can be derived via:

```rust
let bn: BigNumInstance<3, BNParams> = BNInstance();
// (a+b)*c
let t0 = bn.__mul(bn.__add(a, b), c);
// (d-e)*f
let t1 = bn.__mul(bn.__add(d, bn.__neg(e)), f);
let g = bn.__add(t0, t1);
```

See `bignum_test.nr` for more examples.

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



## Additional usage examples

```rust
use crate::bignum::fields::bn254Fq::BNParams;
use crate::bignum::fields::BN254Instance;
use crate::bignum::BigNum;
use crate::bignum::runtime_bignum::BigNumInstance;

type Fq = BigNum<3, BNParams>;

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


#### Arithmetic operations in Ed25519 TODO use this?

In the prime field of Ed25519, the integers mod $2^{255}-19$, perform simple arithmetic operations `(x1 * x2) + x3` and compare them to the expected result `expected`. 

```rust
use dep::bignum::fields::ed25519Fq::{ED25519_Fq_Params, ED25519_Fq_Instance};
use dep::bignum::runtime_bignum::BigNumInstance;
use dep::bignum::BigNum;

// Prime field mod 2^255-19
type Fq = BigNum<3, ED25519_Fq_Params>;

// Check that (x1 * x2) + x3 equals `expected`
fn main(x1: Fq, x2: Fq, x3: Fq, expected: Fq) {
    // Define alias of field instance for readability
    let fq: BigNumInstance<3, ED25519_Fq_Params> = ED25519_Fq_Instance;

    // Step 1: calculate res = (x1 * x2) + x3 in unconstrained functions 
    let res = fq.__mul(x1, x2).__add(x3);

    // Step 2: Constrain (x1 * x2) + x3 - res == 0 mod 2^255-19
    // (until now we have value res, but "unchecked")

    // `evaluate_quadratic_expression` takes: 
    //  (1) left-hand side product terms with their sign flags
    //  (2) right-hand side product terms with their sign flags
    //  (3) linear terms
    // In this case those inputs are:
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

## Benchmarks

Benchmarks can be ran using [this repo](https://github.com/hashcloak/noir-bigint-bench/). A full benchmark report based on that repo can be found [here](https://docs.google.com/spreadsheets/d/1KBc6mhMZ4iQYIZhsyF8E6-juhob7mM94sBKqVKS-v-8/edit?gid=0#gid=0). 

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

