import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'dummy-api-key',
      appId: '1:123456789:android:abcdef',
      messagingSenderId: '123456789',
      projectId: 'dummy-project',
      storageBucket: 'dummy-project.appspot.com',
    );
  }
}
