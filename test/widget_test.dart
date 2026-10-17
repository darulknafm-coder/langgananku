// File ini sengaja ada agar `flutter create` tidak membuat contoh test
// bawaan (yang merujuk ke MyApp dan pasti gagal).
import 'package:flutter_test/flutter_test.dart';
import 'package:langgananku/utils/format.dart';

void main() {
  test('format rupiah', () {
    expect(rupiah(54000).replaceAll(' ', ''), 'Rp54.000');
  });
}
