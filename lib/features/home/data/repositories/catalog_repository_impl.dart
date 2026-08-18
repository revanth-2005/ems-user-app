import '../../domain/entities/catalog_entities.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_local_datasource.dart';
import '../datasources/catalog_remote_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogRemoteDataSource _remote;
  final CatalogLocalDataSource _local;

  CatalogRepositoryImpl({
    required CatalogRemoteDataSource remote,
    required CatalogLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final res = await _remote.getCategories();
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return _local.getCategories();
  }

  @override
  Future<List<EventPackage>> getPackages({String city = 'Mumbai'}) async {
    try {
      final res = await _remote.getPackages(city: city);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return _local.getPackages();
  }

  @override
  Future<List<StandaloneService>> getServices({String city = 'Mumbai'}) async {
    try {
      final res = await _remote.getServices(city: city);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return _local.getServices();
  }

  @override
  Future<List<PublicEvent>> getEvents() async {
    try {
      final res = await _remote.getEvents();
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return _local.getEvents();
  }

  @override
  Future<EventPackage?> getPackageById(String id) async {
    final pkgs = await getPackages();
    try {
      return pkgs.firstWhere((p) => p.id == id);
    } catch (_) {
      return pkgs.isNotEmpty ? pkgs.first : null;
    }
  }

  @override
  Future<PublicEvent?> getEventById(String id) async {
    final evts = await getEvents();
    try {
      return evts.firstWhere((e) => e.id == id);
    } catch (_) {
      return evts.isNotEmpty ? evts.first : null;
    }
  }

  @override
  Future<StandaloneService?> getServiceById(String id) async {
    final srvs = await getServices();
    try {
      return srvs.firstWhere((s) => s.id == id);
    } catch (_) {
      return srvs.isNotEmpty ? srvs.first : null;
    }
  }
}
