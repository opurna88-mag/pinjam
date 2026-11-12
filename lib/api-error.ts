/**
 * Maps application error codes to HTTP status codes.
 * Reference: docs/API_SPEC.md section 1.3
 */

export const ERROR_STATUS: Record<string, number> = {
  VALIDATION_ERROR: 400,
  UNAUTHENTICATED: 401,
  EMAIL_NOT_VERIFIED: 401,
  FORBIDDEN: 403,
  EMAIL_DOMAIN_NOT_ALLOWED: 403,
  CANCELLATION_WINDOW_CLOSED: 403,
  NOT_FOUND: 404,
  SLOT_UNAVAILABLE: 409,
  INVALID_STATUS_TRANSITION: 409,
  LAST_ADMIN: 409,
  TERMS_NOT_ACCEPTED: 422,
  ADMIN_NOTE_REQUIRED: 422,
  CAPACITY_EXCEEDED: 422,
  OUTSIDE_OPERATING_HOURS: 422,
  INVALID_DURATION: 422,
  INVALID_GRANULARITY: 422,
  BOOKING_WINDOW_INVALID: 422,
  RATE_LIMITED: 429,
  INTERNAL_ERROR: 500,
} as const

export type ErrorCode = keyof typeof ERROR_STATUS

export type ApiSuccess<T> = {
  success: true
  data: T
  meta?: Record<string, unknown>
}

export type ApiFailure = {
  success: false
  error: {
    code: ErrorCode
    message: string
    details?: Record<string, unknown>
  }
}

export type ApiResponse<T> = ApiSuccess<T> | ApiFailure

export function jsonError(
  code: ErrorCode,
  message: string,
  details?: Record<string, unknown>
) {
  return {
    success: false as const,
    error: { code, message, ...(details ? { details } : {}) },
  }
}

export function jsonSuccess<T>(data: T, meta?: Record<string, unknown>) {
  return {
    success: true as const,
    data,
    ...(meta ? { meta } : {}),
  }
}