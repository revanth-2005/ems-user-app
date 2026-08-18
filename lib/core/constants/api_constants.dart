class ApiConstants {
  // In Android Emulator: 10.0.2.2 points to host machine
  // In Physical Device: user can configure LAN IP (e.g. 192.168.x.x)
  // Default port is 6001 for ems-api, or 3001
  static const String defaultHost = '10.0.2.2';
  static const String defaultPort = '6001';
  static const String apiPrefix = '/api/v1';

  static String get baseUrl => 'http://$defaultHost:$defaultPort$apiPrefix';

  // Auth Endpoints
  static const String signupEmail = '/auth/signup/email';
  static const String loginEmail = '/auth/login/email';
  static const String loginPhone = '/auth/login/phone';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';

  // User Endpoints
  static const String userProfile = '/users/me';
  static const String userAddresses = '/users/me/addresses';

  // Master & Catalog Endpoints
  static const String masterCategories = '/master/categories';
  static const String catalogPackages = '/catalog/packages';
  static const String catalogServices = '/catalog/services';
  static const String catalogEvents = '/catalog/events';

  // Cart & Checkout Endpoints
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static const String checkout = '/checkout';
  static const String myBookings = '/bookings/my-bookings';

  // Organizer Endpoints
  static const String organizerUpload = '/organizer/upload';
  static const String organizerRegister = '/organizer/register';
  static const String organizerOnboardingStatus = '/organizer/onboarding/status';
  static const String organizerBusinessType = '/organizer/onboarding/business-type';
  static const String organizerSelectPlan = '/organizer/subscription/select-plan';
  static const String organizerPackages = '/organizer/packages';
  static const String organizerServices = '/organizer/services';
  static const String organizerAvailability = '/organizer/availability';
  static const String organizerBookings = '/organizer/bookings';
  static const String organizerPayouts = '/organizer/payouts';

  // Host Endpoints
  static const String hostEvents = '/host/events';
  static const String hostAttendeeQueue = '/host/events/{id}/attendee-queue';
  static const String hostCheckIn = '/host/events/{id}/check-in';
  static const String myTickets = '/catalog/events/my-tickets/all';
}
