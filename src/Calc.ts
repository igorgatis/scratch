export class Calc {
  private display: string = "0";
  private operand: string | null = null;
  private operator: string | null = null;
  private resetDisplay: boolean = false;
  private error: string | null = null;

  handleSequence(sequence: string): void {
    for (const char of sequence) {
      this.handle(char);
    }
  }

  handle(inst: string): void {
    if (this.error && inst !== "c") {
       // Error state logic handled in specific methods or reset by them
    }

    if (/[0-9]/.test(inst)) {
      this.handleDigit(inst);
    } else if (inst === ".") {
      this.handleDot();
    } else if (inst === "c") {
      this.handleClear();
    } else if (inst === "d") {
      this.handleDelete();
    } else if (inst === "s") {
      this.handleSqrt();
    } else if (inst === "t") {
      this.handleToggleSign();
    } else if (["+", "-", "*", "/"].includes(inst)) {
      this.handleOperator(inst);
    } else if (inst === "=") {
      this.handleEqual();
    }
  }

  getLines(): string[] {
    if (this.error) {
        return [this.error];
    }

    const lines: string[] = [];

    // First line: history (operand + operator)
    if (this.operand !== null && this.operator !== null) {
      lines.push(`${this.operand} ${this.operator}`);
    }

    lines.push(this.display);
    return lines;
  }

  private handleDigit(digit: string): void {
    if (this.error) {
        this.error = null;
        this.display = digit;
        this.resetDisplay = false;
        this.operand = null;
        this.operator = null;
        return;
    }

    if (this.resetDisplay) {
      this.display = digit;
      this.resetDisplay = false;
    } else {
      if (this.display === "0") {
        this.display = digit;
      } else {
        this.display += digit;
      }
    }
  }

  private handleDot(): void {
    if (this.error) {
        this.error = null;
        this.display = "0.";
        this.resetDisplay = false;
        this.operand = null;
        this.operator = null;
        return;
    }

    if (this.resetDisplay) {
      this.display = "0.";
      this.resetDisplay = false;
    } else {
      if (!this.display.includes(".")) {
        this.display += ".";
      }
    }
  }

  private handleClear(): void {
    this.display = "0";
    this.operand = null;
    this.operator = null;
    this.resetDisplay = false;
    this.error = null;
  }

  private handleDelete(): void {
    if (this.error) return;

    if (this.resetDisplay) {
        return;
    }

    if (this.display.length > 1) {
      this.display = this.display.slice(0, -1);
    } else {
      this.display = "0";
    }
  }

  private handleSqrt(): void {
    if (this.error) return;

    const val = parseFloat(this.display);
    if (val < 0) {
        this.error = "Error";
        this.resetDisplay = true;
    } else {
        this.display = Math.sqrt(val).toString();
        this.resetDisplay = true;
    }
  }

  private handleToggleSign(): void {
    if (this.error) return;

    const val = parseFloat(this.display);
    this.display = (-val).toString();
  }

  private handleOperator(op: string): void {
    if (this.error) return;

    if (this.operator !== null && !this.resetDisplay) {
        this.calculate();
        if (this.error) return;
    }

    this.operand = this.display;
    this.operator = op;
    this.resetDisplay = true;
  }

  private handleEqual(): void {
    if (this.error) return;

    if (this.operator !== null && this.operand !== null) {
        this.calculate();
        // If calculation caused error, it's set in calculate
        if (!this.error) {
            this.operator = null;
            this.operand = null;
            this.resetDisplay = true;
        }
    }
  }

  private calculate(): void {
    const val1 = parseFloat(this.operand!);
    const val2 = parseFloat(this.display);
    let result = 0;

    switch (this.operator) {
      case "+": result = val1 + val2; break;
      case "-": result = val1 - val2; break;
      case "*": result = val1 * val2; break;
      case "/":
        if (val2 === 0) {
            this.error = "Error";
            this.resetDisplay = true;
            return;
        }
        result = val1 / val2;
        break;
    }

    this.display = result.toString();
  }
}
