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
    calc.handle("1");
    calc.handle("2");
    expect(calc.getLines()).toEqual(["12"]);
  });

  it("should handle addition", () => {
    calc.handle("1");
    calc.handle("+");
    expect(calc.getLines()).toEqual(["1 +", "1"]);
    calc.handle("2");
    expect(calc.getLines()).toEqual(["1 +", "2"]);
    calc.handle("=");
    expect(calc.getLines()).toEqual(["3"]);
  });

  it("should handle chained addition", () => {
    calc.handle("1");
    calc.handle("+");
    calc.handle("2");
    calc.handle("+"); // Should calc 1+2=3, set 3 as operand, + as operator
    expect(calc.getLines()).toEqual(["3 +", "3"]);
    calc.handle("3");
    calc.handle("=");
    expect(calc.getLines()).toEqual(["6"]);
  });

  it("should handle decimal", () => {
    calc.handle("1");
    calc.handle(".");
    calc.handle("5");
    expect(calc.getLines()).toEqual(["1.5"]);
  });

  it("should ignore multiple decimals", () => {
    calc.handle("1");
    calc.handle(".");
    calc.handle("5");
    calc.handle(".");
    expect(calc.getLines()).toEqual(["1.5"]);
  });

  it("should handle clear", () => {
    calc.handle("1");
    calc.handle("+");
    calc.handle("c");
    expect(calc.getLines()).toEqual(["0"]);
  });

  it("should handle delete", () => {
    calc.handle("1");
    calc.handle("2");
    calc.handle("d");
    expect(calc.getLines()).toEqual(["1"]);
    calc.handle("d");
    expect(calc.getLines()).toEqual(["0"]);
  });

  it("should handle sqrt", () => {
    calc.handle("9");
    calc.handle("s");
    expect(calc.getLines()).toEqual(["3"]);
  });

  it("should handle toggle sign", () => {
    calc.handle("5");
    calc.handle("t");
    expect(calc.getLines()).toEqual(["-5"]);
    calc.handle("t");
    expect(calc.getLines()).toEqual(["5"]);
  });

  it("should handle operator change", () => {
    calc.handle("5");
    calc.handle("+");
    calc.handle("*"); // Change + to *
    expect(calc.getLines()).toEqual(["5 *", "5"]);
    calc.handle("2");
    calc.handle("=");
    expect(calc.getLines()).toEqual(["10"]);
  });
});
