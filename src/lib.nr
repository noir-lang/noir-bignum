// BigNum
pub mod bignum;

// RuntimeBigNum
pub mod runtime_bignum;

// Pre-defined fields and bignums for people to use:
pub mod fields;

// Structs enabling people to define their own bignum params
pub mod params;

// Free functions and other utils, called by the BigNum and RuntimeBigNum structs
pub(crate) mod fns;
pub(crate) mod utils;

// Re-export the main structs so that users don't have to specify the paths
pub use bignum::BigNum;
pub use bignum::BigNumTrait; // So that external code can operate on a generic BigNum, `where BigNum: BigNumTrait`.
pub use runtime_bignum::RuntimeBigNum;

// Tests
mod tests;
