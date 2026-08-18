import { ApiResponse, AuthTokens, User } from '../types/ems.types';
import { apiClient } from './api-client';
import { storage } from '../utils/storage';

export interface SignupEmailPayload {
  email: string;
  password: string;
  name: string;
  phone?: string;
  city?: string;
}

export interface LoginEmailPayload {
  email: string;
  password: string;
}

export interface RequestOtpPayload {
  phone: string;
}

export interface VerifyOtpPayload {
  phone: string;
  otp: string;
}

export interface AuthResponseData {
  user: User;
  tokens: AuthTokens;
}

/**
 * Authentication Service handling all API communication for user lifecycle.
 */
export class AuthService {
  /**
   * Sign Up with Email & Password
   * POST /auth/signup/email
   */
  async signupWithEmail(payload: SignupEmailPayload): Promise<AuthResponseData> {
    const response = await apiClient.post<AuthResponseData>(
      '/api/v1/auth/signup/email',
      payload
    );

    const data = response.data;
    await storage.setTokens(data.tokens);
    await storage.setUserProfile(data.user);
    return data;
  }

  /**
   * Login with Email & Password
   * POST /auth/login/email
   */
  async loginWithEmail(payload: LoginEmailPayload): Promise<AuthResponseData> {
    const response = await apiClient.post<AuthResponseData>(
      '/api/v1/auth/login/email',
      payload
    );

    const data = response.data;
    await storage.setTokens(data.tokens);
    await storage.setUserProfile(data.user);
    return data;
  }

  /**
   * Request Phone OTP (Returns 300 seconds expiration timer)
   * POST /auth/login/phone
   */
  async requestPhoneOtp(
    payload: RequestOtpPayload
  ): Promise<{ expiresInSeconds: number; message: string }> {
    const response = await apiClient.post<{ expiresInSeconds: number; message: string }>(
      '/api/v1/auth/login/phone',
      payload
    );

    return (
      response.data || {
        expiresInSeconds: 300,
        message: 'OTP sent to mobile number',
      }
    );
  }

  /**
   * Verify 6-digit Phone OTP
   * POST /auth/verify-otp
   */
  async verifyPhoneOtp(payload: VerifyOtpPayload): Promise<AuthResponseData> {
    const response = await apiClient.post<AuthResponseData>(
      '/api/v1/auth/verify-otp',
      payload
    );

    const data = response.data;
    await storage.setTokens(data.tokens);
    await storage.setUserProfile(data.user);
    return data;
  }

  /**
   * Refresh Token rotation
   * POST /auth/refresh
   */
  async refreshToken(): Promise<AuthTokens> {
    const refreshToken = await storage.getRefreshToken();
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }

    const response = await apiClient.post<AuthTokens>('/api/v1/auth/refresh', {
      refreshToken,
    });

    const tokens = response.data;
    await storage.setTokens(tokens);
    return tokens;
  }

  /**
   * Logout user and revoke server refresh token
   * POST /auth/logout
   */
  async logout(): Promise<void> {
    try {
      const refreshToken = await storage.getRefreshToken();
      if (refreshToken) {
        await apiClient.post('/api/v1/auth/logout', { refreshToken });
      }
    } catch {
      // Proceed with local logout even if server fails
    } finally {
      await storage.clearAuth();
    }
  }

  /**
   * Google OAuth Entrypoint URL
   */
  getGoogleOAuthUrl(): string {
    const globalProcess = (globalThis as unknown as { process?: { env?: Record<string, string> } })?.process;
    const baseUrl = globalProcess?.env?.NEXT_PUBLIC_API_URL || 'http://localhost:3001';
    return `${baseUrl}/api/v1/auth/google`;
  }
}

export const authService = new AuthService();
