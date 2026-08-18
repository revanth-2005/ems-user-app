import { AuthTokens, User } from '../types/ems.types';

/**
 * Storage Keys
 */
export const STORAGE_KEYS = {
  ACCESS_TOKEN: 'ems_access_token',
  REFRESH_TOKEN: 'ems_refresh_token',
  USER_PROFILE: 'ems_user_profile',
  ACTIVE_PORTAL: 'ems_active_portal',
} as const;

export interface StorageAdapter {
  getItem(key: string): Promise<string | null> | string | null;
  setItem(key: string, value: string): Promise<void> | void;
  removeItem(key: string): Promise<void> | void;
  clear(): Promise<void> | void;
}

/**
 * Default Storage Adapter: Uses window.localStorage if in browser,
 * otherwise falls back to safe in-memory Map for Node/SSR environments.
 */
class DefaultStorageAdapter implements StorageAdapter {
  private memoryMap = new Map<string, string>();

  private get isLocalStorageAvailable(): boolean {
    return typeof window !== 'undefined' && typeof window.localStorage !== 'undefined';
  }

  getItem(key: string): string | null {
    if (this.isLocalStorageAvailable) {
      return window.localStorage.getItem(key);
    }
    return this.memoryMap.get(key) ?? null;
  }

  setItem(key: string, value: string): void {
    if (this.isLocalStorageAvailable) {
      window.localStorage.setItem(key, value);
    } else {
      this.memoryMap.set(key, value);
    }
  }

  removeItem(key: string): void {
    if (this.isLocalStorageAvailable) {
      window.localStorage.removeItem(key);
    } else {
      this.memoryMap.delete(key);
    }
  }

  clear(): void {
    if (this.isLocalStorageAvailable) {
      window.localStorage.clear();
    } else {
      this.memoryMap.clear();
    }
  }
}

/**
 * Secure Storage Utility for Auth & Session management.
 */
export class StorageService {
  private adapter: StorageAdapter;

  constructor(adapter?: StorageAdapter) {
    this.adapter = adapter || new DefaultStorageAdapter();
  }

  /**
   * Swap out adapter (e.g. for React Native AsyncStorage / Expo SecureStore).
   */
  public setAdapter(adapter: StorageAdapter): void {
    this.adapter = adapter;
  }

  // ── Access Token ──────────────────────────────────────────────────────────

  async getAccessToken(): Promise<string | null> {
    return await this.adapter.getItem(STORAGE_KEYS.ACCESS_TOKEN);
  }

  async setAccessToken(token: string): Promise<void> {
    await this.adapter.setItem(STORAGE_KEYS.ACCESS_TOKEN, token);
  }

  // ── Refresh Token ─────────────────────────────────────────────────────────

  async getRefreshToken(): Promise<string | null> {
    return await this.adapter.getItem(STORAGE_KEYS.REFRESH_TOKEN);
  }

  async setRefreshToken(token: string): Promise<void> {
    await this.adapter.setItem(STORAGE_KEYS.REFRESH_TOKEN, token);
  }

  // ── Batch Tokens ──────────────────────────────────────────────────────────

  async setTokens(tokens: AuthTokens): Promise<void> {
    await Promise.all([
      this.setAccessToken(tokens.accessToken),
      this.setRefreshToken(tokens.refreshToken),
    ]);
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  async getUserProfile(): Promise<User | null> {
    const raw = await this.adapter.getItem(STORAGE_KEYS.USER_PROFILE);
    if (!raw) return null;
    try {
      return JSON.parse(raw) as User;
    } catch {
      return null;
    }
  }

  async setUserProfile(user: User): Promise<void> {
    await this.adapter.setItem(STORAGE_KEYS.USER_PROFILE, JSON.stringify(user));
  }

  // ── Clear Session ─────────────────────────────────────────────────────────

  async clearAuth(): Promise<void> {
    await Promise.all([
      this.adapter.removeItem(STORAGE_KEYS.ACCESS_TOKEN),
      this.adapter.removeItem(STORAGE_KEYS.REFRESH_TOKEN),
      this.adapter.removeItem(STORAGE_KEYS.USER_PROFILE),
    ]);
  }
}

// Global Singleton Export
export const storage = new StorageService();
