import 'dart:io';

import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

import 'detector.dart';

/// Membaca SMS kotak masuk (Android saja). iOS tidak mengizinkan aplikasi
/// membaca SMS — di iOS pengguna menempelkan email/nota secara manual.
class SmsScanner {
  /// Build tanpa fitur SMS: flutter build appbundle --dart-define=SMS_SCAN=false
  static const bool _enabled = bool.fromEnvironment('SMS_SCAN', defaultValue: true);

  static bool get supported => _enabled && Platform.isAndroid;

  static Future<List<RawMessage>> readInbox({int days = 400}) async {
    if (!supported) return [];
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      throw Exception('Izin membaca SMS ditolak. Anda tetap bisa menempelkan teks nota secara manual.');
    }
    final query = SmsQuery();
    final messages = await query.querySms(kinds: [SmsQueryKind.inbox], count: 3000);
    final since = DateTime.now().subtract(Duration(days: days));
    return [
      for (final m in messages)
        if ((m.date ?? DateTime.now()).isAfter(since) && (m.body ?? '').isNotEmpty)
          RawMessage(m.body!, m.date ?? DateTime.now(), m.address ?? ''),
    ];
  }
}
