// Menyiapkan file platform Android & iOS setelah `flutter create`.
//
// Jalankan dari folder proyek:
//   flutter create --org id.langgananku --project-name langgananku --platforms android,ios .
//   dart run tool/setup.dart
//
// Pengaturan lewat environment variable (opsional):
//   APP_ID    = ID aplikasi / bundle ID (default: id.langgananku.app)
//               PERMANEN setelah rilis pertama — tentukan sebelum upload!
//   SMS_SCAN  = true/false (default: true). false = izin READ_SMS dihapus
//               (untuk rilis Play Store bila deklarasi izin SMS belum disetujui).
import 'dart:io';

final String appId = Platform.environment['APP_ID'] ?? 'id.langgananku.app';
final bool smsScan = (Platform.environment['SMS_SCAN'] ?? 'true').toLowerCase() != 'false';

void main() {
  stdout.writeln('APP_ID   : $appId');
  stdout.writeln('SMS_SCAN : $smsScan\n');
  _android();
  _ios();
  stdout.writeln('\nSelesai. Lanjutkan: flutter pub get  →  flutter run');
}

void _android() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln('Folder android belum ada. Jalankan dulu:\n'
        '  flutter create --org id.langgananku --project-name langgananku --platforms android,ios .');
    exit(1);
  }
  var m = manifest.readAsStringSync();
  final perms = [
    if (smsScan) 'android.permission.READ_SMS',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.VIBRATE',
  ];
  if (!smsScan) {
    m = m.replaceAll(RegExp(r'\s*<uses-permission android:name="android.permission.READ_SMS"\s*/>'), '');
    // Pastikan izin SMS dari plugin juga ikut dibuang saat manifest digabung.
    if (!m.contains('xmlns:tools')) {
      m = m.replaceFirst('<manifest ', '<manifest xmlns:tools="http://schemas.android.com/tools" ');
    }
    if (!m.contains('tools:node="remove"')) {
      m = m.replaceFirst('<application',
          '<uses-permission android:name="android.permission.READ_SMS" tools:node="remove"/>\n    <uses-permission android:name="android.permission.RECEIVE_SMS" tools:node="remove"/>\n    <application');
    }
  }
  for (final p in perms) {
    if (!m.contains(p)) {
      m = m.replaceFirst('<application', '<uses-permission android:name="$p"/>\n    <application');
    }
  }
  m = m.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="LanggananKu"');
  if (!m.contains('ScheduledNotificationReceiver')) {
    const receivers = '''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>''';
    m = m.replaceFirst('</application>', receivers);
  }
  manifest.writeAsStringSync(m);
  stdout.writeln('✓ AndroidManifest.xml: izin ${smsScan ? 'SMS & ' : ''}notifikasi, receiver pengingat');

  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  if (kts.existsSync()) {
    kts.writeAsStringSync(_patchKts(kts.readAsStringSync()));
    stdout.writeln('✓ build.gradle.kts: applicationId, SDK 36, desugaring, signing rilis');
  } else if (groovy.existsSync()) {
    groovy.writeAsStringSync(_patchGroovy(groovy.readAsStringSync()));
    stdout.writeln('✓ build.gradle: applicationId, SDK 36, desugaring, signing rilis');
  } else {
    stderr.writeln('! build.gradle tidak ditemukan.');
    exit(1);
  }
}

String _patchKts(String g) {
  g = g.replaceFirst(RegExp(r'applicationId\s*=\s*"[^"]*"'), 'applicationId = "$appId"');
  g = g.replaceFirst(RegExp(r'compileSdk\s*=\s*[^\n]+'), 'compileSdk = 36');
  g = g.replaceFirst(RegExp(r'targetSdk\s*=\s*[^\n]+'), 'targetSdk = 36');
  if (!g.contains('isCoreLibraryDesugaringEnabled')) {
    g = g.replaceFirst('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true');
    g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n';
  }
  if (!g.contains('keystoreProperties')) {
    g = 'import java.io.FileInputStream\nimport java.util.Properties\n\n$g';
    g = g.replaceFirst(RegExp(r'\nandroid \{'), '''

// Kunci rilis dibaca dari android/key.properties (JANGAN di-commit ke Git).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {''');
    g = g.replaceFirst('    buildTypes {', '''    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {''');
    g = g.replaceFirst(RegExp(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)'),
        'signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")');
  }
  return g;
}

String _patchGroovy(String g) {
  g = g.replaceFirst(RegExp(r'applicationId\s*=?\s*"[^"]*"'), 'applicationId "$appId"');
  g = g.replaceFirst(RegExp(r'compileSdk(Version)?\s*=?\s*[^\n]+'), 'compileSdk 36');
  g = g.replaceFirst(RegExp(r'targetSdk(Version)?\s*=?\s*[^\n]+'), 'targetSdk 36');
  if (!g.contains('coreLibraryDesugaringEnabled')) {
    g = g.replaceFirst('compileOptions {', 'compileOptions {\n        coreLibraryDesugaringEnabled true');
    g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n";
  }
  if (!g.contains('keystoreProperties')) {
    g = g.replaceFirst(RegExp(r'\nandroid \{'), '''

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {''');
    g = g.replaceFirst('    buildTypes {', '''    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {''');
    g = g.replaceFirst(RegExp(r'signingConfig\s*=?\s*signingConfigs\.debug'),
        'signingConfig keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug');
  }
  return g;
}

void _ios() {
  final plist = File('ios/Runner/Info.plist');
  if (!plist.existsSync()) {
    stdout.writeln('- Folder ios tidak ada, dilewati.');
    return;
  }
  var p = plist.readAsStringSync();
  p = p.replaceFirst(
      RegExp(r'<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>'),
      '<key>CFBundleDisplayName</key>\n\t<string>LanggananKu</string>');
  // Aplikasi tidak memakai enkripsi khusus → lewati pertanyaan export compliance.
  if (!p.contains('ITSAppUsesNonExemptEncryption')) {
    p = p.replaceFirst('<dict>', '<dict>\n\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>');
  }
  plist.writeAsStringSync(p);
  stdout.writeln('✓ Info.plist: nama aplikasi, export compliance');

  final pbx = File('ios/Runner.xcodeproj/project.pbxproj');
  if (pbx.existsSync()) {
    var x = pbx.readAsStringSync();
    x = x.replaceAllMapped(
        RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*?\.langgananku(\.RunnerTests)?;'),
        (mm) => 'PRODUCT_BUNDLE_IDENTIFIER = $appId${mm.group(1) ?? ''};');
    pbx.writeAsStringSync(x);
    stdout.writeln('✓ Bundle ID iOS: $appId');
  }

  final delegate = File('ios/Runner/AppDelegate.swift');
  if (delegate.existsSync()) {
    var d = delegate.readAsStringSync();
    const line = 'GeneratedPluginRegistrant.register(with: self)';
    if (d.contains(line) && !d.contains('UNUserNotificationCenter')) {
      d = d.replaceFirst(line,
          '$line\n    if #available(iOS 10.0, *) {\n      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate\n    }');
      delegate.writeAsStringSync(d);
      stdout.writeln('✓ AppDelegate.swift: notifikasi foreground');
    }
  }
}
