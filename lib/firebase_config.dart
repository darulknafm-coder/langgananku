import 'package:firebase_core/firebase_core.dart';

/// Konfigurasi proyek Firebase LanggananKu (Android).
/// Nilai-nilai ini berasal dari google-services.json. Ini BUKAN rahasia:
/// keamanan data diatur oleh aturan Firestore (hanya pemilik akun yang bisa
/// membaca/menulis datanya sendiri).
///
/// Bila dikosongkan, aplikasi berjalan tanpa login (mode pengembangan).
const FirebaseOptions kFirebaseAndroid = FirebaseOptions(
  apiKey: 'AIzaSyAuyVwZgvLnyOtjZMVhATz4YgY2JYAxPp4',
  appId: '1:602366753488:android:6f374dbbb5234b59603cd5',
  messagingSenderId: '602366753488',
  projectId: 'langgananku-ada63',
  storageBucket: 'langgananku-ada63.firebasestorage.app',
);

bool get firebaseConfigured => kFirebaseAndroid.apiKey.isNotEmpty;
