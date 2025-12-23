import { describe, it, expect, beforeEach } from "bun:test";
import { Calc } from "./Calc";

describe("Calc", () => {
  let calc: Calc;

  beforeEach(() => {
    calc = new Calc();
  });

  it("should start with 0", () => {
    expect(calc.getLines()).toEqual(["0"]);
  });

  it("should handle digits", () => {
    calc.handleSequence("12");
    expect(calc.getLines()).toEqual(["12"]);
  });

  it("should handle addition", () => {
    calc.handleSequence("1+");
    expect(calc.getLines()).toEqual(["1 +", "1"]);
    calc.handle("2");
    expect(calc.getLines()).toEqual(["1 +", "2"]);
    calc.handle("=");
    expect(calc.getLines()).toEqual(["3"]);
  });

  it("should handle chained addition", () => {
    calc.handleSequence("1+2+"); // Should calc 1+2=3, set 3 as operand, + as operator
    expect(calc.getLines()).toEqual(["3 +", "3"]);
    calc.handleSequence("3=");
    expect(calc.getLines()).toEqual(["6"]);
  });

  it("should handle decimal", () => {
    calc.handleSequence("1.5");
    expect(calc.getLines()).toEqual(["1.5"]);
  });

  it("should ignore multiple decimals", () => {
    calc.handleSequence("1.5.");
    expect(calc.getLines()).toEqual(["1.5"]);
  });

  it("should handle clear", () => {
    calc.handleSequence("1+c");
    expect(calc.getLines()).toEqual(["0"]);
  });

  it("should handle delete", () => {
    calc.handleSequence("12d");
    expect(calc.getLines()).toEqual(["1"]);
    calc.handle("d");
    expect(calc.getLines()).toEqual(["0"]);
  });

  it("should handle sqrt", () => {
    calc.handleSequence("9s");
    expect(calc.getLines()).toEqual(["3"]);
  });

  it("should handle toggle sign", () => {
    calc.handleSequence("5t");
    expect(calc.getLines()).toEqual(["-5"]);
    calc.handle("t");
    expect(calc.getLines()).toEqual(["5"]);
  });

  it("should handle operator change", () => {
    calc.handleSequence("5+*"); // Change + to *
    expect(calc.getLines()).toEqual(["5 *", "5"]);
    calc.handleSequence("2=");
    expect(calc.getLines()).toEqual(["10"]);
  });
});
