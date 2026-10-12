import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warehouse_management/core/app_scope.dart';
import 'package:warehouse_management/core/app_theme.dart';
import 'package:warehouse_management/repositories/firestore_inventory_repository.dart';
import 'package:warehouse_management/repositories/memory_inventory_repository.dart';
import 'package:warehouse_management/screens/app_shell.dart';
import 'package:warehouse_management/screens/login_page.dart';
import 'package:warehouse_management/services/auth_service.dart';
import 'package:warehouse_management/services/warehouse_bootstrap.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  bool _isDemo = false;
  MemoryInventoryRepository? _demoRepo;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Warehouse Management',
      theme: AppTheme.light(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_isDemo) {
      _demoRepo ??= MemoryInventoryRepository(seed: true);
      return AppScope(
        repo: _demoRepo!,
        auth: null,
        isDemo: true,
        userEmail: 'demo@warehouse.io',
        child: AppShell(
          onSignOut: () async {
            setState(() {
              _isDemo = false;
              _demoRepo = null;
            });
          },
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: _authService.authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return AppScope(
            repo: MemoryInventoryRepository(seed: false),
            auth: _authService,
            isDemo: false,
            userEmail: '',
            child: LoginPage(
              onDemo: () {
                setState(() {
                  _isDemo = true;
                });
              },
            ),
          );
        }

        return FutureBuilder<String>(
          future: WarehouseBootstrap.resolve(user),
          builder: (context, whSnap) {
            if (whSnap.hasError) {
              final fallbackRepo = FirestoreInventoryRepository(
                warehouseId: 'Aa3SUKLQScIhcYYkBB1K',
              );
              return AppScope(
                repo: fallbackRepo,
                auth: _authService,
                isDemo: false,
                userEmail: user.email ?? 'User',
                child: AppShell(
                  onSignOut: () => _authService.signOut(),
                ),
              );
            }

            if (!whSnap.hasData) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Connecting to warehouse...'),
                    ],
                  ),
                ),
              );
            }

            final repo = FirestoreInventoryRepository(
              warehouseId: whSnap.data!,
            );
            return AppScope(
              repo: repo,
              auth: _authService,
              isDemo: false,
              userEmail: user.email ?? 'User',
              child: AppShell(
                onSignOut: () => _authService.signOut(),
              ),
            );
          },
        );
      },
    );
  }
}
