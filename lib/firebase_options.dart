import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for your app
///
/// To get these values:
/// 1. Go to https://console.firebase.google.com/
/// 2. Create a new project or select an existing one
/// 3. Click on the web platform (</>) to add a web app
/// 4. Register your app and copy the configuration
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for $defaultTargetPlatform - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
    }
  }

  /// Replace these placeholder values with your Firebase configuration
  /// Get these values from your Firebase Console -> Project Settings -> Web App
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',  // Get from Firebase Console
    appId: '1:1234567890:web:abcdef1234567890',          // Get from Firebase Console
    messagingSenderId: '1234567890',                      // Get from Firebase Console
    projectId: 'your-project-id',                         // Get from Firebase Console
    authDomain: 'your-project-id.firebaseapp.com',        // Get from Firebase Console
    storageBucket: 'your-project-id.appspot.com',         // Get from Firebase Console
    measurementId: 'G-XXXXXXXXXX',                        // Get from Firebase Console (optional)
  );
} 