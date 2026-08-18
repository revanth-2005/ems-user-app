import { ActivePortal, User } from '../types/ems.types';
import { authService, LoginEmailPayload, SignupEmailPayload, VerifyOtpPayload } from '../services/auth-service';
import { storage } from '../utils/storage';

export interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  isInitializing: boolean;
  error: string | null;
  activePortal: ActivePortal;
  otpCountdownSeconds: number;
}

export type AuthListener = (state: AuthState) => void;

/**
 * Event-Driven Global Authentication Store
 * Provides reactive session state and methods across frontend components.
 */
export class AuthStore {
  private state: AuthState = {
    user: null,
    isAuthenticated: false,
    isLoading: false,
    isInitializing: true,
    error: null,
    activePortal: 'CUSTOMER',
    otpCountdownSeconds: 0,
  };

  private listeners: Set<AuthListener> = new Set();
  private otpTimerInterval: any = null;

  constructor() {
    this.initSession();
  }

  public getState(): AuthState {
    return { ...this.state };
  }

  public subscribe(listener: AuthListener): () => void {
    this.listeners.add(listener);
    listener(this.getState());
    return () => this.listeners.delete(listener);
  }

  private notify(): void {
    const currentState = this.getState();
    this.listeners.forEach((listener) => listener(currentState));
  }

  private setState(partial: Partial<AuthState>): void {
    this.state = { ...this.state, ...partial };
    this.notify();
  }

  /**
   * 1. Splash / App Launch Flow
   * Checks if valid access_token exists or attempts silent token refresh.
   */
  async initSession(): Promise<boolean> {
    this.setState({ isInitializing: true, error: null });

    try {
      const accessToken = await storage.getAccessToken();
      const cachedUser = await storage.getUserProfile();

      if (accessToken && cachedUser) {
        this.setState({
          user: cachedUser,
          isAuthenticated: true,
          activePortal: cachedUser.activePortal || 'CUSTOMER',
          isInitializing: false,
        });
        return true;
      }

      // If token missing, attempt refresh
      const refreshToken = await storage.getRefreshToken();
      if (refreshToken) {
        await authService.refreshToken();
        const user = await storage.getUserProfile();
        if (user) {
          this.setState({
            user,
            isAuthenticated: true,
            activePortal: user.activePortal || 'CUSTOMER',
            isInitializing: false,
          });
          return true;
        }
      }
    } catch {
      await storage.clearAuth();
    }

    this.setState({
      user: null,
      isAuthenticated: false,
      isInitializing: false,
    });
    return false;
  }

  /**
   * 2. Login with Email
   */
  async loginWithEmail(payload: LoginEmailPayload): Promise<void> {
    this.setState({ isLoading: true, error: null });
    try {
      const data = await authService.loginWithEmail(payload);
      this.setState({
        user: data.user,
        isAuthenticated: true,
        activePortal: data.user.activePortal || 'CUSTOMER',
        isLoading: false,
      });
    } catch (err: any) {
      this.setState({
        isLoading: false,
        error: err.message || 'Login failed',
      });
      throw err;
    }
  }

  /**
   * 3. Sign Up with Email
   */
  async signupWithEmail(payload: SignupEmailPayload): Promise<void> {
    this.setState({ isLoading: true, error: null });
    try {
      const data = await authService.signupWithEmail(payload);
      this.setState({
        user: data.user,
        isAuthenticated: true,
        activePortal: data.user.activePortal || 'CUSTOMER',
        isLoading: false,
      });
    } catch (err: any) {
      this.setState({
        isLoading: false,
        error: err.message || 'Registration failed',
      });
      throw err;
    }
  }

  /**
   * 4. Request Phone OTP (Starts 300s Countdown)
   */
  async requestPhoneOtp(phone: string): Promise<void> {
    this.setState({ isLoading: true, error: null });
    try {
      const result = await authService.requestPhoneOtp({ phone });
      this.startOtpCountdown(result.expiresInSeconds || 300);
      this.setState({ isLoading: false });
    } catch (err: any) {
      this.setState({
        isLoading: false,
        error: err.message || 'Failed to send OTP',
      });
      throw err;
    }
  }

  /**
   * 5. Verify Phone OTP
   */
  async verifyPhoneOtp(payload: VerifyOtpPayload): Promise<void> {
    this.setState({ isLoading: true, error: null });
    try {
      const data = await authService.verifyPhoneOtp(payload);
      this.clearOtpCountdown();
      this.setState({
        user: data.user,
        isAuthenticated: true,
        activePortal: data.user.activePortal || 'CUSTOMER',
        isLoading: false,
      });
    } catch (err: any) {
      this.setState({
        isLoading: false,
        error: err.message || 'Invalid OTP code',
      });
      throw err;
    }
  }

  /**
   * 6. Switch Active Portal Workspace (Customer / Organizer / Host)
   */
  switchPortal(portal: ActivePortal): void {
    if (this.state.user) {
      const updatedUser = { ...this.state.user, activePortal: portal };
      storage.setUserProfile(updatedUser);
      this.setState({ activePortal: portal, user: updatedUser });
    } else {
      this.setState({ activePortal: portal });
    }
  }

  /**
   * 7. Logout Flow
   */
  async logout(): Promise<void> {
    this.setState({ isLoading: true });
    try {
      await authService.logout();
    } finally {
      this.clearOtpCountdown();
      this.setState({
        user: null,
        isAuthenticated: false,
        isLoading: false,
        activePortal: 'CUSTOMER',
      });
    }
  }

  // ── OTP Timer Internals ───────────────────────────────────────────────────

  private startOtpCountdown(seconds = 300): void {
    this.clearOtpCountdown();
    this.setState({ otpCountdownSeconds: seconds });

    this.otpTimerInterval = setInterval(() => {
      const remaining = this.state.otpCountdownSeconds - 1;
      if (remaining <= 0) {
        this.clearOtpCountdown();
      } else {
        this.setState({ otpCountdownSeconds: remaining });
      }
    }, 1000);
  }

  private clearOtpCountdown(): void {
    if (this.otpTimerInterval) {
      clearInterval(this.otpTimerInterval);
      this.otpTimerInterval = null;
    }
    this.setState({ otpCountdownSeconds: 0 });
  }
}

// Global Singleton Export
export const authStore = new AuthStore();
