# ed25519 Example

## Testing
Run test:
```
nargo test
```

## Execution
The testvalues are also in the `Prover.toml`. Adjust them to prove with other values. 
Execute the Noir program:
```
nargo execute example1
```
The witness is written to `./target/example1.gz`. 

Prove valid execution (with default Barretenberg backend):
```
bb prove -b ./target/ed25519_example.json -w ./target/example1.gz -o ./target/proof
```
The generated proof will be in `./target/proof`. 

Verify proof by computing the verification key:
```
bb write_vk -b ./target/ed25519_example.json -o ./target/vk
```
.. and then verifying the proof:
```
bb verify -k ./target/vk -p ./target/proof
```
If successful, you see nothing! Otherwise an error will show. 