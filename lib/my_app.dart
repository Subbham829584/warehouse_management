import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warehouse_management/screens/home.dart';
import 'package:warehouse_management/screens/login.dart';
import 'package:warehouse_management/screens/splash.dart';
import 'package:warehouse_management/services/warehouse_service.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class MyApp extends StatelessWidget {
  final Future<void> _initialization = WarehouseService.instance.initialize();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Warehouse Management',
      theme: ThemeData(
        fontFamily: 'Nunito',
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: ColorPalette.white,
          primary: ColorPalette.pacificBlue,
        ),
      ),
      home: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return StreamBuilder<bool>(
              stream: WarehouseService.instance.authStateChanges,
              initialData: WarehouseService.instance.isAuthenticated,
              builder: (context, authSnapshot) {
                if (authSnapshot.data == true) {
                  return Home();
                } else {
                  return Login();
                }
              },
            );
          }
          return Splash();
        },
      ),
    );
  }
}
