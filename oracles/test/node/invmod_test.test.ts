// a modular inversion test
// 
import { expect } from "chai";
import { handle_invmod } from "../../nodejs/oracle.js";
import { handle_mul_with_quotient } from "../../nodejs/oracle.js";
describe("invmod oracle function", () => {
  it("should correctly compute modular inverse", () => {
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
    
    // Value to invert = 2
    const value = [
      "353b7f680023467008c00000000001",
      "32af4d1652ab305a268f2e1bd800ac",
      "0955"
    ];


    const input = [
      has_multiplicative_inverse,
      modulus,
      double_modulus, 
      modulus_u60,
      modulus_u60_x4,
      redc_param,
      value,
      "3",
      "5"
    ];

    const result = handle_invmod(input);

    const mul_input = [
        has_multiplicative_inverse, 
        modulus, 
        double_modulus, 
        modulus_u60, 
        modulus_u60_x4, 
        redc_param, 
        value, 
        result[0],
        "3", 
        "5"];

    const mul_result = handle_mul_with_quotient(mul_input);
    expect(mul_result[1]).to.deep.equal(["1","0","0"]);
  });
});
