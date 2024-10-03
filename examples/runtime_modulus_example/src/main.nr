use dep::bignum::{BigNum, BigNumParamsTrait};
use dep::bignum::runtime_bignum::{BigNumTrait, BigNumInstanceTrait, BigNumParamsTrait as RuntimeBigNumParamsTrait};
use dep::bignum::runtime_bignum::BigNumInstance;
use dep::bignum::utils::u60_representation::U60Repr;
use dep::bignum::utils::arrayX::ArrayX;

struct RSA1024Params {}
impl RuntimeBigNumParamsTrait<9> for RSA1024Params {
    fn modulus_bits() -> u32 {
        1024
    }
    fn has_multiplicative_inverse() -> bool { false }
}

type RSA1024 = BigNum<9, RSA1024Params>;
type RSA1024Instance = BigNumInstance<9, RSA1024Params>;

fn main(modulus: [Field; 9], redc_param: [Field; 9], a: RSA1024, b: RSA1024, expected: RSA1024) {
    let BNInstance: RSA1024Instance = BigNumInstance::new(modulus, redc_param);

    let c = BNInstance.add(a, b);
    assert(BNInstance.eq(expected, c));
}

#[test]
fn test_add() {
    let mut a: RSA1024 = BigNum::new();
    a.limbs[0] = 10;
    let mut b: RSA1024 = BigNum::new();
    b.limbs[0] = 20;

    let mut expected: RSA1024 = BigNum::new();
    expected.limbs[0] = 30;

    let modulus = [
        0xca067270cbaa2f334deca1472a3e31, 0x6610de1958b4206e3e34a14af22618, 0xe59e76000fcfb05956e5503a499841, 0x3d429c951fdec78afafacd2381782c, 0x617806aa0cf2d15b8c2a41bfd38ed9, 0xa5bd5539ec839696d39cf8dfdd92d3, 0xe9bed0c391a2d4050d6d2367c6a943, 0x2d2150ff6bb93bf3a7d1163587d488, 0x852ed0ee51bf01f3
    ];
    let redc_param = [
        0xb6b68cb415434ea6273830091e7ba4, 0x9da115c204677051818a8c033cbc85, 0x8cb24ce7044f7c1fe2cd6d5425e397, 0x478c0c53482aacf0b50d3649c1b096, 0xc7b7c730e69ec6b458f1ea2faf1c28, 0x6b733155f8756e0d0cc2bce80185da, 0xf34103a45581aa68206e1aac5ecdca, 0x59c9f258f9e3905b9629a277b6752f, 0x01ec13452bee67c5dc
    ];
    main(modulus, redc_param, a, b, expected);
}
