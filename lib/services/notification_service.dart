import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/subscription.dart';
import '../utils/format.dart';

/// Pengingat jatuh tempo lokal (H-3 dan H-1), tanpa server.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'jatuh_tempo',
      'Pengingat jatuh tempo',
      channelDescription: 'Pengingat H-3 dan H-1 sebelum langganan ditagih',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(_guessLocation());
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings).timeout(const Duration(seconds: 5));
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Tentukan zona waktu dari offset perangkat (WIB/WITA/WIT diprioritaskan).
  static tz.Location _guessLocation() {
    final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
    for (final name in ['Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura']) {
      final loc = tz.getLocation(name);
      if (loc.currentTimeZone.offset == offsetMs) return loc;
    }
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.currentTimeZone.offset == offsetMs) return loc;
    }
    return tz.getLocation('Asia/Jakarta');
  }

  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      if (Platform.isAndroid) {
        final a = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await a?.requestNotificationsPermission() ?? false;
      }
      if (Platform.isIOS) {
        final i = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await i?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> showNow(String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.show(999, title, body, _details);
    } catch (_) {}
  }

  /// Jadwalkan ulang semua pengingat. iOS membatasi 64 notifikasi terjadwal,
  /// jadi hanya 60 terdekat yang dijadwalkan (diperbarui tiap app dibuka).
  static Future<void> reschedule(List<Subscription> subs,
      {required bool enabled, required int hour}) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      if (!enabled) return;
      final now = tz.TZDateTime.now(tz.local);
      final items = <(tz.TZDateTime, String, String)>[];
      for (final s in subs.where((s) => s.active)) {
        var due = s.nextDue;
        for (var k = 0; k < 2; k++) {
          for (final d in const [3, 1]) {
            final day = due.subtract(Duration(days: d));
            final when = tz.TZDateTime(tz.local, day.year, day.month, day.day, hour);
            if (when.isAfter(now)) {
              items.add((
                when,
                'Tagihan ${s.name} ${d == 1 ? 'besok' : '3 hari lagi'}',
                '${rupiah(s.amount)} akan ditagih ${tanggal(due)} via ${s.paymentMethod}. '
                    'Tidak dipakai? Batalkan sekarang.',
              ));
            }
          }
          due = s.cycle.nextFrom(due, s.anchorDay);
        }
      }
      items.sort((a, b) => a.$1.compareTo(b.$1));
      var id = 0;
      for (final it in items.take(60)) {
        await _plugin.zonedSchedule(
          id++,
          it.$2,
          it.$3,
          it.$1,
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {}
  }
}
