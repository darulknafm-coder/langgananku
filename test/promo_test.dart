import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:langgananku/data/catalog.dart';
import 'package:langgananku/services/promo_service.dart';

void main() {
  test('promos.json valid dan semua layanan ada di katalog', () {
    final raw = File('assets/data/promos.json').readAsStringSync();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final list = (j['services'] as List)
        .map((e) => ServicePromo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    expect(list, isNotEmpty);
    for (final s in list) {
      expect(catalogByKey(s.key), isNotNull, reason: s.key);
      expect(s.plans, isNotEmpty, reason: s.key);
    }
    // Salinan di docs (dibaca aplikasi dari internet) harus sama dengan bawaan.
    expect(File('docs/promos.json').readAsStringSync(), raw);
  });

  test('domain logo katalog', () {
    expect(catalogByKey('netflix')!.domain, 'netflix.com');
    expect(catalogByKey('spotify')!.domain, 'spotify.com');
    expect(catalogByKey('claude')!.domain, 'claude.ai');
    for (final c in kCatalog) {
      expect(c.domain.contains('.'), isTrue, reason: c.key);
    }
  });
}
