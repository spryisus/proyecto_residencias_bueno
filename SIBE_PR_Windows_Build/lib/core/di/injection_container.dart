// Dependency injection container
// Note: This requires get_it package to be added to pubspec.yaml

import '../../data/datasources/inventario_datasource.dart';
import '../../data/local/inventory_session_storage.dart';
import '../../data/repositories/inventario_repository_impl.dart';
import '../../domain/repositories/inventario_repository.dart';

// Simple service locator pattern without external dependencies
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  void registerSingleton<T>(T service) {
    _services[T] = service;
  }

  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not registered');
    }
    return service as T;
  }
}

final ServiceLocator serviceLocator = ServiceLocator();

void setupDependencies() {
  // Datasources
  serviceLocator.registerSingleton<InventarioDataSource>(
    SupabaseInventarioDataSource(),
  );

  // Repositories
  serviceLocator.registerSingleton<InventarioRepository>(
    InventarioRepositoryImpl(serviceLocator.get<InventarioDataSource>()),
  );

  // Local storage
  serviceLocator.registerSingleton<InventorySessionStorage>(
    InventorySessionStorage(),
  );
}
