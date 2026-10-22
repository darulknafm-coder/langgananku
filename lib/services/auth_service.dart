import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_config.dart';

/// Profil pengguna yang disimpan di akun.
class UserProfile {
  final String name;
  final String email;
  final String phone;
  const UserProfile({required this.name, required this.email, required this.phone});
}

/// Pesan kesalahan login dalam bahasa sehari-hari.
class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);
  @override
  String toString() => message;
}

/// Login dengan email & password (Firebase Authentication).
/// Profil (nama, email, nomor HP) disimpan di Firestore: users/{uid}.
class AuthService {
  static bool _ready = false;

  /// false = aplikasi berjalan tanpa login (pratinjau web, data contoh,
  /// atau Firebase belum dikonfigurasi).
  static bool get available => _ready;

  static Future<void> init() async {
    if (kIsWeb || const bool.fromEnvironment('DEMO')) return;
    if (!Platform.isAndroid || !firebaseConfigured) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: kFirebaseAndroid)
            .timeout(const Duration(seconds: 10));
      }
      await FirebaseAuth.instance.setLanguageCode('id');
      _ready = true;
    } catch (e) {
      debugPrint('Firebase init gagal: $e');
      _ready = false;
    }
  }

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static User? get user => _ready ? _auth.currentUser : null;
  static Stream<User?> get changes => _auth.authStateChanges();

  static DocumentReference<Map<String, dynamic>> _profileDoc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  /// Nomor HP dalam format +62…  ("0812…", "812…", "+62812…" → "+62812…").
  static String normalizePhone(String raw) {
    var d = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.startsWith('+62')) return d;
    d = d.replaceAll('+', '');
    if (d.startsWith('62')) return '+$d';
    if (d.startsWith('0')) d = d.substring(1);
    return '+62$d';
  }

  static Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      final u = cred.user!;
      await u.updateDisplayName(name.trim());
      await _profileDoc(u.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': normalizePhone(phone),
        'createdAt': FieldValue.serverTimestamp(),
      });
      unawaited(u.sendEmailVerification().catchError((_) {}));
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code, e.message));
    } on FirebaseException catch (e) {
      throw AuthFailure('Gagal menyimpan profil (${e.code}). Coba lagi.');
    }
  }

  static Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code, e.message));
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  static Future<void> resendVerification() async {
    try {
      await user?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  /// Perbarui status verifikasi email dari server.
  static Future<bool> refreshVerified() async {
    try {
      await user?.reload();
    } catch (_) {}
    return user?.emailVerified ?? false;
  }

  static Future<UserProfile?> profile() async {
    final u = user;
    if (u == null) return null;
    try {
      final d = await _profileDoc(u.uid).get().timeout(const Duration(seconds: 8));
      final m = d.data() ?? {};
      return UserProfile(
        name: (m['name'] as String?) ?? u.displayName ?? '',
        email: (m['email'] as String?) ?? u.email ?? '',
        phone: (m['phone'] as String?) ?? '',
      );
    } catch (_) {
      return UserProfile(name: u.displayName ?? '', email: u.email ?? '', phone: '');
    }
  }

  static Future<void> updateProfile({required String name, required String phone}) async {
    final u = user;
    if (u == null) return;
    await u.updateDisplayName(name.trim());
    await _profileDoc(u.uid).set(
        {'name': name.trim(), 'phone': normalizePhone(phone)}, SetOptions(merge: true));
  }

  static Future<void> signOut() => _auth.signOut();

  /// Hapus akun beserta semua data di server. Wajib memasukkan password lagi.
  static Future<void> deleteAccount(String password) async {
    final u = user;
    if (u == null) return;
    try {
      await u.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: u.email!, password: password));
      final doc = _profileDoc(u.uid);
      final data = await doc.collection('data').get();
      for (final d in data.docs) {
        await d.reference.delete();
      }
      await doc.delete();
      await u.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    } on FirebaseException catch (e) {
      throw AuthFailure('Gagal menghapus data (${e.code}). Periksa internet lalu coba lagi.');
    }
  }

  static String _message(String code, [String? detail]) {
    final d = detail ?? '';
    if (d.contains('CONFIGURATION_NOT_FOUND') || code == 'operation-not-allowed') {
      return 'Layanan login belum aktif di server. Hubungi pengembang aplikasi.';
    }
    if (code == 'unknown' && d.isNotEmpty) return 'Terjadi kesalahan: $d';
    return _messageFor(code);
  }

  static String _messageFor(String code) => switch (code) {
        'email-already-in-use' => 'Email ini sudah terdaftar. Silakan masuk.',
        'invalid-email' => 'Format email tidak valid.',
        'weak-password' => 'Password terlalu lemah. Gunakan minimal 8 karakter.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Email atau password salah.',
        'user-disabled' => 'Akun ini dinonaktifkan.',
        'too-many-requests' => 'Terlalu banyak percobaan. Tunggu beberapa menit.',
        'network-request-failed' => 'Tidak ada koneksi internet.',
        'requires-recent-login' => 'Demi keamanan, masuk ulang lalu coba lagi.',
        _ => 'Terjadi kesalahan ($code). Coba lagi.',
      };
}
