# Changelog

## [0.4.1](https://github.com/noir-lang/noir-bignum/compare/v0.4.0...v0.4.1) (2024-11-08)


### Features

* Optimize brillig execution of `split_X_bits` functions ([#47](https://github.com/noir-lang/noir-bignum/issues/47)) ([31ebc7c](https://github.com/noir-lang/noir-bignum/commit/31ebc7cc03a7d8be4aef90a632515f79e3405c7a))
* Remove a bunch of unnecessary bytecode from unconstrained ops ([#50](https://github.com/noir-lang/noir-bignum/issues/50)) ([08c4151](https://github.com/noir-lang/noir-bignum/commit/08c4151f12cc4fe1831da2eba6c854948a17c3d8))
* Remove generic parameter from the `BigNum` trait ([#44](https://github.com/noir-lang/noir-bignum/issues/44)) ([53f652b](https://github.com/noir-lang/noir-bignum/commit/53f652b443967b589ae5ee3b3c9bdba5d3606806))


### Bug Fixes

* Check that `RuntimeBigNum`s have the same `BigNumParams` on operations ([#46](https://github.com/noir-lang/noir-bignum/issues/46)) ([729dd24](https://github.com/noir-lang/noir-bignum/commit/729dd244e07a17b4c5f4d24fcd63caae91e8d645))
* Fix barrett reduction bug ([#51](https://github.com/noir-lang/noir-bignum/issues/51)) ([c61a621](https://github.com/noir-lang/noir-bignum/commit/c61a621745fb6a6c3778fbee35344bc7cf79f6a9))
* Fix broken tests in `runtime_bignum_test.nr` ([#39](https://github.com/noir-lang/noir-bignum/issues/39)) ([63e6c85](https://github.com/noir-lang/noir-bignum/commit/63e6c851712ff3492d0b538437d3ddb0c6aacc1e))

## [0.4.0](https://github.com/noir-lang/noir-bignum/compare/v0.3.5...v0.4.0) (2024-11-01)


### ⚠ BREAKING CHANGES

* refactor library architecture ([#36](https://github.com/noir-lang/noir-bignum/issues/36))
* bump minimum noir version to 0.35.0 and address privacy warnings #24

### Features

* Added modular square root computation and fully constrained `derive_from_seed` method ([#32](https://github.com/noir-lang/noir-bignum/issues/32)) ([20e03b0](https://github.com/noir-lang/noir-bignum/commit/20e03b04f7e2c57b61538d707695ae02979c51b4))
* Refactor library architecture ([#36](https://github.com/noir-lang/noir-bignum/issues/36)) ([4fa65f6](https://github.com/noir-lang/noir-bignum/commit/4fa65f6be596ea1b6c6c49b784fa7a9aca95c5d4))


### Bug Fixes

* Bump minimum noir version to 0.35.0 and address privacy warnings [#24](https://github.com/noir-lang/noir-bignum/issues/24) ([fc53098](https://github.com/noir-lang/noir-bignum/commit/fc53098332e1843759114ad7c05118e8fee141ed))
* Fixed reduction parameter error ([#31](https://github.com/noir-lang/noir-bignum/issues/31)) ([c312ef7](https://github.com/noir-lang/noir-bignum/commit/c312ef72e2127153fad5afcffc5bf88045a5b4ba))
* Remove unnecessary generic ([#42](https://github.com/noir-lang/noir-bignum/issues/42)) ([1eb64aa](https://github.com/noir-lang/noir-bignum/commit/1eb64aab691e96d143775183987e7dfc2132bdc3))

## [0.3.5](https://github.com/noir-lang/noir-bignum/compare/v0.3.4...v0.3.5) (2024-10-02)


### Features

* Bignum uses generic arithmetic instead of clunky ArrayX struct ([#17](https://github.com/noir-lang/noir-bignum/issues/17)) ([08f5710](https://github.com/noir-lang/noir-bignum/commit/08f5710e085e55c038b8555032c90a31d7c91037))
