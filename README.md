# noir-bignum

An optimized big number library for Noir. Requires noir version >= 0.32.
For barretenberg backend requires bb version at least 0.46.1 (`bbup -v 0.46.1`)

noir-bignum evaluates modular arithmetic for large integers of any length.

BigNum instances are parametrised by a struct that satisfies BigNumParamsTrait.

Multiplication operations for a 2048-bit prime field cost approx. 930 gates.

bignum can evaluate large integer arithmetic by defining a modulus() that is a power of 2.

# Usage

Example usage

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
    let mut lambda_numerator = x.__mulmod(x);
    lambda_numerator = lambda_numerator.__addmod(lambda_numerator.__addmod(lambda_numerator));
    let lambda_denominator = y.__addmod(y);
    let lambda = lambda_numerator / lambda_denominator;
    // x3 = lambda * lambda - x - x
    let x3 = lambda.__mulmod(lambda).__submod(x.__addmod(x));
    // y3 = lambda * (x - x3) - y
    let y3 = lambda.__mulmod(x.__submod(x3)).__submod(y);

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

### `evaluate_quadratic_expression`

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

# BigNum and runtime_bignum::BigNum

BigNum members are represented as arrays of 120-bit limbs. The number of 120-bit limbs required to represent a given BigNum object must be defined at compile-time.

If your field moduli is _also_ known at compile-time, use the `BigNumTrait` definition in `lib.nr`

If your field moduli is _not_ known at compile-time (e.g. RSA verification), use the traits and structs defined in `runtime_bignum`: `runtime_bignum::BigNumTrait` and `runtime_bignum::BigNumInstanceTrait`

A `runtime_bignum::BigNumInstance` wraps the bignum modulus (as well as a derived parameter used internally to perform Barret reductions). A `BigNumInstance` object is required to evaluate most bignum operations.

# runtime_bignum.nr Types

bignum operations are evaluated using two structs and a trait: `ParamsTrait`, `BigNum<N, Params>`, `BigNumInstance<N, Params>`

`ParamsTrait` defines the compile-time properties of a BigNum instance: the number of modulus bits and the Barret reduction parameter `k` (TODO: these two values should be the same?!)

`BigNumInstance` is a generator type that is used to create `BigNum` objects and evaluate operations on `BigNum` objects. It wraps BigNum parameters that may not be known at compile time (the `modulus` and a reduction parameter required for Barret reductions (`redc_param`))

The `BigNum` struct represents individual big numbers.

BigNumInstance parameters (`modulus`, `redc_param`) can be provided at runtime via witnesses (e.g. RSA verification). The `redc_param` is only used in unconstrained functions and does not need to be derived from `modulus` in-circuit.

# Usage (runtime_bignum)

Example usage:

```rust
use crate::bignum::fields::bn254Fq::BNParams;
use crate::bignum::fields::BN254Instance;
use crate::bignum::BigNum;
use crate::bignum::runtime_bignum::BigNumInstance;

type Fq = BigNum<3, BNParams>;
type FqInst = BigNumInstance<3, BNParams>;

fn example(Fq a, Fq b) -> Fq {
    let instance = BN254Instance();
    instance.mul(a, b)
}
```

Basic expressions can be evaluated using `BigNumInstance::add, BigNumInstance::sub, BigNumInstance::mul`. However, when evaluating relations (up to degree 2) that are more complex than single operations, the function `BigNumInstance::evaluate_quadratic_expression` is more efficient (due to needing only a single modular reduction).

Unconstrained functions `__mulmod, __addmod, __submod, __divmod, __powmod` can be used to compute witnesses that can then be fed into `BigNumInstance::evaluate_quadratic_expression`.

See `bignum_test.nr` for examples.

Note: `__divmod`, `__powmod` and `div` are expensive due to requiring modular exponentiations during witness computation. It is worth modifying witness generation algorithms to minimize the number of modular exponentiations required. (for example, using batch inverses)

### Computing witness values

When computing inputs to `evaluate_quadratic_expresson` , unconstrained functions `__addmod`, `__submod`, `__mulmod`, `__divmod` can be used to compute witness values.

e.g. if we wanted to compute `(a + b) * c + (d - e) * f = g` by evaluating the above example, `g` can be derived via:

```
let bn: BigNumInstance<3, BNParams> = BNInstance();
let t0 = bn.__mulmod(bn.__addmod(a, b), c);
let t1 = bn.__mulmod(bn.__addmod(d, bn.__neg(e)), f);
let g = bn.__addmod(t0, t1);
```

# Deriving BNInstance parameters: `modulus`, `redc_param`

For common fields, the intention is that BNInstance parameters do not have to be derived; `BigNum::fields` contains `BigNumInstance` constructors for common fields (if you need a field that is missing, please create an issue).

For other moduli (e.g. those used in RSA verification), both `modulus` and `redc_param` must be computed and formatted according to the following speficiations:

`modulus` represents the BigNum modulus, encoded as an array of `Field` elements that each encode 120 bits of the modulus. The first array element represents the least significant 120 bits.

`redc_param` is equal to `(1 << (2 * Params::modulus_bits())) / modulus` . This must be computed outside of the circuit and provided either as a private witness or hardcoded constant. (computing it via an unconstrained function would be very expensive until noir witness computation times improve)

`double_modulus` is derived via the method `compute_double_modulus` in `runtime_bignum.nr`. If you want to provide this value as a compile-time constant (see `fields/bn254Fq.nr` for an example), follow the algorithm `compute_double_modulus` as this parameter is _not_ structly 2 \* modulus. Each limb except the most significant limb borrows 2^120 from the next most significant limb. This ensure that when performing limb subtractions `double_modulus.limbs[i] - x.limbs[i]`, we know that the result will not underflow.

For example derivations see `https://github.com/noir-lang/noir_rsa`
