import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../features/bookings/domain/repositories/booking_repository.dart';
import '../../features/bookings/presentation/providers/booking_providers.dart';

/// Service managing the lifecycle of Razorpay Payment Gateway Checkout.
/// Implements the Server-Initiated Order & Double-Verification Pattern:
/// 1. POST /payments/create-order -> returns gatewayOrderId & Razorpay key
/// 2. Razorpay.open(options) -> launches native checkout SDK
/// 3. POST /payments/verify -> HMAC-SHA256 signature verification on backend
class RazorpayService {
  final BookingRepository _bookingRepo;
  late final Razorpay _razorpay;

  // Active payment callbacks
  void Function(Map<String, dynamic> data)? _onSuccessCallback;
  void Function(String message, bool isCancelled)? _onErrorCallback;

  RazorpayService(this._bookingRepo) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  /// Initiates the full Razorpay payment workflow.
  Future<void> startPaymentFlow({
    required int amountInPaise,
    String paymentType = 'DEPOSIT',
    String currency = 'INR',
    String? bookingId,
    String? registrationId,
    String? subscriptionId,
    String? orderId,
    String? userEmail,
    String? userPhone,
    String? userName,
    String? description,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message, bool isCancelled) onError,
  }) async {
    _onSuccessCallback = onSuccess;
    _onErrorCallback = onError;

    try {
      // 1. Create order on EMS backend
      final orderRes = await _bookingRepo.createPaymentOrder(
        amountInPaise: amountInPaise,
        paymentType: paymentType,
        currency: currency,
        bookingId: bookingId,
        registrationId: registrationId,
        subscriptionId: subscriptionId,
        orderId: orderId,
      );

      final key = (orderRes['key'] as String?) ?? 'rzp_test_YourKeyId';
      final gatewayOrderId = (orderRes['gatewayOrderId'] as String?);

      if (gatewayOrderId == null || gatewayOrderId.isEmpty) {
        throw Exception('Server did not return a valid Razorpay gatewayOrderId.');
      }

      final effectiveAmount = (orderRes['amountInPaise'] as int?) ?? amountInPaise;

      // 2. Configure Razorpay Mobile Options
      final options = <String, dynamic>{
        'key': key,
        'amount': effectiveAmount,
        'name': 'Event Management System',
        'order_id': gatewayOrderId,
        'description': description ?? 'Payment for $paymentType',
        'prefill': {
          if (userPhone != null && userPhone.isNotEmpty) 'contact': userPhone,
          if (userEmail != null && userEmail.isNotEmpty) 'email': userEmail,
          if (userName != null && userName.isNotEmpty) 'name': userName,
        },
        'theme': {
          'color': '#6366F1', // EMS Primary Brand Color
        },
        'retry': {
          'enabled': true,
          'max_count': 3,
        },
        'send_sms_hash': true,
      };

      debugPrint('💳 [RAZORPAY] Launching Checkout for Order: $gatewayOrderId, Amount: $effectiveAmount paise');
      _razorpay.open(options);
    } catch (e) {
      debugPrint('❌ [RAZORPAY ERROR] Failed to initiate checkout: $e');
      _onErrorCallback?.call(e.toString().replaceAll('Exception: ', ''), false);
    }
  }

  /// Directly launches Razorpay checkout for a pre-created Event Ticket Order.
  Future<void> startEventTicketPaymentFlow({
    required String key,
    required String gatewayOrderId,
    required int amountInPaise,
    String? userEmail,
    String? userPhone,
    String? userName,
    String? eventTitle,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message, bool isCancelled) onError,
  }) async {
    _onSuccessCallback = onSuccess;
    _onErrorCallback = onError;

    try {
      final options = <String, dynamic>{
        'key': key.isNotEmpty ? key : 'rzp_test_YourKeyId',
        'amount': amountInPaise,
        'name': 'EMS Events',
        'order_id': gatewayOrderId,
        'description': eventTitle != null ? 'Ticket Pass: $eventTitle' : 'Event Ticket Booking',
        'prefill': {
          if (userPhone != null && userPhone.isNotEmpty) 'contact': userPhone,
          if (userEmail != null && userEmail.isNotEmpty) 'email': userEmail,
          if (userName != null && userName.isNotEmpty) 'name': userName,
        },
        'theme': {
          'color': '#F05537', // Coral Brand Primary
        },
        'retry': {
          'enabled': true,
          'max_count': 3,
        },
        'send_sms_hash': true,
      };

      debugPrint('💳 [RAZORPAY EVENT] Launching Checkout for Ticket Order: $gatewayOrderId, Amount: $amountInPaise paise');
      _razorpay.open(options);
    } catch (e) {
      debugPrint('❌ [RAZORPAY EVENT ERROR] Failed to open checkout: $e');
      _onErrorCallback?.call(e.toString().replaceAll('Exception: ', ''), false);
    }
  }

  // ── SDK Event Callbacks ──────────────────────────────────────────────────

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ [RAZORPAY SUCCESS] Payment ID: ${response.paymentId}, Order ID: ${response.orderId}');
    final orderId = response.orderId;
    final paymentId = response.paymentId;
    final signature = response.signature;

    if (orderId == null || paymentId == null || signature == null) {
      _onErrorCallback?.call('Missing verification details from Razorpay SDK.', false);
      return;
    }

    try {
      // 3. Double-verify signature on EMS backend
      final verifyRes = await _bookingRepo.verifyPayment(
        gatewayOrderId: orderId,
        gatewayPaymentId: paymentId,
        gatewaySignature: signature,
      );

      if (verifyRes['success'] == true || verifyRes['payment'] != null) {
        _onSuccessCallback?.call(verifyRes);
      } else {
        _onErrorCallback?.call(
          verifyRes['message']?.toString() ?? 'Payment signature verification failed.',
          false,
        );
      }
    } catch (e) {
      debugPrint('❌ [RAZORPAY VERIFY ERROR] Verification failed: $e');
      _onErrorCallback?.call('Payment completed, but verification failed: $e', false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('⚠️ [RAZORPAY FAILURE] Code: ${response.code}, Message: ${response.message}');
    final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED ||
        response.code == 0 ||
        response.code == 2;
    final msg = response.message ?? 'Payment transaction was not completed.';
    _onErrorCallback?.call(msg, isCancelled);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('👛 [RAZORPAY WALLET] Selected External Wallet: ${response.walletName}');
  }
}

/// Provider for the singleton RazorpayService instance.
final razorpayServiceProvider = Provider<RazorpayService>((ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  return RazorpayService(repo);
});
