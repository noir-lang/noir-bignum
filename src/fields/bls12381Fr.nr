use crate::BigNum;
use crate::BigNumParamsTrait;

struct Bls12_381_Fr_Params {}

impl BigNumParamsTrait<3> for Bls12_381_Fr_Params {
    fn redc_param() -> [Field; 3] {
        [ 0x410fad2f92eb5c509cde80830358e4, 0x253b7fb78ddf0e2d772dc1f823b4d9, 0x008d54 ]
    }
    fn modulus() -> [Field; 3] {
        [ 0xbda402fffe5bfeffffffff00000001, 0xa753299d7d483339d80809a1d80553, 0x0073ed ]
    }
    fn double_modulus() -> [Field; 3] {
        [ 0x17b4805fffcb7fdfffffffe00000002, 0x14ea6533afa906673b0101343b00aa6, 0x00e7da ]
    }
    fn k() -> u64 {
        255
    }
    fn modulus_bits() -> u64 {
        255
    }
}
