// a modular inversion test
// 
import { expect } from "chai";
import { handle_batch_invert } from "../../nodejs/oracle.js";
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
    
    //first value to invert
    const value1 = [
      "353b7f680023467008c00000000001",
      "32af4d1652ab305a268f2e1bd800ac",
      "0955"
    ];
    //second value to invert
    const value2 = [
      "153b7f680023467008c00000000001",
      "12af4d1652ab305a268f2e1bd800ac",
      "0455"
    ];
    //third value to invert
    const value3 = [
      "253b7f680023467008c00000000001",
      "22af4d1652ab305a268f2e1bd800ac",
      "0855"
    ];


    const input = [
      has_multiplicative_inverse,
      modulus,
      double_modulus, 
      modulus_u60,
      modulus_u60_x4,
      redc_param,
      [value1[0],value1[1],value1[2],
      value2[0],value2[1],value2[2],
      value3[0],value3[1],value3[2]],
      "3",
      "5",
      "3"
    ];

    const result = handle_batch_invert(input);
    // split this array into 3 arrays of length 3
    const result1 = result[0].slice(0, 3);
    const result2 = result[0].slice(3, 6);
    const result3 = result[0].slice(6, 9);
    console.log("this is the result");
    console.log(result);
    
    const mul_input2 = [
        has_multiplicative_inverse, 
        modulus, 
        double_modulus, 
        modulus_u60, 
        modulus_u60_x4, 
        redc_param, 
        value2, 
        result2,
        "3", 
        "5"];

    const mul_result2 = handle_mul_with_quotient(mul_input2);
    expect(mul_result2[1]).to.deep.equal(["1","0","0"]);
    

    const mul_input3 = [
        has_multiplicative_inverse, 
        modulus, 
        double_modulus, 
        modulus_u60, 
        modulus_u60_x4, 
        redc_param, 
        value3, 
        result3,
        "3", 
        "5"];

    const mul_result3 = handle_mul_with_quotient(mul_input3);
    expect(mul_result3[1]).to.deep.equal(["1","0","0"]);
  });
});
