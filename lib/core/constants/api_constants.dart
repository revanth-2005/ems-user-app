/// Centralized API Constants & Base URL Configuration.
/// All API endpoints and backend host URLs are defined here in one single place.
class ApiConstants {
  // ── 🌐 Centralized Base URL Configuration ──────────────────────────────────
  static const String serverHost = '192.168.0.173';
  static const String serverPort = '3001';          // Backend Port
  static const String apiPrefix  = '';              // Live backend routes mount directly at root

  /// Active Base URL: http://localhost:3001
  static String get baseUrl => 'http://$serverHost:$serverPort$apiPrefix';

  // ── 🔐 Auth Endpoints ──────────────────────────────────────────────────────
  static const String signupEmail   = '/auth/signup/email';
  static const String loginEmail    = '/auth/login/email';
  static const String loginPhone    = '/auth/login/phone';
  static const String verifyOtp     = '/auth/verify-otp';
  static const String refreshToken  = '/auth/refresh';
  static const String logout        = '/auth/logout';
  static const String googleAuth    = '/auth/google';

  // ── 👤 User Endpoints ──────────────────────────────────────────────────────
  static const String userProfile   = '/users/me';
  static const String userAddresses = '/users/me/addresses';

  // ── 📦 Master & Catalog Endpoints ──────────────────────────────────────────
  static const String masterCategories = '/master/categories';
  static const String catalogPackages  = '/catalog/packages';
  static const String catalogServices  = '/catalog/services';
  static const String catalogEvents    = '/catalog/events';
  static const String catalogOrganizers = '/catalog/organizers';

  // ── 🛒 Cart & Checkout Endpoints ───────────────────────────────────────────
  static const String cart        = '/cart';
  static const String cartItems   = '/cart/items';
  static const String checkout    = '/checkout';
  static const String myBookings  = '/bookings/my-bookings';

  // ── 💳 Payments Endpoints ──────────────────────────────────────────────────
  static const String createPaymentOrder = '/payments/create-order';
  static const String verifyPayment      = '/payments/verify';

  // ── 🏢 Organizer Portal Endpoints ──────────────────────────────────────────
  static const String organizerUpload           = '/organizer/upload';
  static const String organizerRegister         = '/organizer/register';
  static const String organizerOnboardingStatus = '/organizer/onboarding/status';
  static const String organizerBusinessType     = '/organizer/onboarding/business-type';
  static const String organizerSelectPlan       = '/organizer/subscription/select-plan';
  static const String organizerPackages         = '/organizer/packages';
  static const String organizerServices         = '/organizer/services';
  static const String organizerAvailability     = '/organizer/availability';
  static const String organizerBookings         = '/organizer/bookings';
  static const String organizerPayouts          = '/organizer/payouts';

  // ── 🎟️ Host & Ticketing Endpoints ───────────────────────────────────────────
  static const String hostEvents        = '/host/events';
  static const String hostAttendeeQueue = '/host/events/{id}/attendee-queue';
  static const String hostCheckIn       = '/host/events/{id}/check-in';
  static const String myTickets         = '/catalog/events/my-tickets/all';
}
