import '../../domain/entities/catalog_entities.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogRemoteDataSource _remote;

  CatalogRepositoryImpl({
    required CatalogRemoteDataSource remote,
  }) : _remote = remote;

  @override
  Future<List<Category>> getCategories() async {
    return _remote.getCategories();
  }

  @override
  Future<List<EventPackage>> getPackages({String city = 'Mumbai'}) async {
    return _remote.getPackages(city: city);
  }

  @override
  Future<List<StandaloneService>> getServices({String city = 'Mumbai'}) async {
    return _remote.getServices(city: city);
  }

  @override
  Future<List<PublicEvent>> getEvents() async {
    return _remote.getEvents();
  }

  @override
  Future<EventPackage?> getPackageById(String id) async {
    final pkgs = await getPackages();
    try {
      return pkgs.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PublicEvent?> getEventById(String id) async {
    final evts = await getEvents();
    try {
      return evts.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StandaloneService?> getServiceById(String id) async {
    final srvs = await getServices();
    try {
      return srvs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
