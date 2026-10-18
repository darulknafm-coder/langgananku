import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Mengambil ikon resmi situs layanan (mis. netflix.com) sekali, lalu
/// menyimpannya di HP supaya berikutnya tampil tanpa internet.
///
/// Yang dikirim ke internet hanya nama domain layanan dari katalog,
/// tidak ada data pribadi.
class LogoService {
  static final Map<String, Uint8List?> _mem = {};
  static final Map<String, Future<Uint8List?>> _pending = {};
  static final Set<String> _failed = {};
  static SharedPreferences? _prefs;

  static bool enabled = true;

  static String _k(String domain) => 'logo_v1:$domain';

  /// Logo yang sudah ada di memori (tanpa menunggu).
  static Uint8List? cached(String domain) => _mem[domain];

  static Future<Uint8List?> get(String domain) {
    if (_mem.containsKey(domain)) return Future.value(_mem[domain]);
    return _pending[domain] ??= _load(domain).whenComplete(() => _pending.remove(domain));
  }

  static Future<Uint8List?> _load(String domain) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final saved = _prefs!.getString(_k(domain));
      if (saved != null) {
        final b = base64Decode(saved);
        _mem[domain] = b;
        return b;
      }
      if (!enabled || _failed.contains(domain)) return null;
      final uri = Uri.parse('https://www.google.com/s2/favicons?domain=$domain&sz=128');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      // Ikon "tidak ditemukan" dari layanan ini berukuran sangat kecil → abaikan.
      if (res.statusCode == 200 && res.bodyBytes.length > 400) {
        final b = res.bodyBytes;
        _mem[domain] = b;
        await _prefs!.setString(_k(domain), base64Encode(b));
        return b;
      }
      _failed.add(domain);
    } catch (_) {
      // offline / diblokir → pakai inisial
    }
    return null;
  }

  /// Hapus semua logo tersimpan (dipakai saat fitur logo dimatikan).
  static Future<void> clear() async {
    _mem.clear();
    _failed.clear();
    _prefs ??= await SharedPreferences.getInstance();
    for (final k in _prefs!.getKeys().where((k) => k.startsWith('logo_v1:')).toList()) {
      await _prefs!.remove(k);
    }
  }
}
