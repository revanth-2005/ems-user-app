import '../entities/host_entities.dart';

abstract class HostRepository {
  Future<List<HostEventItem>> getHostedEvents();
  Future<HostEventItem> createEvent(HostEventItem event);
  Future<List<AttendeeRecord>> getAttendees(String eventId);
  Future<QrCheckInResult> scanQrCode(String eventId, String qrData);
  Future<bool> manualCheckIn(String eventId, String attendeeId);
}
