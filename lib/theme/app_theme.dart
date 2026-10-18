import 'package:flutter/material.dart';

/// Sistem warna LanggananKu: charcoal gelap + aksen lime.
class AppColors {
  static const bg = Color(0xFF0E0F12);
  static const surface = Color(0xFF16181D);
  static const surface2 = Color(0xFF1E2127);
  static const surface3 = Color(0xFF262A31);
  static const line = Color(0xFF2A2E36);
  static const lineStrong = Color(0xFF3A3F48);
  static const text = Color(0xFFF2F4F7);
  static const muted = Color(0xFF9AA3AF);
  static const faint = Color(0xFF6B7380);

  static const lime = Color(0xFFB8F34A);
  static const limeDeep = Color(0xFF2B3A12);
  static const onLime = Color(0xFF0E0F12);

  static const coral = Color(0xFFFF6B5E);
  static const coralDeep = Color(0xFF3A1B19);
  static const amber = Color(0xFFFFC857);
  static const amberDeep = Color(0xFF3A2E12);
  static const sky = Color(0xFF5AC8FA);

  /// Warna kategori untuk grafik (tanpa ungu).
  static const chart = [
    lime,
    sky,
    amber,
    coral,
    Color(0xFF7EE0C3),
    Color(0xFFF2F4F7),
    Color(0xFFFF9F43),
    Color(0xFF9AA3AF),
  ];
}

const String kFont = 'PlusJakartaSans';

/// Angka rata kolom (tabular) untuk nominal rupiah.
const List<FontFeature> kTabular = [FontFeature.tabularFigures()];

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.lime,
    onPrimary: AppColors.onLime,
    primaryContainer: AppColors.limeDeep,
    onPrimaryContainer: AppColors.lime,
    secondary: AppColors.sky,
    onSecondary: AppColors.onLime,
    secondaryContainer: AppColors.surface2,
    onSecondaryContainer: AppColors.text,
    tertiary: AppColors.lime,
    onTertiary: AppColors.onLime,
    tertiaryContainer: AppColors.limeDeep,
    onTertiaryContainer: AppColors.lime,
    error: AppColors.coral,
    onError: AppColors.onLime,
    errorContainer: AppColors.coralDeep,
    onErrorContainer: Color(0xFFFFB4AB),
    surface: AppColors.bg,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.muted,
    surfaceContainerLowest: AppColors.bg,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surface2,
    surfaceContainerHighest: AppColors.surface3,
    outline: AppColors.lineStrong,
    outlineVariant: AppColors.line,
    inverseSurface: AppColors.text,
    onInverseSurface: AppColors.bg,
    inversePrimary: AppColors.limeDeep,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  final shape14 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: kFont,
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontFamily: kFont, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.onLime,
        disabledBackgroundColor: AppColors.surface3,
        textStyle: const TextStyle(fontFamily: kFont, fontWeight: FontWeight.w700, fontSize: 15),
        shape: shape14,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.lineStrong),
        textStyle: const TextStyle(fontFamily: kFont, fontWeight: FontWeight.w600, fontSize: 15),
        shape: shape14,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lime,
        textStyle: const TextStyle(fontFamily: kFont, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.lime,
      foregroundColor: AppColors.onLime,
      elevation: 0,
      highlightElevation: 0,
      shape: StadiumBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.limeDeep,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: kFont,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? AppColors.lime : AppColors.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? AppColors.lime : AppColors.muted,
            size: 24,
          )),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.lime : AppColors.surface),
        foregroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.onLime : AppColors.muted),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.line)),
        textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: kFont, fontWeight: FontWeight.w600)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.lime,
      checkmarkColor: AppColors.onLime,
      side: const BorderSide(color: AppColors.line),
      labelStyle: const TextStyle(fontFamily: kFont, fontWeight: FontWeight.w600, color: AppColors.text),
      secondaryLabelStyle:
          const TextStyle(fontFamily: kFont, fontWeight: FontWeight.w700, color: AppColors.onLime),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.onLime : AppColors.muted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.lime : AppColors.surface3),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.lime : Colors.transparent),
      checkColor: const WidgetStatePropertyAll(AppColors.onLime),
      side: const BorderSide(color: AppColors.lineStrong, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.lime,
      inactiveTrackColor: AppColors.surface3,
      thumbColor: AppColors.lime,
      overlayColor: Color(0x33B8F34A),
      valueIndicatorColor: AppColors.lime,
      valueIndicatorTextStyle:
          TextStyle(fontFamily: kFont, color: AppColors.onLime, fontWeight: FontWeight.w700),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.lime,
      linearTrackColor: AppColors.surface3,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.muted,
      textColor: AppColors.text,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
      contentTextStyle:
          const TextStyle(fontFamily: kFont, color: AppColors.bg, fontWeight: FontWeight.w600),
      shape: shape14,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: AppColors.lineStrong,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    timePickerTheme: const TimePickerThemeData(
      backgroundColor: AppColors.surface,
    ),
  );
}
