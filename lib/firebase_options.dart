// Generated Firebase configuration for PeerLearnHub.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      /*case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;*/
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /*static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3n63w46s_EiUTdbCCXhkzZbIR6hiQmGA',
    appId: '1:536687852853:android:5b342c3bb3c3447682e07c',
    messagingSenderId: '536687852853',
    projectId: 'peerlearnhub-d7db3',
    storageBucket: 'peerlearnhub-d7db3.firebasestorage.app',
  );*/

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCXH4zUH0lEGIipgJb-L_vLxrvLa2TCm8U",
    authDomain: "peerlearnhub-d7db3.firebaseapp.com",
    projectId: "peerlearnhub-d7db3",
    storageBucket: "peerlearnhub-d7db3.firebasestorage.app",
    messagingSenderId: "536687852853",
    appId: "1:536687852853:web:92506a8aa56369a582e07c",
    measurementId: "G-WTT6R0RT1F",
  );

  /*static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB...',
    appId: '1:1234567890:ios:def456...',
    messagingSenderId: '1234567890',
    projectId: 'peerlearnhub-xxxxx',
    authDomain: 'peerlearnhub-xxxxx.firebaseapp.com',
    storageBucket: 'peerlearnhub-xxxxx.appspot.com',
    androidClientId: '1234567890-xxx.apps.googleusercontent.com',
    iosClientId: '1234567890-yyy.apps.googleusercontent.com',
    iosBundleId: 'com.yourcompany.peerlearnhub',
  );*/
}
