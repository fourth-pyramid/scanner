import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:qrscanner/core/appStorage/app_storage.dart';
import 'package:qrscanner/core/di/injection_container.dart';
import 'package:qrscanner/core/dioHelper/dio_helper.dart';
import 'package:qrscanner/core/router/router.dart';
import 'package:qrscanner/core/theme/app_theme.dart';
import 'package:qrscanner/features/app_disabled_view.dart';
import 'package:qrscanner/features/settings/presentation/settings_view.dart';
import 'package:qrscanner/firebase_options.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)
        ..badCertificateCallback = (cert, host, port) => true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object catch (_) {
    // Firebase initialization failed
  }

  HttpOverrides.global = MyHttpOverrides();

  try {
    await AppStorage.init();
    await initDependencies();
    DioHelper.initBaseUrl();

    runApp(const MyApp());
  } on Object catch (_) {
    // App initialization failed
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('app_control')
        .doc('status')
        .snapshots(),
    builder: (context, snapshot) {
      // Wait state
      if (snapshot.connectionState == ConnectionState.waiting) {
        return MaterialApp(
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          debugShowCheckedModeBanner: false,
          // Apply new theme right away
          theme: AppTheme.lightTheme,
        );
      }

      // Error state
      if (snapshot.hasError) {
        return MaterialApp(
          home: const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Error connecting to server.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
        );
      }

      // Data available state
      final isAppEnabled = (snapshot.data?.get('enabled') as bool?) ?? false;

      if (!isAppEnabled) {
        return MaterialApp(
          home: const AppDisabledView(),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
        );
      }

      // App enabled
      return MaterialApp(
        home: const SettingsView(),
        onGenerateRoute: onGenerateRoute,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AppTheme.lightTheme, // Inject the new design system
      );
    },
  );
}
