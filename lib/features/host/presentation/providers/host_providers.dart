import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/host_remote_datasource.dart';
import '../../data/repositories/host_repository_impl.dart';
import '../../domain/entities/host_entities.dart';
import '../../domain/repositories/host_repository.dart';

// ── Repository Providers ──────────────────────────────────────────────────

final hostRemoteDataSourceProvider = Provider<HostRemoteDataSource>((_) {
  return HostRemoteDataSource(DioClient.instance.dio);
});

final hostRepositoryProvider = Provider<HostRepository>((ref) {
  return HostRepositoryImpl(ref.watch(hostRemoteDataSourceProvider));
});

// ── Hosted Events Notifier ────────────────────────────────────────────────

final hostedEventsProvider =
    AsyncNotifierProvider<HostedEventsNotifier, List<HostEventItem>>(
        HostedEventsNotifier.new);

class HostedEventsNotifier extends AsyncNotifier<List<HostEventItem>> {
  @override
  Future<List<HostEventItem>> build() async {
    final repo = ref.watch(hostRepositoryProvider);
    return repo.getHostedEvents();
  }

  Future<void> createEvent(HostEventItem event) async {
    final repo = ref.read(hostRepositoryProvider);
    await repo.createEvent(event);
    state = AsyncData(await repo.getHostedEvents());
  }
}

// ── Attendees Queue Family Provider ───────────────────────────────────────

final attendeesQueueProvider =
    FutureProvider.family<List<AttendeeRecord>, String>((ref, eventId) async {
  final repo = ref.watch(hostRepositoryProvider);
  return repo.getAttendees(eventId);
});
