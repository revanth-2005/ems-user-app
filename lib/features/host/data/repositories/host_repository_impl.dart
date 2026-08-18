import '../../domain/entities/host_entities.dart';
import '../../domain/repositories/host_repository.dart';
import '../datasources/host_local_datasource.dart';

class HostRepositoryImpl implements HostRepository {
  final HostLocalDataSource _local;

  HostRepositoryImpl(this._local);

  @override
  Future<List<HostEventItem>> getHostedEvents() async {
    return _local.getEvents();
  }

  @override
  Future<HostEventItem> createEvent(HostEventItem event) async {
    return _local.createEvent(event);
  }

  @override
  Future<List<AttendeeRecord>> getAttendees(String eventId) async {
    return _local.getAttendees(eventId);
  }

  @override
  Future<QrCheckInResult> scanQrCode(String eventId, String qrData) async {
    return _local.scanQrCode(eventId, qrData);
  }

  @override
  Future<bool> manualCheckIn(String eventId, String attendeeId) async {
    return _local.manualCheckIn(eventId, attendeeId);
  }
}
