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

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(hostRepositoryProvider).getHostedEvents());
  }

  Future<HostEventItem> createEvent(CreateEventRequest req) async {
    final repo = ref.read(hostRepositoryProvider);
    final created = await repo.createEvent(req);
    // Refresh events list
    final updated = await repo.getHostedEvents();
    state = AsyncData(updated);
    return created;
  }

  Future<void> publishEvent(String id) async {
    final repo = ref.read(hostRepositoryProvider);
    await repo.publishEvent(id);
    final updated = await repo.getHostedEvents();
    state = AsyncData(updated);
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    final repo = ref.read(hostRepositoryProvider);
    await repo.updateEvent(id, data);
    final updated = await repo.getHostedEvents();
    state = AsyncData(updated);
  }
}

// ── Single Host Event Detail Provider ─────────────────────────────────────

final hostEventDetailProvider =
    FutureProvider.autoDispose.family<HostEventItem?, String>((ref, eventId) async {
  final repo = ref.watch(hostRepositoryProvider);
  return repo.getEventDetails(eventId);
});

// ── Attendee Queue Notifier Family ─────────────────────────────────────────

final hostAttendeeQueueProvider =
    AsyncNotifierProvider.family<HostAttendeeQueueNotifier, List<HostRegistration>, String>(
        HostAttendeeQueueNotifier.new);

class HostAttendeeQueueNotifier
    extends FamilyAsyncNotifier<List<HostRegistration>, String> {
  @override
  Future<List<HostRegistration>> build(String arg) async {
    final repo = ref.watch(hostRepositoryProvider);
    return repo.getAttendeeQueue(arg);
  }

  Future<bool> approve(String registrationId, {String? hostMessage}) async {
    final repo = ref.read(hostRepositoryProvider);
    final success = await repo.approveRegistration(registrationId, hostMessage: hostMessage);
    if (success) {
      state = AsyncData(await repo.getAttendeeQueue(arg));
      // also refresh hosted events to update counts
      ref.read(hostedEventsProvider.notifier).refresh();
    }
    return success;
  }

  Future<bool> decline(String registrationId, {String? hostMessage}) async {
    final repo = ref.read(hostRepositoryProvider);
    final success = await repo.declineRegistration(registrationId, hostMessage: hostMessage);
    if (success) {
      state = AsyncData(await repo.getAttendeeQueue(arg));
      ref.read(hostedEventsProvider.notifier).refresh();
    }
    return success;
  }
}

// ── Gate Check-In Stats Provider ──────────────────────────────────────────

final hostGateStatsProvider =
    FutureProvider.autoDispose.family<GateCheckInStats?, String>((ref, eventId) async {
  final repo = ref.watch(hostRepositoryProvider);
  return repo.getCheckInStats(eventId);
});

// ── Legacy Provider for backward compatibility ────────────────────────────

final attendeesQueueProvider =
    FutureProvider.family<List<AttendeeRecord>, String>((ref, eventId) async {
  final repo = ref.watch(hostRepositoryProvider);
  return repo.getAttendees(eventId);
});

