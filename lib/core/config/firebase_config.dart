import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Configuration helper for Firebase initialization
class FirebaseConfig {
  /// Initialize Firebase Core for iOS & Android
  static Future<void> initialize() async {
    // Note: On Android & iOS, Firebase reads configuration from:
    // - android/app/google-services.json
    // - ios/Runner/GoogleService-Info.plist
    try {
      await Firebase.initializeApp();
      if (kDebugMode) {
        print('Firebase initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization notice: $e');
        print('Ensure google-services.json (Android) / GoogleService-Info.plist (iOS) are placed in respective folders.');
      }
    }
  }
}
