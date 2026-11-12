import { describe, it, expect } from 'vitest'

import {
  BOOKING_RULES,
  BLOCKING_STATUSES,
  minutesFromHHMM,
  isOnGranularity,
  isWithinOperatingHours,
  isSameDay,
  durationMinutes,
  isWithinSubmissionWindow,
  canOwnerCancel,
  type OperatingHours,
} from '@/lib/booking-rules'

// These assertions intentionally spell out the concrete limits: they are the
// test cases allowed to contain numbers (see docs/BUSINESS_RULES.md section 2).

const weekdayHours: OperatingHours = {
  day_of_week: 1,
  open_time: '07:00',
  close_time: '16:00',
  is_open: true,
}

// Friday closes earlier. The value comes from the operating_hours table,
// never from a hardcoded constant.
const fridayHours: OperatingHours = {
  day_of_week: 5,
  open_time: '07:00',
  close_time: '14:30',
  is_open: true,
}

describe('BOOKING_RULES', () => {
  it('exposes the locked limits', () => {
    expect(BOOKING_RULES.granularityMinutes).toBe(30)
    expect(BOOKING_RULES.minDurationMinutes).toBe(30)
    expect(BOOKING_RULES.maxDurationMinutes).toBe(480)
    expect(BOOKING_RULES.minAdvanceDays).toBe(1)
    expect(BOOKING_RULES.maxAdvanceDays).toBe(30)
  })

  it('blocks slots only for pending and approved', () => {
    expect([...BLOCKING_STATUSES]).toEqual(['pending', 'approved'])
  })
})

describe('minutesFromHHMM', () => {
  it('parses HH:MM', () => {
    expect(minutesFromHHMM('07:00')).toBe(420)
    expect(minutesFromHHMM('14:30')).toBe(870)
    expect(minutesFromHHMM('16:00')).toBe(960)
  })

  it('parses HH:MM:SS from a time column', () => {
    expect(minutesFromHHMM('14:30:00')).toBe(870)
  })
})

describe('isOnGranularity', () => {
  it('accepts :00 and :30', () => {
    expect(isOnGranularity(new Date(2026, 2, 10, 7, 0))).toBe(true)
    expect(isOnGranularity(new Date(2026, 2, 10, 10, 30))).toBe(true)
  })

  it('rejects other minutes', () => {
    expect(isOnGranularity(new Date(2026, 2, 10, 10, 15))).toBe(false)
    expect(isOnGranularity(new Date(2026, 2, 10, 10, 45))).toBe(false)
  })
})

describe('isWithinOperatingHours', () => {
  it('accepts a slot inside weekday hours', () => {
    expect(
      isWithinOperatingHours(
        new Date(2026, 2, 9, 7, 0),
        new Date(2026, 2, 9, 16, 0),
        weekdayHours
      )
    ).toBe(true)
  })

  it('rejects a slot before opening', () => {
    expect(
      isWithinOperatingHours(
        new Date(2026, 2, 9, 6, 30),
        new Date(2026, 2, 9, 9, 0),
        weekdayHours
      )
    ).toBe(false)
  })

  it('rejects Friday 15:00 because Friday closes earlier', () => {
    expect(
      isWithinOperatingHours(
        new Date(2026, 2, 13, 13, 0),
        new Date(2026, 2, 13, 15, 0),
        fridayHours
      )
    ).toBe(false)
  })

  it('accepts Friday up to the closing time', () => {
    expect(
      isWithinOperatingHours(
        new Date(2026, 2, 13, 13, 0),
        new Date(2026, 2, 13, 14, 30),
        fridayHours
      )
    ).toBe(true)
  })

  it('rejects any slot on a closed day', () => {
    expect(
      isWithinOperatingHours(
        new Date(2026, 2, 9, 8, 0),
        new Date(2026, 2, 9, 10, 0),
        { ...weekdayHours, is_open: false }
      )
    ).toBe(false)
  })
})

describe('isSameDay', () => {
  it('is true within one day', () => {
    expect(
      isSameDay(new Date(2026, 2, 10, 8, 0), new Date(2026, 2, 10, 12, 0))
    ).toBe(true)
  })

  it('is false across midnight', () => {
    expect(
      isSameDay(new Date(2026, 2, 10, 22, 0), new Date(2026, 2, 11, 1, 0))
    ).toBe(false)
  })
})

describe('durationMinutes', () => {
  it('measures the span in minutes', () => {
    expect(
      durationMinutes(
        new Date(2026, 2, 10, 10, 0),
        new Date(2026, 2, 10, 12, 0)
      )
    ).toBe(120)
  })
})

describe('isWithinSubmissionWindow', () => {
  const now = new Date(2026, 2, 10, 9, 0)

  it('rejects same-day bookings', () => {
    expect(isWithinSubmissionWindow(new Date(2026, 2, 10, 13, 0), now)).toBe(
      false
    )
  })

  it('accepts tomorrow', () => {
    expect(isWithinSubmissionWindow(new Date(2026, 2, 11, 9, 0), now)).toBe(true)
  })

  it('accepts the last day of the window', () => {
    expect(isWithinSubmissionWindow(new Date(2026, 3, 9, 9, 0), now)).toBe(true)
  })

  it('rejects past the window', () => {
    expect(isWithinSubmissionWindow(new Date(2026, 3, 10, 9, 0), now)).toBe(
      false
    )
  })

  it('rejects a past date', () => {
    expect(isWithinSubmissionWindow(new Date(2026, 2, 9, 9, 0), now)).toBe(false)
  })
})

describe('canOwnerCancel', () => {
  const now = new Date(2026, 2, 10, 9, 0)

  it('allows cancelling an event tomorrow', () => {
    expect(canOwnerCancel(new Date(2026, 2, 11, 10, 0), now)).toBe(true)
  })

  it('rejects cancelling an event today', () => {
    expect(canOwnerCancel(new Date(2026, 2, 10, 15, 0), now)).toBe(false)
  })

  it('allows cancelling a later event', () => {
    expect(canOwnerCancel(new Date(2026, 2, 20, 10, 0), now)).toBe(true)
  })
})