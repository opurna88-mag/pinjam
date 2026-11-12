/**
 * Single source of booking limits in application code.
 *
 * The numeric values mirror docs/BUSINESS_RULES.md section 2, which is the
 * only document allowed to define them. Do NOT copy these numbers into other
 * files — import from here instead.
 *
 * Operating hours are deliberately NOT defined here: they are read per day
 * from the `operating_hours` table so Friday's shorter day is never hardcoded.
 */

export const BOOKING_RULES = {
  /** Slot boundaries must fall on this step, in minutes. */
  granularityMinutes: 30,
  /** Shortest bookable duration, in minutes. */
  minDurationMinutes: 30,
  /** Longest bookable duration, in minutes. */
  maxDurationMinutes: 8 * 60,
  /** Earliest allowed event date, in days from today. */
  minAdvanceDays: 1,
  /** Furthest allowed event date, in days from today. */
  maxAdvanceDays: 30,
  /** Pending bookings expire after this many hours without admin action. */
  pendingExpiryHours: 72,
  /** Owned approved bookings may be cancelled up to this many days ahead. */
  cancellationCutoffDays: 1,
  /** Minimum length of admin_note on approve and reject. */
  adminNoteMinLength: 5,
} as const

/** Statuses that block a slot. Mirrors the DB EXCLUDE predicate. */
export const BLOCKING_STATUSES = ['pending', 'approved'] as const

export type BookingStatus =
  | 'pending'
  | 'approved'
  | 'rejected'
  | 'cancelled'
  | 'expired'

export type OperatingHours = {
  day_of_week: number
  open_time: string
  close_time: string
  is_open: boolean
}

/** Converts a 'HH:MM' or 'HH:MM:SS' string to minutes since midnight. */
export function minutesFromHHMM(value: string): number {
  const [hours, minutes] = value.split(':').map(Number)
  return hours * 60 + minutes
}

/** True when the timestamp sits on a granularity boundary. */
export function isOnGranularity(date: Date): boolean {
  return (
    date.getMinutes() % BOOKING_RULES.granularityMinutes === 0 &&
    date.getSeconds() === 0
  )
}

/**
 * True when start and end fall inside the given day's operating hours.
 * `hours` must come from the operating_hours table, never from constants.
 */
export function isWithinOperatingHours(
  start: Date,
  end: Date,
  hours: OperatingHours
): boolean {
  if (!hours.is_open) return false

  const startMin = start.getHours() * 60 + start.getMinutes()
  const endMin = end.getHours() * 60 + end.getMinutes()

  return (
    startMin >= minutesFromHHMM(hours.open_time) &&
    endMin <= minutesFromHHMM(hours.close_time)
  )
}

/** True when both ends fall on the same calendar day (no overnight slots). */
export function isSameDay(start: Date, end: Date): boolean {
  return (
    start.getFullYear() === end.getFullYear() &&
    start.getMonth() === end.getMonth() &&
    start.getDate() === end.getDate()
  )
}

/** Duration between two timestamps, in minutes. */
export function durationMinutes(start: Date, end: Date): number {
  return (end.getTime() - start.getTime()) / 60_000
}

/**
 * True when the event date falls inside the submission window.
 * Admins are exempt from this check (see BUSINESS_RULES.md section 2).
 */
export function isWithinSubmissionWindow(
  eventDate: Date,
  now: Date = new Date()
): boolean {
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const target = new Date(
    eventDate.getFullYear(),
    eventDate.getMonth(),
    eventDate.getDate()
  )
  const diffDays = Math.round((target.getTime() - today.getTime()) / 86_400_000)

  return (
    diffDays >= BOOKING_RULES.minAdvanceDays &&
    diffDays <= BOOKING_RULES.maxAdvanceDays
  )
}

/** True when an approved booking can still be cancelled by its owner. */
export function canOwnerCancel(
  startTime: Date,
  now: Date = new Date()
): boolean {
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const target = new Date(
    startTime.getFullYear(),
    startTime.getMonth(),
    startTime.getDate()
  )
  const diffDays = Math.round((target.getTime() - today.getTime()) / 86_400_000)

  return diffDays >= BOOKING_RULES.cancellationCutoffDays
}