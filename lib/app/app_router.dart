import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/views/login_screen.dart';
import '../features/auth/presentation/views/signup_screen.dart';
import '../features/auth/presentation/views/verify_otp_screen.dart';
import '../features/home/presentation/views/events_discovery_view.dart';
import '../features/home/presentation/views/home_discovery_screen.dart';
import '../features/home/presentation/views/search_filter_screen.dart';
import '../features/home/presentation/views/event_detail_screen.dart';
import '../features/home/presentation/views/package_detail_screen.dart';
import '../features/home/presentation/views/service_detail_screen.dart';
import '../features/home/presentation/views/organizer_profile_screen.dart';
import '../features/bookings/presentation/views/my_bookings_tickets_screen.dart';
import '../features/bookings/presentation/views/cart_checkout_screen.dart';
import '../features/organizer/presentation/views/organizer_dashboard_screen.dart';
import '../features/organizer/presentation/views/booking_inbox_screen.dart';
import '../features/organizer/presentation/views/catalog_manager_screen.dart';
import '../features/organizer/presentation/views/availability_calendar_screen.dart';
import '../features/organizer/presentation/views/payout_ledger_screen.dart';
import '../features/organizer/presentation/views/kyc_registration_screen.dart';
import '../features/organizer/presentation/views/onboarding_wizard_screen.dart';
import '../features/host/presentation/views/host_dashboard_screen.dart';
import '../features/host/presentation/views/create_event_screen.dart';
import '../features/host/presentation/views/event_management_hub_screen.dart';
import '../features/host/presentation/views/attendee_queue_screen.dart';
import '../features/host/presentation/views/qr_scanner_screen.dart';
import '../features/host/presentation/views/event_hosting_subscription_screen.dart';
import '../features/profile/presentation/views/customer_profile_screen.dart';
import '../features/profile/presentation/views/followed_organizers_screen.dart';
import '../features/notifications/presentation/views/notifications_screen.dart';
import '../features/chatbot/presentation/views/ai_chatbot_screen.dart';
import 'app_shell.dart';

// ── Named Route Paths ──────────────────────────────────────────────────────

abstract class AppRoutes {
  // Auth
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const otp = '/auth/otp';

  // AI Chatbot
  static const chatbot = '/chatbot';

  // Main shell tabs
  static const home = '/';
  static const search = '/search';
  static const bookings = '/bookings';
  static const profile = '/profile';
  static const eventsDiscovery = '/events';
  static const following = '/following';

  // Notifications
  static const notifications = '/notifications';

  // Detail screens
  static const eventDetail = '/detail/event/:id';
  static const packageDetail = '/detail/package/:id';
  static const serviceDetail = '/detail/service/:id';
  static const organizerProfile = '/organizer-profile/:id';

  // Cart
  static const cart = '/cart';

  // Host
  static const hostDashboard = '/host';
  static const hostSubscription = '/host/subscription';
  static const createEvent = '/host/create-event';
  static const hostCreateEvent = '/host/create-event';
  static const hostManagementHub = '/host/manage/:id';
  static const attendeeQueue = '/host/attendees/:id';
  static const qrScanner = '/host/scanner/:id';

  // Organizer
  static const organizerDashboard = '/organizer';
  static const bookingInbox = '/organizer/inbox';
  static const catalogManager = '/organizer/catalog';
  static const availabilityCalendar = '/organizer/calendar';
  static const payoutLedger = '/organizer/payouts';
  static const kycRegistration = '/organizer/kyc';
  static const onboardingWizard = '/organizer/onboarding';
}

// ── Router Notifier (State-aware refreshListenable) ───────────────────────

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final isLoggedIn = authState.valueOrNull != null;
    final isAuthRoute = state.matchedLocation.startsWith('/auth');

    if (!isLoggedIn && !isAuthRoute) {
      return AppRoutes.login;
    }
    if (isLoggedIn && isAuthRoute) {
      return AppRoutes.home;
    }
    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// GoRouter provider — kept alive for the app's lifetime.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    debugLogDiagnostics: false,

    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, state) => VerifyOtpScreen(
          target: state.uri.queryParameters['target'] ?? state.uri.queryParameters['phone'] ?? '',
          isSignup: state.uri.queryParameters['type'] == 'signup',
        ),
      ),

      // ── Main Shell ────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HomeDiscoveryScreen()),
          ),
          GoRoute(
            path: AppRoutes.search,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SearchFilterScreen()),
          ),
          GoRoute(
            path: AppRoutes.bookings,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: MyBookingsTicketsScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: CustomerProfileScreen()),
          ),
        ],
      ),

      // ── Detail Screens ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.eventsDiscovery,
        builder: (_, __) => const EventsDiscoveryView(),
      ),
      GoRoute(
        path: AppRoutes.eventDetail,
        builder: (_, state) =>
            EventDetailScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.packageDetail,
        builder: (_, state) =>
            PackageDetailScreen(packageId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.serviceDetail,
        builder: (_, state) =>
            ServiceDetailScreen(serviceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.organizerProfile,
        builder: (_, state) =>
            OrganizerProfileScreen(organizerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.following,
        builder: (_, __) => const FollowedOrganizersScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatbot,
        builder: (_, __) => const AiChatbotScreen(),
      ),

      // ── Cart ──────────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.cart, builder: (_, __) => const CartCheckoutScreen()),

      // ── Host ──────────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.hostDashboard, builder: (_, __) => const HostDashboardScreen()),
      GoRoute(path: AppRoutes.hostSubscription, builder: (_, __) => const EventHostingSubscriptionScreen()),
      GoRoute(path: AppRoutes.createEvent, builder: (_, __) => const CreateEventScreen()),
      GoRoute(
        path: AppRoutes.hostManagementHub,
        builder: (_, state) =>
            EventManagementHubScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.attendeeQueue,
        builder: (_, state) =>
            AttendeeQueueScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.qrScanner,
        builder: (_, state) =>
            QrScannerScreen(eventId: state.pathParameters['id']!),
      ),

      // ── Organizer ─────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.organizerDashboard, builder: (_, __) => const OrganizerDashboardScreen()),
      GoRoute(path: AppRoutes.bookingInbox, builder: (_, __) => const BookingInboxScreen()),
      GoRoute(path: AppRoutes.catalogManager, builder: (_, __) => const CatalogManagerScreen()),
      GoRoute(path: AppRoutes.availabilityCalendar, builder: (_, __) => const AvailabilityCalendarScreen()),
      GoRoute(path: AppRoutes.payoutLedger, builder: (_, __) => const PayoutLedgerScreen()),
      GoRoute(path: AppRoutes.kycRegistration, builder: (_, __) => const KycRegistrationScreen()),
      GoRoute(path: AppRoutes.onboardingWizard, builder: (_, __) => const OnboardingWizardScreen()),
    ],
  );
});
