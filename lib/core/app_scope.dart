import 'package:flutter/material.dart';
import 'package:warehouse_management/repositories/inventory_repository.dart';
import 'package:warehouse_management/repositories/memory_inventory_repository.dart';
import 'package:warehouse_management/services/auth_service.dart';

/// Dependency injection scope providing the active InventoryRepository.
/// Access anywhere: `AppScope.of(context).repo`.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repo,
    required this.auth,
    required this.isDemo,
    required this.userEmail,
    required super.child,
  });

  final InventoryRepository repo;
  final AuthService? auth; // null in demo mode
  final bool isDemo;
  final String userEmail;

  static AppScope? _lastKnownScope;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope != null) {
      _lastKnownScope = scope;
      return scope;
    }
    if (_lastKnownScope != null) {
      return _lastKnownScope!;
    }
    // Safe fallback scope to guarantee no route ever crashes
    final fallback = AppScope(
      repo: MemoryInventoryRepository(seed: true),
      auth: null,
      isDemo: true,
      userEmail: 'demo@warehouse.io',
      child: const SizedBox.shrink(),
    );
    _lastKnownScope = fallback;
    return fallback;
  }

  @override
  bool updateShouldNotify(AppScope old) {
    final should = repo != old.repo || isDemo != old.isDemo || userEmail != old.userEmail;
    if (should) _lastKnownScope = this;
    return should;
  }
}
