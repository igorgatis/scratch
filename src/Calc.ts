export class Calc {
  private display: string = "0";
  private operand: number | null = null;
  private operator: string | null = null;
  private shouldResetDisplay: boolean = false;

  handle(inst: string): void {
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
    const lines: string[] = [];

    // First line: history (operand + operator)
    if (this.operand !== null && this.operator !== null) {
      lines.push(`${this.operand} ${this.operator}`);
    } else {
       // If just a number, maybe empty first line?
       // User says "pode retornar 1 ou 2 linhas".
       // If I return just one line ["123"], it's valid.
    }

    // Second line: current display
    // However, if we want to show consistent UI, maybe just return what we have.
    // Let's return just the display if no history.
    if (lines.length === 0) {
      return [this.display];
    }

    lines.push(this.display);
    return lines;
  }

  private handleDigit(digit: string): void {
    if (this.shouldResetDisplay) {
      this.display = digit;
      this.shouldResetDisplay = false;
    } else {
      if (this.display === "0") {
        this.display = digit;
      } else {
        this.display += digit;
      }
    }
  }

  private handleDot(): void {
    if (this.shouldResetDisplay) {
      this.display = "0.";
      this.shouldResetDisplay = false;
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
    this.shouldResetDisplay = false;
  }

  private handleDelete(): void {
    if (this.shouldResetDisplay) {
        // If we just finished a calc or pressed an operator, 'd' usually does nothing or resets to 0?
        // Let's assume it works on the displayed number but doesn't exit "reset mode" until a digit is pressed?
        // Actually standard calculator: if you have a result, backspace does nothing or clears it.
        // Let's make it clear the display if it's a result, or do nothing.
        // For simplicity: if waiting for new number, do nothing.
        return;
    }

    if (this.display.length > 1) {
      this.display = this.display.slice(0, -1);
    } else {
      this.display = "0";
    }
  }

  private handleSqrt(): void {
    const val = parseFloat(this.display);
    if (val < 0) {
        this.display = "Error";
        this.shouldResetDisplay = true;
    } else {
        this.display = Math.sqrt(val).toString();
        // After an immediate operation like sqrt, usually we are ready to operate on it,
        // but if we type a digit, it should probably replace it?
        this.shouldResetDisplay = true;
    }
  }

  private handleToggleSign(): void {
    const val = parseFloat(this.display);
    this.display = (-val).toString();
    // Do NOT set shouldResetDisplay here, usually we want to keep editing or using this number.
  }

  private handleOperator(op: string): void {
    if (this.operator !== null && !this.shouldResetDisplay) {
        // We have `operand op display`. Calculate it first.
        this.calculate();
    }

    this.operand = parseFloat(this.display);
    this.operator = op;
    this.shouldResetDisplay = true;
  }

  private handleEqual(): void {
    if (this.operator !== null && this.operand !== null) {
        this.calculate();
        this.operator = null;
        this.operand = null;
        this.shouldResetDisplay = true;
    }
  }

  private calculate(): void {
    const val1 = this.operand!;
    const val2 = parseFloat(this.display);
    let result = 0;

    switch (this.operator) {
      case "+": result = val1 + val2; break;
      case "-": result = val1 - val2; break;
      case "*": result = val1 * val2; break;
      case "/":
        if (val2 === 0) {
            this.display = "Error";
            this.shouldResetDisplay = true;
            return;
        }
        result = val1 / val2;
        break;
    }

    // Handle floating point precision issues?
    // e.g. 0.1 + 0.2 = 0.30000000000000004
    // The user didn't ask for it, but it's nice.
    // For now I'll stick to raw JS result or maybe strip slightly.
    this.display = result.toString();
  }
}
