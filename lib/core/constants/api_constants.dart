/// Centralized API Constants & Base URL Configuration.
/// All API endpoints and backend host URLs are defined here in one single place.
class ApiConstants {
  // ── 🌐 Centralized Base URL Configuration ──────────────────────────────────
  static const String baseUrl = 'http://192.168.0.190:3001';
  static const String serverHost = '192.168.0.190';
  static const String serverPort = '3001';          // Backend / Proxy Port
  static const String apiPrefix  = '';          // Live backend routes mount directly at root
  static const String chatEndpoint = '$baseUrl/chat';
  static const String chat = '/chat';

  /// MinIO Media Storage Base URL (Local MinIO on port 6006)
  static const String mediaBaseUrl = 'http://192.168.0.190:6006';

  // ── 🔐 Auth Endpoints ──────────────────────────────────────────────────────
  static const String signupEmail   = '/auth/signup/email';
  static const String loginEmail    = '/auth/login/email';
  static const String loginPhone    = '/auth/login/phone';
  static const String verifyOtp     = '/auth/verify-otp';
  static const String refreshToken  = '/auth/refresh';
  static const String logout        = '/auth/logout';
  static const String googleAuth    = '/auth/google';
  static const String googleAuthMobile = '/auth/google/mobile';
  static const String googleWebClientId =
      '1046270070303-14805ic3j0fdlv6s97r96vi2p30lqols.apps.googleusercontent.com';

  // ── 👤 User Endpoints ──────────────────────────────────────────────────────
  static const String userProfile   = '/users/me';
  static const String userAddresses = '/users/me/addresses';
  static const String updateFcmToken = '/users/me/fcm-token';

  // ── 📦 Master & Catalog Endpoints ──────────────────────────────────────────
  static const String masterCategories             = '/master/categories';
  static const String masterEventCategories        = '/master/event-categories';
  static const String masterEventSubscriptionPlans = '/master/event-subscription-plans';
  static const String catalogPackages              = '/catalog/packages';
  static const String catalogServices              = '/catalog/services';
  static const String catalogEvents                = '/catalog/events';
  static const String calculateEventFee            = '/catalog/events/calculate-fee';
  static const String catalogOrganizers            = '/catalog/organizers';

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
  static const String hostEvents                    = '/host/events';
  static const String userEventSubscriptionCurrent  = '/organizer/user-event-subscription/current';
  static const String userEventSubscriptionSelectPlan = '/organizer/user-event-subscription/select-plan';
  static const String hostGenerateMeet              = '/host/meetings/generate-meet';
  static const String hostAttendeeQueue             = '/host/events/{id}/attendee-queue';
  static const String hostApproveRegistration       = '/host/events/registrations/{id}/approve';
  static const String hostDeclineRegistration = '/host/events/registrations/{id}/decline';
  static const String hostCheckIn             = '/host/events/{id}/check-in';
  static const String hostCheckInBulk         = '/host/events/{id}/check-in/bulk';
  static const String hostCheckInStats        = '/host/events/{id}/check-in/stats';
  static const String hostPublishEvent        = '/host/events/{id}/publish';
  static const String hostTicketTypes         = '/host/events/{id}/ticket-types';
  static const String hostTicketTypeDetail    = '/host/events/ticket-types/{id}';
  static const String myTickets               = '/catalog/events/my-tickets/all';
  static const String registerEvent           = '/catalog/events/{id}/register';
  static const String createTicketOrder       = '/catalog/events/{id}/create-ticket-order';
  static const String eventCalendarLink       = '/catalog/events/{id}/calendar-link';

  // ── 🔍 Multi-Dimensional Search & Discovery Endpoints ──────────────────────
  static const String searchAutocomplete = '/search/autocomplete';
  static const String searchUnified      = '/search/unified';
  static const String searchPackages     = '/search/packages';
  static const String searchServices     = '/search/services';
  static const String searchOrganizers   = '/search/organizers';
  static const String searchEvents       = '/search/events';

  // ── ⭐ Follow / Unfollow Endpoints ──────────────────────────────────────────
  static const String followOrganizer    = '/organizers/{id}/follow';
  static const String unfollowOrganizer  = '/organizers/{id}/unfollow';
  static const String followStatus       = '/organizers/{id}/follow-status';
  static const String followedOrganizers = '/users/me/followed-organizers';
  static const String organizerFollowers = '/organizers/{id}/followers';

  // ── 💸 Ticket & Booking Cancellation & Automated Refund Endpoints ──────────
  static const String registrationRefundQuote = '/registrations/{id}/refund-quote';
  static const String cancelRegistration      = '/registrations/{id}/cancel';
  static const String bookingRefundQuote       = '/bookings/{id}/refund-quote';
  static const String cancelBookingEndpoint   = '/bookings/{id}/cancel';

  // ── 🔔 In-App Notifications Endpoints ─────────────────────────────────────
  static const String notificationsMe           = '/notifications/me';
  static const String markNotificationRead      = '/notifications/{id}/read';
  static const String markAllNotificationsRead  = '/notifications/mark-all-read';
}
