// File ini sengaja ada agar `flutter create` tidak membuat contoh test
// bawaan (yang merujuk ke MyApp dan pasti gagal).
import 'package:flutter_test/flutter_test.dart';
import 'package:langgananku/utils/format.dart';

void main() {
  test('format rupiah', () {
    // Hapus spasi/non-breaking space apa pun yang mungkin dipakai locale.
    expect(rupiah(54000).replaceAll(RegExp(r'\s'), ''), 'Rp54.000');
  });
}
