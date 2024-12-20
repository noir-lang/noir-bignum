// a division test
// 
import { expect } from "chai";
import { handle_div } from "../../nodejs/oracle.js";

describe("div oracle function", () => {
  it("should correctly divide two values", () => {
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
    
    // Numerator = 10
    const numerator = [
      "a",
      "655e9a2ca55660b44d1e5c37b00159",
      "0"
    ];
    
    // Denominator = 2 
    const denominator = [
      "1",
      "0", 
      "0"
    ];

    // Expected result = 5
    const expected_result = [
      "a",
      "655e9a2ca55660b44d1e5c37b00159",
      "0"  
    ];

    const input = [
      has_multiplicative_inverse,
      modulus,
      double_modulus,
      modulus_u60,
      modulus_u60_x4,
      redc_param,
      numerator,
      denominator,
      "3",
      "5"
    ];

    const result = handle_div(input);
    expect(result[0]).to.deep.equal(expected_result);
  });
});
