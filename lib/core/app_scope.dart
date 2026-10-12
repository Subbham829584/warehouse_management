import 'package:flutter/material.dart';
import 'package:warehouse_management/repositories/inventory_repository.dart';
import 'package:warehouse_management/services/auth_service.dart';

/// Minimal dependency injection (no extra package needed).
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

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      repo != old.repo || isDemo != old.isDemo || userEmail != old.userEmail;
}
