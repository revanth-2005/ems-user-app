import '../entities/host_entities.dart';

abstract class HostRepository {
  Future<List<HostEventItem>> getHostedEvents();
  Future<HostEventItem?> getEventDetails(String id);
  Future<HostEventItem> createEvent(CreateEventRequest req);
  Future<HostEventItem> updateEvent(String id, Map<String, dynamic> data);
  Future<HostEventItem> publishEvent(String id);
  Future<GenerateMeetResponse> generateMeetRoom(String title);
  Future<Map<String, dynamic>> createTicketTier(String eventId, CreateTicketTierRequest tier);
  Future<Map<String, dynamic>> updateTicketTier(String ticketTypeId, Map<String, dynamic> data);
  Future<bool> deleteTicketTier(String ticketTypeId);
  Future<List<HostRegistration>> getAttendeeQueue(String eventId, {String? status});
  Future<bool> approveRegistration(String registrationId, {String? hostMessage});
  Future<bool> declineRegistration(String registrationId, {String? hostMessage});
  Future<CheckInResponse> checkInAttendee(String eventId, String qrCode);
  Future<BulkCheckInResponse> bulkCheckIn(String eventId, {required String registrationId, int? count});
  Future<GateCheckInStats> getCheckInStats(String eventId);
  Future<Map<String, dynamic>> getCalendarLinks(String eventId);

  // Subscriptions & Quota
  Future<List<EventSubscriptionPlan>> getEventSubscriptionPlans();
  Future<UserEventSubscriptionResponse> getCurrentUserEventSubscription();
  Future<SelectPlanResponse> selectEventSubscriptionPlan({required String tier, required String billingCycle});
  Future<Map<String, dynamic>> verifyPayment({required String gatewayOrderId, required String gatewayPaymentId, required String gatewaySignature});

  // Legacy signatures
  Future<List<AttendeeRecord>> getAttendees(String eventId);
  Future<QrCheckInResult> scanQrCode(String eventId, String qrData);
  Future<bool> manualCheckIn(String eventId, String attendeeId);
}
