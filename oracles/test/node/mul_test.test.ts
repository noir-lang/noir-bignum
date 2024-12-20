// a test that checks the mul_with_quotient oracle function
// 
import { expect } from "chai";
import { handle_mul_with_quotient } from "../../nodejs/oracle.js";

describe("mul_with_quotient oracle function", () => {
  it("should correctly multiply two values and return quotient and remainder", () => {
    const has_multiplicative_inverse = "1";
    const modulus = [
      "aa76fed00000010a11800000000001",
      "655e9a2ca55660b44d1e5c37b00159",
      "12ab"
    ];
    const double_modulus = ["0","0","0"];
    const modulus_u60 = ["0","0","0"];
    const modulus_u60_x4 = ["0","0","0"];
    const redc_param = ["0","0","0"];
    
    const lhs = ["fdb69ab55a04031aef326c9d04692d", "1eb22a447ccfeed098256a87385bea", "2cf"]; 
    const rhs = ["e8e9c353306ab9b0169ffc645b4fe4", "c4f0ebfbf6f6b6482e4f767df7dac6", "fbe"];
    const expected_remainder = ["1dc50c4b2ab8d4eee01ae8228c72e2", "d74fcac3665ed41507d75f4e76f859", "110f"];
    const expected_quotient = ["dbd233e6638ac01ec7573b08d51c32", "7acaefb7fe1ce5373daedc27f13db8", "25e"];

    
    const input = [
      has_multiplicative_inverse,
      modulus,
      double_modulus,
      modulus_u60,
      modulus_u60_x4,
      redc_param,
      lhs,
      rhs,
      "3",
      "5"
    ];

    const result = handle_mul_with_quotient(input);
    expect(result[0]).to.deep.equal(expected_quotient);
    expect(result[1]).to.deep.equal(expected_remainder);
  });
});
