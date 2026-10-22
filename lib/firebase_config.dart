import 'package:firebase_core/firebase_core.dart';

/// Konfigurasi proyek Firebase LanggananKu (Android).
/// Nilai-nilai ini berasal dari google-services.json. Ini BUKAN rahasia:
/// keamanan data diatur oleh aturan Firestore (hanya pemilik akun yang bisa
/// membaca/menulis datanya sendiri).
///
/// Selama masih kosong, aplikasi berjalan tanpa login (mode pengembangan).
const FirebaseOptions kFirebaseAndroid = FirebaseOptions(
  apiKey: '',
  appId: '',
  messagingSenderId: '',
  projectId: '',
  storageBucket: '',
);

bool get firebaseConfigured => kFirebaseAndroid.apiKey.isNotEmpty;
