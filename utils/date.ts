/**
 * Date & Time Utilities
 * Standards:
 * - Dates: ISO-8601 strings (YYYY-MM-DD or YYYY-MM-DDTHH:mm:ss.sssZ)
 * - Times: 24-hour format (HH:mm)
 */

/**
 * Formats an ISO date string or Date object into human-readable Indian standard date.
 * Example: "2026-11-25" => "25 Nov 2026"
 */
export function formatDate(
  dateInput: string | Date | number,
  options?: Intl.DateTimeFormatOptions
): string {
  if (!dateInput) return '';
  const date = new Date(dateInput);
  if (isNaN(date.getTime())) return '';

  const defaultOptions: Intl.DateTimeFormatOptions = {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  };

  return new Intl.DateTimeFormat('en-IN', options || defaultOptions).format(date);
}

/**
 * Formats a Date or ISO string into 24-hour time notation (HH:mm).
 * Example: 2026-11-25T18:30:00.000Z => "18:30"
 */
export function formatTime24(dateInput: string | Date | number): string {
  if (!dateInput) return '';
  const date = new Date(dateInput);
  if (isNaN(date.getTime())) return '';

  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  return `${hours}:${minutes}`;
}

/**
 * Formats into standard event datetime (e.g., "Wed, 25 Nov • 18:30")
 */
export function formatEventDateTime(dateInput: string | Date | number): string {
  if (!dateInput) return '';
  const date = new Date(dateInput);
  if (isNaN(date.getTime())) return '';

  const datePart = new Intl.DateTimeFormat('en-IN', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
  }).format(date);

  const timePart = formatTime24(date);
  return `${datePart} • ${timePart}`;
}

/**
 * Returns ISO-8601 Date string (YYYY-MM-DD).
 */
export function toISODateString(date: Date = new Date()): string {
  return date.toISOString().split('T')[0];
}

/**
 * Calculates remaining hours/minutes before an SLA deadline ISO string expires.
 */
export function formatSlaRemaining(slaDeadlineIso: string | Date): {
  isExpired: boolean;
  displayText: string;
  hoursRemaining: number;
} {
  const deadline = new Date(slaDeadlineIso).getTime();
  const now = Date.now();
  const diffMs = deadline - now;

  if (diffMs <= 0) {
    return { isExpired: true, displayText: 'SLA Expired', hoursRemaining: 0 };
  }

  const totalMinutes = Math.floor(diffMs / (1000 * 60));
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;

  if (hours > 24) {
    const days = Math.floor(hours / 24);
    return {
      isExpired: false,
      displayText: `${days}d ${hours % 24}h remaining`,
      hoursRemaining: hours,
    };
  }

  return {
    isExpired: false,
    displayText: `${hours}h ${minutes}m remaining`,
    hoursRemaining: hours,
  };
}
