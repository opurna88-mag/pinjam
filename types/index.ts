/**
 * Shared database row types.
 * Mirrors docs/DATABASE_DESIGN.md section 1 table for table.
 */

export type ProfileRole = 'student' | 'lecturer' | 'admin'

export type BookingStatus =
  | 'pending'
  | 'approved'
  | 'rejected'
  | 'cancelled'
  | 'expired'

export type NotificationChannel = 'email' | 'whatsapp'

export type NotificationEvent =
  | 'submitted'
  | 'approved'
  | 'rejected'
  | 'expired'
  | 'cancelled'

export type NotificationStatus = 'sent' | 'failed' | 'pending'

export interface Profile {
  id: string
  full_name: string | null
  phone_number: string | null
  role: ProfileRole
  created_at: string
  updated_at: string
}

export interface Room {
  id: string
  name: string
  code: string
  capacity: number
  location: string | null
  description: string | null
  image_url: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface RoomFacility {
  id: string
  room_id: string
  facility: string
  created_at: string
}

export interface RoomImage {
  id: string
  room_id: string
  url: string
  is_cover: boolean
  sort_order: number
  created_at: string
}

export interface GalleryImage {
  id: string
  url: string
  caption: string | null
  sort_order: number
  created_at: string
}

export interface OperatingHours {
  day_of_week: number
  open_time: string
  close_time: string
  is_open: boolean
  updated_at: string
}

export interface Booking {
  id: string
  user_id: string
  room_id: string
  start_time: string
  end_time: string
  activity_name: string
  participant_count: number
  person_in_charge: string
  phone_number: string
  purpose: string | null
  status: BookingStatus
  admin_note: string | null
  approved_by: string | null
  decided_at: string | null
  terms_accepted_at: string
  terms_version: string
  cancel_reason: string | null
  created_at: string
  updated_at: string
}

export interface NotificationLog {
  id: string
  booking_id: string | null
  user_id: string | null
  channel: NotificationChannel
  event: NotificationEvent
  recipient: string
  status: NotificationStatus
  attempts: number
  error_message: string | null
  created_at: string
}

/** Row shape of the public_calendar view. Contains no private columns. */
export interface PublicCalendarEvent {
  id: string
  room_id: string
  room_code: string
  room_name: string
  start_time: string
  end_time: string
  activity_name: string
  person_in_charge: string
  status: BookingStatus
}