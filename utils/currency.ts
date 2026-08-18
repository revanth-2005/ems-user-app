/**
 * Currency Utilities
 * Standard: All monetary backend values are in Paise (100 Paise = ₹1.00 INR).
 */

export interface FormatCurrencyOptions {
  showDecimals?: boolean;
  symbol?: boolean;
  locale?: string;
}

/**
 * Formats an integer value in Paise to standard Indian Rupee notation (₹).
 * Example:
 * formatCurrency(150000) => "₹1,500"
 * formatCurrency(150050, { showDecimals: true }) => "₹1,500.50"
 */
export function formatCurrency(
  paise: number,
  options: FormatCurrencyOptions = {}
): string {
  const { showDecimals = false, symbol = true, locale = 'en-IN' } = options;

  if (typeof paise !== 'number' || isNaN(paise)) {
    return symbol ? '₹0' : '0';
  }

  const rupees = paise / 100;

  const formatted = new Intl.NumberFormat(locale, {
    style: symbol ? 'currency' : 'decimal',
    currency: 'INR',
    minimumFractionDigits: showDecimals ? 2 : (rupees % 1 === 0 ? 0 : 2),
    maximumFractionDigits: 2,
  }).format(rupees);

  return formatted;
}

/**
 * Converts integer Paise into decimal Rupees.
 */
export function paiseToRupees(paise: number): number {
  return (paise || 0) / 100;
}

/**
 * Converts standard Rupees into integer Paise for backend payload transmission.
 */
export function rupeesToPaise(rupees: number): number {
  return Math.round((rupees || 0) * 100);
}

/**
 * Calculates advance deposit and remainder balance in paise.
 */
export function calculateDeposit(
  totalPaise: number,
  rule: { type: 'PERCENT' | 'FLAT'; value: number }
): { depositPaise: number; balancePaise: number } {
  let deposit = 0;
  if (rule.type === 'PERCENT') {
    deposit = Math.round((totalPaise * rule.value) / 100);
  } else {
    deposit = rule.value;
  }

  // Clamping
  deposit = Math.max(0, Math.min(deposit, totalPaise));
  const balance = totalPaise - deposit;

  return { depositPaise: deposit, balancePaise: balance };
}
