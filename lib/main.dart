import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/service_providers.dart';
import 'core/services/hive_service.dart';
import 'firebase_options.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Hive BEFORE anything uses it
    final hiveService = HiveService();
    await hiveService.init();

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          hiveServiceProvider.overrideWithValue(hiveService),
        ],
        child: const AITreasureHuntApp(),
      ),
    );
  } catch (e, st) {
    debugPrint("APP STARTUP ERROR: $e");
    debugPrintStack(stackTrace: st);

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Startup Error\n\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
