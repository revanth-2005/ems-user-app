import { ApiResponse, Booking } from '../types/ems.types';
import { apiClient } from './api-client';

export interface CancelBookingPayload {
  reason: string;
}

/**
 * Booking Lifecycle Tracking & Cancellation Service
 */
export class BookingService {
  /**
   * Fetch all vendor bookings for the current authenticated user
   * GET /bookings/my-bookings
   */
  async getMyBookings(): Promise<Booking[]> {
    const res = await apiClient.get<Booking[]>('/api/v1/bookings/my-bookings');
    return res.data || [];
  }

  /**
   * Cancel an existing booking with a reason
   * PATCH /bookings/:id/cancel
   */
  async cancelBooking(
    bookingId: string,
    reason: string
  ): Promise<Booking> {
    const res = await apiClient.patch<Booking>(
      `/api/v1/bookings/${bookingId}/cancel`,
      { reason }
    );
    return res.data;
  }
}

export const bookingService = new BookingService();
