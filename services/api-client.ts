import { ApiResponse, AuthTokens } from '../types/ems.types';
import { storage } from '../utils/storage';

export interface ApiClientConfig {
  baseUrl?: string;
  timeoutMs?: number;
  onUnauthorized?: () => void;
}

export class ApiError extends Error {
  public status: number;
  public code?: string;
  public details?: unknown;

  constructor(message: string, status: number, code?: string, details?: unknown) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

/**
 * EventSphere Centralized API Client
 * Features:
 * - Base URL configuration (Dev: http://localhost:3001, Prod: https://api.yourapp.com)
 * - Automatic Bearer Access Token injection
 * - Automated 401 token refresh queue & retry
 * - Reusable typed request methods (GET, POST, PUT, PATCH, DELETE)
 */
export class ApiClient {
  private baseUrl: string;
  private timeoutMs: number;
  private onUnauthorized?: () => void;

  // Refresh token rotation state
  private isRefreshing = false;
  private refreshSubscribers: Array<(token: string) => void> = [];

  constructor(config: ApiClientConfig = {}) {
    const globalProcess = (globalThis as unknown as { process?: { env?: Record<string, string> } })?.process;
    const isProd = globalProcess?.env?.NODE_ENV === 'production';

    this.baseUrl =
      config.baseUrl ||
      globalProcess?.env?.NEXT_PUBLIC_API_URL ||
      (isProd ? 'https://api.yourapp.com' : 'http://192.168.0.112:3001');

    this.timeoutMs = config.timeoutMs ?? 15000;
    this.onUnauthorized = config.onUnauthorized;
  }

  public setBaseUrl(url: string): void {
    this.baseUrl = url;
  }

  public setUnauthorizedHandler(handler: () => void): void {
    this.onUnauthorized = handler;
  }

  private onTokenRefreshed(token: string): void {
    this.refreshSubscribers.forEach((callback) => callback(token));
    this.refreshSubscribers = [];
  }

  private addRefreshSubscriber(callback: (token: string) => void): void {
    this.refreshSubscribers.push(callback);
  }

  /**
   * Core request executor with timeout and 401 retry interceptor.
   */
  public async request<T>(
    endpoint: string,
    options: RequestInit = {},
    isRetry = false
  ): Promise<ApiResponse<T>> {
    const url = endpoint.startsWith('http')
      ? endpoint
      : `${this.baseUrl.replace(/\/+$/, '')}/${endpoint.replace(/^\/+/, '')}`;

    const headers = new Headers(options.headers || {});
    if (!headers.has('Content-Type') && !(options.body instanceof FormData)) {
      headers.set('Content-Type', 'application/json');
    }
    headers.set('Accept', 'application/json');

    // Inject Bearer token
    const token = await storage.getAccessToken();
    if (token && !headers.has('Authorization')) {
      headers.set('Authorization', `Bearer ${token}`);
    }

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const response = await fetch(url, {
        ...options,
        headers,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      // Handle 401 Unauthorized with Refresh Token rotation
      if (response.status === 401 && !isRetry) {
        return this.handle401AndRetry<T>(endpoint, options);
      }

      const responseBody = await response.json().catch(() => null);

      if (!response.ok) {
        throw new ApiError(
          responseBody?.error?.message ||
            responseBody?.message ||
            `HTTP ${response.status}: ${response.statusText}`,
          response.status,
          responseBody?.error?.code,
          responseBody?.error?.details
        );
      }

      return responseBody as ApiResponse<T>;
    } catch (err: any) {
      clearTimeout(timeoutId);
      if (err.name === 'AbortError') {
        throw new ApiError('Request connection timed out', 408, 'TIMEOUT');
      }
      throw err;
    }
  }

  /**
   * Automated Token Refresh Queue
   */
  private async handle401AndRetry<T>(
    endpoint: string,
    options: RequestInit
  ): Promise<ApiResponse<T>> {
    const refreshToken = await storage.getRefreshToken();

    if (!refreshToken) {
      await this.handleAuthFailure();
      throw new ApiError('Session expired. Please log in again.', 401, 'UNAUTHORIZED');
    }

    if (!this.isRefreshing) {
      this.isRefreshing = true;

      try {
        const refreshResponse = await fetch(`${this.baseUrl}/api/v1/auth/refresh`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ refreshToken }),
        });

        if (!refreshResponse.ok) {
          throw new Error('Refresh token rejected');
        }

        const data: ApiResponse<AuthTokens> = await refreshResponse.json();
        const newTokens = data.data;

        await storage.setTokens(newTokens);
        this.isRefreshing = false;
        this.onTokenRefreshed(newTokens.accessToken);
      } catch {
        this.isRefreshing = false;
        this.refreshSubscribers = [];
        await this.handleAuthFailure();
        throw new ApiError('Session refresh failed. Please log in again.', 401, 'SESSION_EXPIRED');
      }
    }

    // Wait for the new token and retry the original request
    return new Promise((resolve, reject) => {
      this.addRefreshSubscriber(async (newToken: string) => {
        try {
          const retryHeaders = new Headers(options.headers || {});
          retryHeaders.set('Authorization', `Bearer ${newToken}`);
          const retryRes = await this.request<T>(
            endpoint,
            { ...options, headers: retryHeaders },
            true
          );
          resolve(retryRes);
        } catch (error) {
          reject(error);
        }
      });
    });
  }

  private async handleAuthFailure(): Promise<void> {
    await storage.clearAuth();
    if (this.onUnauthorized) {
      this.onUnauthorized();
    }
  }

  // ── Convenience Methods ───────────────────────────────────────────────────

  public get<T>(endpoint: string, options?: RequestInit): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { ...options, method: 'GET' });
  }

  public post<T>(endpoint: string, body?: unknown, options?: RequestInit): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      ...options,
      method: 'POST',
      body: body instanceof FormData ? body : JSON.stringify(body),
    });
  }

  public put<T>(endpoint: string, body?: unknown, options?: RequestInit): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      ...options,
      method: 'PUT',
      body: body instanceof FormData ? body : JSON.stringify(body),
    });
  }

  public patch<T>(endpoint: string, body?: unknown, options?: RequestInit): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      ...options,
      method: 'PATCH',
      body: body instanceof FormData ? body : JSON.stringify(body),
    });
  }

  public delete<T>(endpoint: string, options?: RequestInit): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { ...options, method: 'DELETE' });
  }
}

// Global Singleton Instance Export
export const apiClient = new ApiClient();
export const apiRequest = <T>(endpoint: string, options?: RequestInit) =>
  apiClient.request<T>(endpoint, options);
