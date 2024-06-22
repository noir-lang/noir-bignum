# noir-bignum

A big number library for Noir

noir-bignum evaluates modular arithmetic for large integers of any length.

BigNum instances are parametrised by a struct that satisfies BigNumParamsTrait.

bignum can evaluate large integer arithmetic by defining a modulus() that is a power of 2. 

```rust
/**
 * @brief BigNumParamsTrait defines a "field" with which to parametrise BigNum.
**/
trait BigNumParamsTrait<N> {
    /**
     * @brief modulus: all BigNum operations are evaluated modulo this value
     **/
    fn modulus() -> [Field; N];
    /**
     * @brief double_modulus: used when performing negations and subtractions
     **/
    fn double_modulus() -> [Field; N];
    /**
     * @brief redc_param used for __barrett_reduction. See https://en.wikipedia.org/wiki/Barrett_reduction
     **/
    fn redc_param() -> [Field; N];
    /**
     * @brief k used for __barrett_reduction. Should be at least modulus_bits() + 1
     **/
    fn k() -> u64;
    /**
     * @brief modulus_bits = log2(modulus) rounded up
     **/
    fn modulus_bits() -> u64;
}
```

# Usage

Basic expressions can be evaluated using `BigNum::Add, BigNum::Sub, BigNum::Mul`. However, when evaluating relations (up to degree 2) that are more complex than single operations, the function `BigNum::evaluate_quadratic_expression` is more efficient (due to needing only a single modular reduction).

Unconstrained functions `__mulmod, __addmod, __submod, __divmod, __powmod` can be used to compute witnesses that can then be fed into `BigNum::evaluate_quadratic_expression`.

See `bignum_test.nr` for examples.

Note: `__divmod`, `__powmod` and `Div` are expensive due to requiring modular exponentiations during witness computation. It is worth modifying witness generation algorithms to minimize the number of modular exponentiations required. (for example, using batch inverses)