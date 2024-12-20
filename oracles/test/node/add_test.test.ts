import { expect } from "chai";
import { handle_add } from "../../nodejs/oracle.js";

describe("add oracle function", () => {
  it("should correctly add two values", () => {
    // the inputs to handle_add are params = [has_m_inv, modulus, double_modulus, modulus_u60, modulus_u60_x4, redc_param],
    // lhs , rhs
    const has_multiplicative_inverse = "1";
    const modulus = [
      "aa76fed00000010a11800000000001",
      "655e9a2ca55660b44d1e5c37b00159",
      "12ab",
    ];
    const double_modulus = [ "0","0","0"];
    const modulus_u60 = ["0","0","0"];
    const modulus_u60_x4 = [
      "0",
      "0",
      "0",
    ];

    const redc_param = ["0","0","0"];
    const lhs = ["aa76fed00000010a11800000000000",
      "655e9a2ca55660b44d1e5c37b00159",
      "12ab",]; 
    const rhs = ["1","0","0"];
    const exp_res = ["0","0","0"];
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
     "5",
    ];
    var result = handle_add(input);
    expect(result[0]).to.deep.equal(exp_res);
  });

  //   it('should correctly identify non-zero inputs', () => {
  //     const inputs = ['1', '2', '3'];
  //   });
});
