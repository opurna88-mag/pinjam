import { z } from 'zod'

/**
 * Shape-level validation only.
 *
 * Business rules (granularity, duration, operating hours, submission window,
 * capacity) are NOT duplicated here — they live in lib/booking-rules.ts and
 * are checked in the API route. Field lengths follow
 * docs/BUSINESS_RULES.md section 8.
 */
export const createBookingSchema = z
  .object({
    room_id: z.string().uuid('room_id must be a valid UUID'),
    start_time: z
      .string()
      .datetime({ offset: true, message: 'start_time must be an ISO 8601 timestamp with offset' }),
    end_time: z
      .string()
      .datetime({ offset: true, message: 'end_time must be an ISO 8601 timestamp with offset' }),
    activity_name: z
      .string()
      .trim()
      .min(3, 'activity_name must be at least 3 characters')
      .max(200, 'activity_name must be at most 200 characters'),
    participant_count: z
      .number({ message: 'participant_count is required' })
      .int('participant_count must be an integer')
      .positive('participant_count must be greater than 0'),
    person_in_charge: z
      .string()
      .trim()
      .min(3, 'person_in_charge must be at least 3 characters')
      .max(120, 'person_in_charge must be at most 120 characters'),
    phone_number: z
      .string()
      .regex(
        /^(\+62|62|0)8\d{7,12}$/,
        'phone_number must be a valid Indonesian mobile number'
      ),
    purpose: z.string().trim().max(1000).optional(),
    terms_accepted: z.literal(true, {
      message: 'terms_accepted must be true',
    }),
  })
  .refine(
    (data) =>
      new Date(data.end_time).getTime() > new Date(data.start_time).getTime(),
    {
      message: 'end_time must be after start_time',
      path: ['end_time'],
    }
  )

/** Admin approve/reject. admin_note is mandatory for BOTH actions. */
export const adminDecisionSchema = z.object({
  status: z.enum(['approved', 'rejected']),
  admin_note: z
    .string()
    .trim()
    .min(5, 'admin_note must be at least 5 characters')
    .max(2000, 'admin_note must be at most 2000 characters'),
})

/** Owner cancellation. Reason is optional. */
export const cancelBookingSchema = z.object({
  cancel_reason: z.string().trim().max(500).optional(),
})

export type CreateBookingInput = z.infer<typeof createBookingSchema>
export type AdminDecisionInput = z.infer<typeof adminDecisionSchema>
export type CancelBookingInput = z.infer<typeof cancelBookingSchema>