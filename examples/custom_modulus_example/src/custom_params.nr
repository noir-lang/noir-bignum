use dep::bignum::BigNum;
use dep::bignum::BigNumParamsTrait;
use dep::bignum::runtime_bignum::BigNumInstance;
use dep::bignum::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;
use dep::bignum::utils::u60_representation::U60Repr;
use dep::bignum::utils::arrayX::ArrayX;

struct RSA2048_example_Params {}
impl RuntimeBigNumParamsTrait<18> for RSA2048_example_Params {
    fn modulus_bits() -> u32 {
        2048
    }
    fn has_multiplicative_inverse() -> bool { false }
}
impl BigNumParamsTrait<18> for RSA2048_example_Params {
    fn get_instance() -> BigNumInstance<18, Self> {
        RSA2048_example_Instance
    }
    fn modulus_bits() -> u32 {
        2048
    }
    fn has_multiplicative_inverse() -> bool { false }
}
global RSA2048_example_Instance: BigNumInstance<18, RSA2048_example_Params> = BigNumInstance {
        modulus: [
            0xca067270cbaa2f334deca1472a2bf3, 0x6610de1958b4206e3e34a14af22618, 0xe59e76000fcfb05956e5503a499841, 0x3d429c951fdec78afafacd2381782c, 0x617806aa0cf2d15b8c2a41bfd38ed9, 0xa4a58ff8737791b2d5571ea75c92d3, 0x49f85ae321bfbc161162bc1034f586, 0xa40bf68ca724dff0cf63605975cf48, 0xd5c5fe2ab9a1adf232351085a7d591, 0x1b0d1c9077b8f0794b2cb4af4d294f, 0x9401a841ae63b1f566fd6b69e62ccd, 0xd6958bad7bcf453c6cb489538831e0, 0x51bdf4c4cd4c92887a1d178d6bc3ce, 0xd153e9c43d7aa9b0d7a2c1af84ea38, 0x9deb9b61f4e25c1bd0d53e4e0e61e1, 0xbed33da20e52d7c916d486f235202b, 0x0c541718be73e9ce00f430c086b205, 0xa2
        ],
        double_modulus: [
            0x01940ce4e197545e669bd9428e5457e6, 0x01cc21bc32b16840dc7c694295e44c30, 0x01cb3cec001f9f60b2adcaa074933081, 0x017a85392a3fbd8f15f5f59a4702f058, 0x01c2f00d5419e5a2b71854837fa71db1, 0x01494b1ff0e6ef2365aaae3d4eb925a5, 0x0193f0b5c6437f782c22c5782069eb0c, 0x014817ed194e49bfe19ec6c0b2eb9e8f, 0x01ab8bfc5573435be4646a210b4fab22, 0x01361a3920ef71e0f29659695e9a529e, 0x01280350835cc763eacdfad6d3cc5999, 0x01ad2b175af79e8a78d96912a71063c0, 0x01a37be9899a992510f43a2f1ad7879c, 0x01a2a7d3887af55361af45835f09d46f, 0x013bd736c3e9c4b837a1aa7c9c1cc3c2, 0x017da67b441ca5af922da90de46a4056, 0x0118a82e317ce7d39c01e861810d640a, 0x0143
        ],
        modulus_u60: U60Repr { limbs: ArrayX { segments: [[
            0x034deca1472a2bf3, 0x0ca067270cbaa2f3, 0x0e3e34a14af22618, 0x06610de1958b4206, 0x0956e5503a499841, 0x0e59e76000fcfb05, 0x0afafacd2381782c, 0x03d429c951fdec78, 0x0b8c2a41bfd38ed9, 0x0617806aa0cf2d15, 0x02d5571ea75c92d3, 0x0a4a58ff8737791b, 0x061162bc1034f586, 0x049f85ae321bfbc1, 0xcf63605975cf48, 0x0a40bf68ca724dff, 0x0232351085a7d591, 0x0d5c5fe2ab9a1adf], [0x094b2cb4af4d294f, 0x01b0d1c9077b8f07, 0x0566fd6b69e62ccd, 0x09401a841ae63b1f, 0x0c6cb489538831e0, 0x0d6958bad7bcf453, 0x087a1d178d6bc3ce, 0x051bdf4c4cd4c928, 0xd7a2c1af84ea38, 0x0d153e9c43d7aa9b, 0x0bd0d53e4e0e61e1, 0x09deb9b61f4e25c1, 0x0916d486f235202b, 0x0bed33da20e52d7c, 0x0e00f430c086b205, 0xc541718be73e9c, 0xa2, 0x00]] } },
        modulus_u60_x4: U60Repr { limbs: ArrayX { segments: [[
            0x034deca1472a2bf3, 0x0ca067270cbaa2f3, 0x0e3e34a14af22618, 0x06610de1958b4206, 0x0956e5503a499841, 0x0e59e76000fcfb05, 0x0afafacd2381782c, 0x03d429c951fdec78, 0x0b8c2a41bfd38ed9, 0x0617806aa0cf2d15, 0x02d5571ea75c92d3, 0x0a4a58ff8737791b, 0x061162bc1034f586, 0x049f85ae321bfbc1, 0xcf63605975cf48, 0x0a40bf68ca724dff, 0x0232351085a7d591, 0x0d5c5fe2ab9a1adf], [0x094b2cb4af4d294f, 0x01b0d1c9077b8f07, 0x0566fd6b69e62ccd, 0x09401a841ae63b1f, 0x0c6cb489538831e0, 0x0d6958bad7bcf453, 0x087a1d178d6bc3ce, 0x051bdf4c4cd4c928, 0xd7a2c1af84ea38, 0x0d153e9c43d7aa9b, 0x0bd0d53e4e0e61e1, 0x09deb9b61f4e25c1, 0x0916d486f235202b, 0x0bed33da20e52d7c, 0x0e00f430c086b205, 0xc541718be73e9c, 0xa2, 0x00], [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]] } },
        redc_param: [
            0x1fdcdafc0b4a1e7e76fea4d047f13c, 0xe9f3127f19f73583a5378c5e3fb4a4, 0x61d4721841efbeac85a785dd48b58e, 0x747ed55336a2218c1f011c5f730478, 0xf8e29e2ca49c4df7aa57cc4defb877, 0x67541ffb558ce4fea6409c61e5b96a, 0xc616b60523693e15226453d9c1a735, 0x8e609df55b7e417c40ec232ac85f2c, 0xec4a3a8702ea1a8836d5bf2d63dc4c, 0x73ee26edb819fac7c1a771ed2d2447, 0x84e660e9c009e0eadd88a0c2d957c5, 0xb9c718c32762b643b6c29606ea3766, 0x9077b6f87aa1ba000b853a4841ea29, 0x28e68f0218123e2f911bfe4f2afdb1, 0xc45f6a9c6e8f5c18e38415b847eba6, 0xfd74428019998d5f69bda9954cd6d4, 0x6c48d17d943d2d123a0cb7f1044254, 0x0194
        ]
};

