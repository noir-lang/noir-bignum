import { expect } from "chai";
import { handle_is_zero } from "../../nodejs/oracle.js";

describe("is_zero oracle function", () => {
  it("should correctly identify zero inputs", () => {
    const inputs = ["0", "0", "0"];
    const result = handle_is_zero(inputs);
    expect(result).to.deep.equal(["1"]);
  });

  it("should correctly identify non-zero inputs", () => {
    const inputs = ["1", "2", "3"];
    const result = handle_is_zero(inputs);
    expect(result).to.deep.equal(["0"]);
  });
});
