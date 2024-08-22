# Runtime modulus example

## Create program

As explained in the general BigNum README, for a runtime modulus a `BigNumInstance` either has to be passed into the program or generated using the `modulus` and `redc_param`. In this example we'll do the latter.

This is an example assuming RSA for a modulus of 1024 bits.

At compile-time we know the number of bits of the modulus and can define the types:
```rust
struct RSA1024Params {}
impl RuntimeBigNumParamsTrait<9> for RSA1024Params {
    fn modulus_bits() -> u32 {
        1024
    }
    fn has_multiplicative_inverse() -> bool { false }
}

type RSA1024 = BigNum<9, RSA1024Params>;
type RSA1024Instance = BigNumInstance<9, RSA1024Params>;
```

The `main` function expects the `modulus` and `redc_param` in order to generate the `BigNumInstance` and consequently use it to perform arithmetic operations.

```rust
fn main(modulus: [Field; 9], redc_param: [Field; 9], a: RSA1024, b: RSA1024, expected: RSA1024) {
    let BNInstance: RSA1024Instance = BigNumInstance::new(modulus, redc_param);

    let c = BNInstance.add(a, b);
    assert(BNInstance.eq(expected, c));
}
```

## Test program

The test defines `modulus` and `redc_param`, which have been obtained using [this tool](https://github.com/noir-lang/noir-bignum-paramgen). To run the test:
```
nargo test
```

## Execute, prove & verify program

The testvalues are also in the `Prover.toml`. Adjust them to prove with other values. 
Execute the Noir program:
```
nargo execute example2
```
The witness is written to `./target/example2.gz`. 

Prove valid execution (with default Barretenberg backend):
```
bb prove -b ./target/custom_modulus_example.json -w ./target/example2.gz -o ./target/proof
```
The generated proof will be in `./target/proof`. 

Verify proof by computing the verification key:
```
bb write_vk -b ./target/custom_modulus_example.json -o ./target/vk
```
.. and then verifying the proof:
```
bb verify -k ./target/vk -p ./target/proof
```
If successful, you see nothing! Otherwise an error will show. 