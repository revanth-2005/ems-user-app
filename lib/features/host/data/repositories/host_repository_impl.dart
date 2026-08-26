import '../../domain/entities/host_entities.dart';
import '../../domain/repositories/host_repository.dart';
import '../datasources/host_remote_datasource.dart';

class HostRepositoryImpl implements HostRepository {
  final HostRemoteDataSource _remote;

  HostRepositoryImpl(this._remote);

  @override
  Future<List<HostEventItem>> getHostedEvents() async {
    return _remote.getEvents();
  }

  @override
  Future<HostEventItem?> getEventDetails(String id) async {
    return _remote.getEventDetails(id);
  }

  @override
  Future<HostEventItem> createEvent(CreateEventRequest req) async {
    return _remote.createEvent(req);
  }

  @override
  Future<HostEventItem> updateEvent(String id, Map<String, dynamic> data) async {
    return _remote.updateEvent(id, data);
  }

  @override
  Future<HostEventItem> publishEvent(String id) async {
    return _remote.publishEvent(id);
  }

  @override
  Future<GenerateMeetResponse> generateMeetRoom(String title) async {
    return _remote.generateMeetRoom(title);
  }

  @override
  Future<Map<String, dynamic>> createTicketTier(
    String eventId,
    CreateTicketTierRequest tier,
  ) async {
    return _remote.createTicketTier(eventId, tier);
  }

  @override
  Future<Map<String, dynamic>> updateTicketTier(
    String ticketTypeId,
    Map<String, dynamic> data,
  ) async {
    return _remote.updateTicketTier(ticketTypeId, data);
  }

  @override
  Future<bool> deleteTicketTier(String ticketTypeId) async {
    return _remote.deleteTicketTier(ticketTypeId);
  }

  @override
  Future<List<HostRegistration>> getAttendeeQueue(
    String eventId, {
    String? status,
  }) async {
    return _remote.getAttendeeQueue(eventId, status: status);
  }

  @override
  Future<bool> approveRegistration(
    String registrationId, {
    String? hostMessage,
  }) async {
    return _remote.approveRegistration(registrationId, hostMessage: hostMessage);
  }

  @override
  Future<bool> declineRegistration(
    String registrationId, {
    String? hostMessage,
  }) async {
    return _remote.declineRegistration(registrationId, hostMessage: hostMessage);
  }

  @override
  Future<CheckInResponse> checkInAttendee(String eventId, String qrCode) async {
    return _remote.checkInAttendee(eventId, qrCode);
  }

  @override
  Future<BulkCheckInResponse> bulkCheckIn(
    String eventId, {
    required String registrationId,
    int? count,
  }) async {
    return _remote.bulkCheckIn(eventId, registrationId: registrationId, count: count);
  }

  @override
  Future<GateCheckInStats> getCheckInStats(String eventId) async {
    return _remote.getCheckInStats(eventId);
  }

  @override
  Future<Map<String, dynamic>> getCalendarLinks(String eventId) async {
    return _remote.getCalendarLink(eventId);
  }

  @override
  Future<List<AttendeeRecord>> getAttendees(String eventId) async {
    return _remote.getAttendees(eventId);
  }

  @override
  Future<QrCheckInResult> scanQrCode(String eventId, String qrData) async {
    return _remote.scanQrCode(eventId, qrData);
  }

  @override
  Future<bool> manualCheckIn(String eventId, String attendeeId) async {
    return _remote.manualCheckIn(eventId, attendeeId);
  }

  @override
  Future<List<EventSubscriptionPlan>> getEventSubscriptionPlans() async {
    return _remote.getEventSubscriptionPlans();
  }

  @override
  Future<UserEventSubscriptionResponse> getCurrentUserEventSubscription() async {
    return _remote.getCurrentUserEventSubscription();
  }

  @override
  Future<SelectPlanResponse> selectEventSubscriptionPlan({
    required String tier,
    required String billingCycle,
  }) async {
    return _remote.selectEventSubscriptionPlan(
      tier: tier,
      billingCycle: billingCycle,
    );
  }

  @override
  Future<Map<String, dynamic>> verifyPayment({
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  }) async {
    return _remote.verifyPayment(
      gatewayOrderId: gatewayOrderId,
      gatewayPaymentId: gatewayPaymentId,
      gatewaySignature: gatewaySignature,
    );
  }
}

