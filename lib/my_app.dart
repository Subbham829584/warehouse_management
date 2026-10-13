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
      _demoRepo ??= MemoryInventoryRepository();
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
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final isAuthWaiting =
            authSnapshot.connectionState == ConnectionState.waiting;

        if (isAuthWaiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (user == null && !_isDemo) {
          final loginRepo = MemoryInventoryRepository(seed: false);
          return AppScope(
            repo: loginRepo,
            auth: _authService,
            isDemo: false,
            userEmail: '',
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Warehouse Management',
              theme: AppTheme.light(),
              builder: (context, child) => AppScope(
                repo: loginRepo,
                auth: _authService,
                isDemo: false,
                userEmail: '',
                child: child!,
              ),
              home: LoginPage(
                onDemo: () => setState(() => _isDemo = true),
              ),
            ),
          );
        }

        if (_isDemo) {
          _demoRepo ??= MemoryInventoryRepository(seed: true);
          return AppScope(
            repo: _demoRepo!,
            auth: null,
            isDemo: true,
            userEmail: 'demo@warehouse.io',
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Warehouse Management',
              theme: AppTheme.light(),
              builder: (context, child) => AppScope(
                repo: _demoRepo!,
                auth: null,
                isDemo: true,
                userEmail: 'demo@warehouse.io',
                child: child!,
              ),
              home: AppShell(
                onSignOut: () async {
                  setState(() {
                    _isDemo = false;
                    _demoRepo = null;
                  });
                },
              ),
            ),
          );
        }

        // Firebase authenticated user
        return FutureBuilder<String>(
          future: WarehouseBootstrap.resolve(user!),
          builder: (context, whSnap) {
            final warehouseId = whSnap.data ?? 'Aa3SUKLQScIhcYYkBB1K';
            final repo = FirestoreInventoryRepository(warehouseId: warehouseId);
            final email = user.email ?? 'User';

            return AppScope(
              repo: repo,
              auth: _authService,
              isDemo: false,
              userEmail: email,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Warehouse Management',
                theme: AppTheme.light(),
                builder: (context, child) => AppScope(
                  repo: repo,
                  auth: _authService,
                  isDemo: false,
                  userEmail: email,
                  child: child!,
                ),
                home: whSnap.connectionState == ConnectionState.waiting
                    ? const Scaffold(
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
                      )
                    : AppShell(
                        onSignOut: () => _authService.signOut(),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
