import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'repository.dart';

/// Menyimpan salinan data langganan di akun (Firestore: users/{uid}/data/backup),
/// supaya data aman saat ganti HP. Data di HP tetap jadi sumber utama;
/// perubahan diunggah otomatis beberapa detik setelah disimpan.
class SyncService {
  static Timer? _debounce;
  static String? _uid;

  static DocumentReference<Map<String, dynamic>> _doc(String uid) => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('data')
      .doc('backup');

  /// Dipanggil setelah login. Mengambil data dari akun bila lebih baru,
  /// atau mengunggah data HP bila akun masih kosong.
  static Future<void> start(String uid) async {
    final repo = Repo.instance;
    if (_uid != null && _uid != uid) {
      // Akun berbeda dari sebelumnya → jangan campur data.
      await repo.resetLocal();
    }
    _uid = uid;
    Repo.onChanged = _schedule;
    try {
      final snap = await _doc(uid).get().timeout(const Duration(seconds: 10));
      final m = snap.data();
      final raw = m?['json'] as String?;
      final cloudTime = DateTime.tryParse((m?['changedAt'] as String?) ?? '');
      if (raw != null && cloudTime != null) {
        if (!repo.hasData || cloudTime.isAfter(repo.lastChange)) {
          await repo.applyCloud(raw, cloudTime);
          return;
        }
      }
      if (repo.hasData) await upload();
    } catch (_) {
      // offline → lanjut pakai data di HP, unggah nanti
    }
  }

  static void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () => upload());
  }

  static Future<void> upload() async {
    final uid = _uid;
    if (uid == null || AuthService.user?.uid != uid) return;
    final repo = Repo.instance;
    try {
      await _doc(uid).set({
        'json': repo.exportJson(),
        'changedAt': repo.lastChange.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));
    } catch (_) {
      // Firestore menyimpan antrean tulis offline dan mengirimnya nanti.
    }
  }

  /// Sebelum keluar: kirim perubahan terakhir, lalu bersihkan data di HP.
  static Future<void> stop({bool uploadFirst = true}) async {
    _debounce?.cancel();
    if (uploadFirst) await upload();
    Repo.onChanged = null;
    _uid = null;
    await Repo.instance.resetLocal();
  }
}
