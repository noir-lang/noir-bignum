# noir-bignum

An optimized big number library for Noir. Requires noir version >= 0.32.
For barretenberg backend requires bb version at least 0.46.1 (`bbup -v 0.46.1`)

noir-bignum evaluates modular arithmetic for large integers of any length.

BigNum instances are parametrised by a struct that satisfies BigNumParamsTrait.

Multiplication operations for a 2048-bit prime field cost approx. 930 gates.

bignum can evaluate large integer arithmetic by defining a modulus() that is a power of 2.

# Types

bignum operations are evaluated using two structs and a trait: `ParamsTrait`, `BigNum<N, Params>`, `BigNumInstance<N, Params>`

`ParamsTrait` defines the compile-time properties of a BigNum instance: the number of modulus bits and the Barret reduction parameter `k` (TODO: these two values should be the same?!)

`BigNumInstance` is a generator type that is used to create `BigNum` objects and evaluate operations on `BigNum` objects. It wraps BigNum parameters that may not be known at compile time (the `modulus` and a reduction parameter required for Barret reductions (`redc_param`))

The `BigNum` struct represents individual big numbers.

BigNumInstance parameters (`modulus`, `redc_param`) can be provided at runtime via witnesses (e.g. RSA verification). The `redc_param` is only used in unconstrained functions and does not need to be derived from `modulus` in-circuit.

# Usage

Example usage:

```rust
use crate::bignum::fields::bn254Fq::BNParams as BNParams;
use crate::bignum::fields::BN254Instance;

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
instance.evaluate_quadratic_expresson(lhs_terms, lhs_flags, rhs_terms, rhs_flags, linear_terms, linear_flags);
```

# Deriving BNInstance parameters: `modulus`, `redc_param`

For common fields, the intention is that BNInstance parameters do not have to be derived; `BigNum::fields` contains `BigNumInstance` constructors for common fields (if you need a field that is missing, please create an issue).

For other moduli (e.g. those used in RSA verification), both `modulus` and `redc_param` must be computed and formatted according to the following speficiations:

`modulus` represents the BigNum modulus, encoded as an array of `Field` elements that each encode 120 bits of the modulus. The first array element represents the least significant 120 bits.

`redc_param` is equal to `(1 << (2 * Params::modulus_bits())) / modulus` . This must be computed outside of the circuit and provided either as a private witness or hardcoded constant. (computing it via an unconstrained function would be very expensive until noir witness computation times improve)

For example derivations see `https://github.com/noir-lang/noir_rsa`
