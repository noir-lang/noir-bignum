# Changelog

## [0.5.4](https://github.com/noir-lang/noir-bignum/compare/v0.5.3...v0.5.4) (2025-02-08)


### Bug Fixes

* Correct batch inversion implementation ([#121](https://github.com/noir-lang/noir-bignum/issues/121)) ([399d21a](https://github.com/noir-lang/noir-bignum/commit/399d21adb6786ad0ce2b670e8b216faf1f8a3fc2))

## [0.5.3](https://github.com/noir-lang/noir-bignum/compare/v0.5.2...v0.5.3) (2025-02-03)


### Bug Fixes

* Correct batch inversion function ([#117](https://github.com/noir-lang/noir-bignum/issues/117)) ([976d3ef](https://github.com/noir-lang/noir-bignum/commit/976d3efd392fc12d95256624e82f5c826e98ab82))

## [0.5.2](https://github.com/noir-lang/noir-bignum/compare/v0.5.1...v0.5.2) (2025-01-29)


### Features

* Add `is_zero` ([#111](https://github.com/noir-lang/noir-bignum/issues/111)) ([2ca1383](https://github.com/noir-lang/noir-bignum/commit/2ca1383238b927d11fc12c48c618475172c0a677))
* Implement `Default` trait on `BigNum` ([#109](https://github.com/noir-lang/noir-bignum/issues/109)) ([e56352a](https://github.com/noir-lang/noir-bignum/commit/e56352a05c3cb8620076dd9e0453ef9b20974315))


### Bug Fixes

* Constrain `split_60_bits` function ([#113](https://github.com/noir-lang/noir-bignum/issues/113)) ([0d19e5a](https://github.com/noir-lang/noir-bignum/commit/0d19e5a34dbfa91e9f7c2eedb3e51b034ecd75d7))

## [0.5.1](https://github.com/noir-lang/noir-bignum/compare/v0.5.0...v0.5.1) (2025-01-27)


### Features

* Add zero constructor ([#108](https://github.com/noir-lang/noir-bignum/issues/108)) ([c6466ef](https://github.com/noir-lang/noir-bignum/commit/c6466ef6c831d6ecd12dbc9e921b822319f7e4a8))
* Added `to_field` function ([#99](https://github.com/noir-lang/noir-bignum/issues/99)) ([7c92c22](https://github.com/noir-lang/noir-bignum/commit/7c92c22d35bb2f4199d53b32dd339d6b9142bb0d))
* Constrain ops only in constrained context ([#102](https://github.com/noir-lang/noir-bignum/issues/102)) ([b3000e1](https://github.com/noir-lang/noir-bignum/commit/b3000e17c4f057be85cf36e56816ea77b719e5f2))
* Deprecate `BigNum::new()` ([#110](https://github.com/noir-lang/noir-bignum/issues/110)) ([ce3c654](https://github.com/noir-lang/noir-bignum/commit/ce3c654a077f2b5c96f53610123f9321fcd11089))
* Implement `From&lt;Field&gt;` on `BigNum` ([#87](https://github.com/noir-lang/noir-bignum/issues/87)) ([35bf983](https://github.com/noir-lang/noir-bignum/commit/35bf983bdf80abbb2f191dd6c464a6fe3516f9c2))
* Minor unconstrained bytecode optimizations ([#79](https://github.com/noir-lang/noir-bignum/issues/79)) ([b44ef7f](https://github.com/noir-lang/noir-bignum/commit/b44ef7f6bee56751e2d83848e84accf25e0bdc0f))
* Remove unnecessary usage of slices ([#104](https://github.com/noir-lang/noir-bignum/issues/104)) ([fb6f9e5](https://github.com/noir-lang/noir-bignum/commit/fb6f9e5982dda8729d6b12ef83ad3ef60cdf0b7e))

## [0.5.0](https://github.com/noir-lang/noir-bignum/compare/v0.4.2...v0.5.0) (2025-01-06)


### ⚠ BREAKING CHANGES

* remove redefinition of arithmetic methods on `BigNumTrait` ([#84](https://github.com/noir-lang/noir-bignum/issues/84))

### Features

* Remove redefinition of arithmetic methods on `BigNumTrait` ([#84](https://github.com/noir-lang/noir-bignum/issues/84)) ([b5c6ce2](https://github.com/noir-lang/noir-bignum/commit/b5c6ce20d8a5705127f3b0c33a17e77750fc91c2))

## [0.4.2](https://github.com/noir-lang/noir-bignum/compare/v0.4.1...v0.4.2) (2024-11-15)


### Bug Fixes

* Constraint count regression introduced in commit 53f652b  ([#53](https://github.com/noir-lang/noir-bignum/issues/53)) ([d81d5fa](https://github.com/noir-lang/noir-bignum/commit/d81d5fac5e2ea919bd93e513644d0edc5630261c))

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
