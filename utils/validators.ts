/**
 * Form Validation Utilities for Authentication & User Registration
 */

export interface ValidationResult {
  isValid: boolean;
  message?: string;
}

/**
 * Validates Email Address format.
 */
export function validateEmail(email: string): ValidationResult {
  const trimmed = email?.trim() || '';
  if (!trimmed) {
    return { isValid: false, message: 'Email address is required' };
  }

  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailRegex.test(trimmed)) {
    return { isValid: false, message: 'Please enter a valid email address' };
  }

  return { isValid: true };
}

/**
 * Validates Password strength:
 * - Minimum 8 characters
 * - At least one uppercase letter
 * - At least one lowercase letter
 * - At least one number
 */
export function validatePassword(password: string): ValidationResult {
  if (!password) {
    return { isValid: false, message: 'Password is required' };
  }

  if (password.length < 8) {
    return { isValid: false, message: 'Password must be at least 8 characters' };
  }

  const hasUpper = /[A-Z]/.test(password);
  const hasLower = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);

  if (!hasUpper || !hasLower || !hasNumber) {
    return {
      isValid: false,
      message: 'Password must contain uppercase, lowercase letters, and a number',
    };
  }

  return { isValid: true };
}

/**
 * Standardizes and validates 10-digit Indian Mobile Numbers with optional +91.
 * Returns formatted number (+91XXXXXXXXXX) if valid.
 */
export function validateIndianPhone(phone: string): {
  isValid: boolean;
  message?: string;
  formattedNumber?: string;
} {
  const cleaned = (phone || '').replace(/[\s-]/g, '');

  if (!cleaned) {
    return { isValid: false, message: 'Phone number is required' };
  }

  // Regex matching +91XXXXXXXXXX, 91XXXXXXXXXX, or XXXXXXXXXX (starts with 6-9)
  const phoneRegex = /^(?:\+91|91)?[6-9]\d{9}$/;

  if (!phoneRegex.test(cleaned)) {
    return {
      isValid: false,
      message: 'Please enter a valid 10-digit Indian mobile number',
    };
  }

  // Extract last 10 digits
  const last10 = cleaned.slice(-10);
  const formatted = `+91${last10}`;

  return {
    isValid: true,
    formattedNumber: formatted,
  };
}

/**
 * Validates 6-digit numeric OTP code.
 */
export function validateOtp(otp: string): ValidationResult {
  const trimmed = otp?.trim() || '';
  if (!trimmed) {
    return { isValid: false, message: 'OTP is required' };
  }

  if (!/^\d{6}$/.test(trimmed)) {
    return { isValid: false, message: 'OTP must be exactly 6 digits' };
  }

  return { isValid: true };
}
