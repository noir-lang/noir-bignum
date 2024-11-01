# Changelog

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
