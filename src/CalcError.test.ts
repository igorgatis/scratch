import { describe, it, expect, beforeEach } from "bun:test";
import { Calc } from "./Calc";

describe("Calc Error Handling", () => {
  let calc: Calc;

  beforeEach(() => {
    calc = new Calc();
  });

  it("should show error on division by zero", () => {
    calc.handleSequence("1/0=");
    expect(calc.getLines()).toEqual(["Error"]);
  });

  it("should recover from error on clear", () => {
    calc.handleSequence("1/0=c");
    expect(calc.getLines()).toEqual(["0"]);
  });

  it("should recover from error on new digit", () => {
    calc.handleSequence("1/0=");
    expect(calc.getLines()).toEqual(["Error"]);
    calc.handle("5");
    expect(calc.getLines()).toEqual(["5"]);
  });

  it("should show error on invalid sqrt", () => {
    calc.handleSequence("9t"); // -9
    expect(calc.getLines()).toEqual(["-9"]);
    calc.handle("s");
    expect(calc.getLines()).toEqual(["Error"]);
  });
});
