import {
  Address,
  ApiResponse,
  CheckoutPayload,
  CheckoutResponse,
  CreateAddressPayload,
} from '../types/ems.types';
import { apiClient } from './api-client';

/**
 * Checkout & User Address Service
 */
export class CheckoutService {
  /**
   * Fetch saved user venue / delivery addresses
   * GET /users/me/addresses
   */
  async getAddresses(): Promise<Address[]> {
    const res = await apiClient.get<Address[]>('/api/v1/users/me/addresses');
    return res.data || [];
  }

  /**
   * Save a new venue / delivery address
   * POST /users/me/addresses
   */
  async addAddress(payload: CreateAddressPayload): Promise<Address> {
    const res = await apiClient.post<Address>(
      '/api/v1/users/me/addresses',
      payload
    );
    return res.data;
  }

  /**
   * Process Checkout: Creates 1 Master Order & N Child Bookings
   * POST /checkout
   */
  async processCheckout(payload: CheckoutPayload = {}): Promise<CheckoutResponse> {
    const res = await apiClient.post<CheckoutResponse>(
      '/api/v1/checkout',
      payload
    );
    return res.data;
  }
}

export const checkoutService = new CheckoutService();
