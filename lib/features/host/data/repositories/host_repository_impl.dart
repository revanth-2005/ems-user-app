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
  Future<HostEventItem> createEvent(HostEventItem event) async {
    return _remote.createEvent(event);
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
}
