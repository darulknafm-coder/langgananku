import 'package:flutter/material.dart';

/// Satu set warna (terang atau gelap).
class Palette {
  final Brightness brightness;
  final Color bg, surface, surface2, surface3, line, lineStrong, text, muted, faint;
  final Color accent, accentSoft, onAccent, accentText;
  final Color coral, coralSoft, amber, amberSoft, sky, skySoft;
  final Color heroFrom; // warna awal gradasi kartu total

  const Palette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.accentText,
    required this.coral,
    required this.coralSoft,
    required this.amber,
    required this.amberSoft,
    required this.sky,
    required this.skySoft,
    required this.heroFrom,
  });

  bool get isDark => brightness == Brightness.dark;
}

/// Tema terang: putih bersih + hijau toska.
const Palette kLight = Palette(
  brightness: Brightness.light,
  bg: Color(0xFFF5F7F7),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFF0F4F4),
  surface3: Color(0xFFE5ECEC),
  line: Color(0xFFE1E8E8),
  lineStrong: Color(0xFFC9D4D4),
  text: Color(0xFF13201F),
  muted: Color(0xFF5B6B6B),
  faint: Color(0xFF94A3A3),
  accent: Color(0xFF0E9C97),
  accentSoft: Color(0xFFDDF4F2),
  onAccent: Color(0xFFFFFFFF),
  accentText: Color(0xFF087A76),
  coral: Color(0xFFDC3E42),
  coralSoft: Color(0xFFFDE8E8),
  amber: Color(0xFFB86E00),
  amberSoft: Color(0xFFFFF1DB),
  sky: Color(0xFF1F6FD1),
  skySoft: Color(0xFFE3EEFC),
  heroFrom: Color(0xFFE2F6F4),
);

/// Tema gelap: abu kehijauan pekat + toska terang.
const Palette kDark = Palette(
  brightness: Brightness.dark,
  bg: Color(0xFF0D1213),
  surface: Color(0xFF151C1D),
  surface2: Color(0xFF1C2526),
  surface3: Color(0xFF253031),
  line: Color(0xFF263133),
  lineStrong: Color(0xFF384547),
  text: Color(0xFFEDF3F3),
  muted: Color(0xFF9AAAAA),
  faint: Color(0xFF627273),
  accent: Color(0xFF2DD4BF),
  accentSoft: Color(0xFF0F2F2C),
  onAccent: Color(0xFF032420),
  accentText: Color(0xFF5EE6D3),
  coral: Color(0xFFFF6B5E),
  coralSoft: Color(0xFF3A1B19),
  amber: Color(0xFFFFC857),
  amberSoft: Color(0xFF3A2E12),
  sky: Color(0xFF5AC8FA),
  skySoft: Color(0xFF13293A),
  heroFrom: Color(0xFF103230),
);

/// Warna yang sedang aktif. Diatur ulang di [MaterialApp.builder] setiap kali
/// tema terang/gelap berganti (layar dibangun ulang saat itu).
///
/// Nama lama (lime, limeDeep, onLime, …) dipertahankan sebagai alias supaya
/// kode layar tetap sederhana: "lime" = warna aksen utama.
class AppColors {
  static Palette p = kDark;

  static Color get bg => p.bg;
  static Color get surface => p.surface;
  static Color get surface2 => p.surface2;
  static Color get surface3 => p.surface3;
  static Color get line => p.line;
  static Color get lineStrong => p.lineStrong;
  static Color get text => p.text;
  static Color get muted => p.muted;
  static Color get faint => p.faint;

  static Color get lime => p.accent;
  static Color get limeDeep => p.accentSoft;
  static Color get onLime => p.onAccent;
  static Color get accentText => p.accentText;

  static Color get coral => p.coral;
  static Color get coralDeep => p.coralSoft;
  static Color get amber => p.amber;
  static Color get amberDeep => p.amberSoft;
  static Color get sky => p.sky;
  static Color get skyDeep => p.skySoft;
  static Color get heroFrom => p.heroFrom;

  /// Teks di atas warna peringatan (coral) yang solid.
  static Color get onCoral => Colors.white;

  /// Warna kategori untuk grafik (tanpa ungu).
  static List<Color> get chart => [
        p.accent,
        p.sky,
        p.amber,
        p.coral,
        p.isDark ? const Color(0xFF7EE0C3) : const Color(0xFF3BA776),
        p.isDark ? const Color(0xFFEDF3F3) : const Color(0xFF34495E),
        p.isDark ? const Color(0xFFFF9F43) : const Color(0xFFE07B1F),
        p.muted,
      ];
}

const String kFont = 'PlusJakartaSans';

/// Angka rata kolom (tabular) untuk nominal rupiah.
const List<FontFeature> kTabular = [FontFeature.tabularFigures()];

ThemeData buildAppTheme(Palette c) {
  final scheme = ColorScheme(
    brightness: c.brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    primaryContainer: c.accentSoft,
    onPrimaryContainer: c.accentText,
    secondary: c.sky,
    onSecondary: c.onAccent,
    secondaryContainer: c.surface2,
    onSecondaryContainer: c.text,
    tertiary: c.accent,
    onTertiary: c.onAccent,
    tertiaryContainer: c.accentSoft,
    onTertiaryContainer: c.accentText,
    error: c.coral,
    onError: Colors.white,
    errorContainer: c.coralSoft,
    onErrorContainer: c.coral,
    surface: c.bg,
    onSurface: c.text,
    onSurfaceVariant: c.muted,
    surfaceContainerLowest: c.bg,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface,
    surfaceContainerHighest: c.surface3,
    outline: c.lineStrong,
    outlineVariant: c.line,
    inverseSurface: c.text,
    onInverseSurface: c.bg,
    inversePrimary: c.accentSoft,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  final shape14 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

  return ThemeData(
    useMaterial3: true,
    brightness: c.brightness,
    colorScheme: scheme,
    fontFamily: kFont,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontFamily: kFont, fontSize: 20, fontWeight: FontWeight.w700, color: c.text),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        disabledBackgroundColor: c.surface3,
        textStyle: const TextStyle(fontFamily: kFont, fontWeight: FontWeight.w700, fontSize: 15),
        shape: shape14,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        side: BorderSide(color: c.lineStrong),
        textStyle: const TextStyle(fontFamily: kFont, fontWeight: FontWeight.w600, fontSize: 15),
        shape: shape14,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accentText,
        textStyle: const TextStyle(fontFamily: kFont, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: c.onAccent,
      elevation: c.isDark ? 0 : 2,
      highlightElevation: 0,
      shape: const StadiumBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.accentSoft,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: kFont,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? c.accentText : c.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? c.accentText : c.muted,
            size: 24,
          )),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.accent : c.surface),
        foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.onAccent : c.muted),
        side: WidgetStatePropertyAll(BorderSide(color: c.line)),
        textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: kFont, fontWeight: FontWeight.w600)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.accent,
      checkmarkColor: c.onAccent,
      side: BorderSide(color: c.line),
      labelStyle: TextStyle(fontFamily: kFont, fontWeight: FontWeight.w600, color: c.text),
      secondaryLabelStyle:
          TextStyle(fontFamily: kFont, fontWeight: FontWeight.w700, color: c.onAccent),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onAccent : c.muted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.surface3),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : Colors.transparent),
      checkColor: WidgetStatePropertyAll(c.onAccent),
      side: BorderSide(color: c.lineStrong, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.surface3,
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: c.muted,
      textColor: c.text,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.text,
      actionTextColor: c.isDark ? kLight.accent : kDark.accent,
      contentTextStyle: TextStyle(fontFamily: kFont, color: c.bg, fontWeight: FontWeight.w600),
      shape: shape14,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: c.lineStrong,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
    ),
    timePickerTheme: TimePickerThemeData(backgroundColor: c.surface),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: c.muted,
      collapsedIconColor: c.muted,
      textColor: c.text,
      collapsedTextColor: c.text,
      shape: const Border(),
      collapsedShape: const Border(),
    ),
  );
}
