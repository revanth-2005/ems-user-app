import { Address, CreateAddressPayload, User } from '../types/ems.types';
import { apiClient } from './api-client';
import { storage } from '../utils/storage';

export interface UpdateUserProfilePayload {
  name?: string;
  city?: string;
  avatarUrl?: string;
  profilePhoto?: string;
}

/**
 * User Profile & Address Book Service
 */
export class UserService {
  /**
   * Fetch current user profile
   * GET /users/me
   */
  async getProfile(): Promise<User> {
    const res = await apiClient.get<User>('/api/v1/users/me');
    const user = res.data;
    await storage.setUserProfile(user);
    return user;
  }

  /**
   * Update current user profile
   * PATCH /users/me
   */
  async updateProfile(payload: UpdateUserProfilePayload): Promise<User> {
    const res = await apiClient.patch<User>('/api/v1/users/me', payload);
    const updated = res.data;
    await storage.setUserProfile(updated);
    return updated;
  }

  /**
   * Fetch saved venue addresses
   * GET /users/me/addresses
   */
  async getAddresses(): Promise<Address[]> {
    const res = await apiClient.get<Address[]>('/api/v1/users/me/addresses');
    return res.data || [];
  }

  /**
   * Add a new venue address
   * POST /users/me/addresses
   */
  async addAddress(payload: CreateAddressPayload): Promise<Address> {
    const res = await apiClient.post<Address>(
      '/api/v1/users/me/addresses',
      payload
    );
    return res.data;
  }
}

export const userService = new UserService();
