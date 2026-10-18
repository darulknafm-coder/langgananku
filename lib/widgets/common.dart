import 'dart:math' as math;

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';
import '../services/logo_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Logo layanan: ikon resmi situs layanan bila tersedia (diunduh sekali lalu
/// disimpan), selain itu kotak membulat berwarna brand + inisial.
class SubAvatar extends StatefulWidget {
  final String name;
  final int color;
  final double size;
  /// Kunci katalog (bila diketahui). Bila null dicocokkan dari nama.
  final String? logoKey;
  /// false = selalu inisial (mis. untuk nama orang).
  final bool logo;
  const SubAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 44,
    this.logoKey,
    this.logo = true,
  });

  @override
  State<SubAvatar> createState() => _SubAvatarState();
}

class _SubAvatarState extends State<SubAvatar> {
  Uint8List? _bytes;
  String? _domain;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(SubAvatar old) {
    super.didUpdateWidget(old);
    if (old.name != widget.name || old.logoKey != widget.logoKey) _resolve();
  }

  void _resolve() {
    _bytes = null;
    _domain = null;
    if (!widget.logo || !LogoService.enabled) return;
    final item = catalogByKey(widget.logoKey) ??
        kCatalog.where((c) => c.name.toLowerCase() == widget.name.trim().toLowerCase()).firstOrNull ??
        matchCatalog(widget.name);
    if (item == null) return;
    final domain = item.domain;
    _domain = domain;
    _bytes = LogoService.cached(domain);
    if (_bytes == null) {
      LogoService.get(domain).then((b) {
        if (mounted && b != null && _domain == domain) setState(() => _bytes = b);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final radius = BorderRadius.circular(size * 0.32);
    if (_bytes != null) {
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: Colors.white.withAlpha(18)),
        ),
        child: Image.memory(
          _bytes!,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _initials(size, radius),
        ),
      );
    }
    return _initials(size, radius);
  }

  Widget _initials(double size, BorderRadius radius) {
    final words = widget.name.trim().split(RegExp(r'\s+'));
    final initials = words.isEmpty || words.first.isEmpty
        ? '?'
        : (words.length == 1
                ? words.first.substring(0, words.first.length >= 2 ? 2 : 1)
                : '${words[0][0]}${words[1][0]}')
            .toUpperCase();
    final c = Color(widget.color);
    final light = c.computeLuminance() > 0.55;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c,
        borderRadius: radius,
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Text(initials,
          style: TextStyle(
              color: light ? AppColors.onLime : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.34,
              letterSpacing: 0.3)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 26, 2, 12),
      child: Row(children: [
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Kartu permukaan standar.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Material(
      color: color ?? AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: borderColor ?? AppColors.line),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Label kecil berbentuk kapsul.
class Pill extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  final IconData? icon;
  const Pill(this.text, {super.key, required this.fg, required this.bg, this.icon});

  factory Pill.due(DateTime due, {Key? key}) {
    final n = daysUntil(due);
    if (n <= 1) {
      return Pill(sisaHari(due), key: key, fg: AppColors.coral, bg: AppColors.coralDeep);
    }
    if (n <= 3) {
      return Pill(sisaHari(due), key: key, fg: AppColors.amber, bg: AppColors.amberDeep);
    }
    return Pill(sisaHari(due), key: key, fg: AppColors.muted, bg: AppColors.surface3);
  }

  /// Pill status untuk satu langganan: "Trial · 3 hari lagi" atau sisa hari tagihan.
  factory Pill.forSub(Subscription s, {Key? key}) {
    if (s.onTrial) {
      final n = daysUntil(s.nextDue);
      return Pill('Trial · ${sisaHari(s.nextDue).toLowerCase()}',
          key: key,
          icon: Icons.hourglass_top_rounded,
          fg: n <= 3 ? AppColors.coral : AppColors.sky,
          bg: n <= 3 ? AppColors.coralDeep : const Color(0x265AC8FA));
    }
    return Pill.due(s.nextDue, key: key);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
        ],
        Text(text,
            style: TextStyle(
                color: fg, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
      ]),
    );
  }
}

/// Baris langganan dalam daftar.
class SubTile extends StatelessWidget {
  final Subscription s;
  final VoidCallback? onTap;
  const SubTile({super.key, required this.s, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Opacity(
              opacity: s.active ? 1 : 0.35, child: SubAvatar(name: s.name, color: s.color, logoKey: s.catalogKey)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: s.active ? AppColors.text : AppColors.faint,
                      decoration: s.active ? null : TextDecoration.lineThrough)),
              const SizedBox(height: 5),
              Row(children: [
                if (s.active) Pill.forSub(s) else
                  const Pill('Nonaktif', fg: AppColors.faint, bg: AppColors.surface3),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    s.active ? '${tanggalPendek(s.nextDue)} · ${s.paymentMethod}' : s.paymentMethod,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(s.amountLabel,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, fontFeatures: kTabular)),
            const SizedBox(height: 3),
            Text(s.cycle.perLabel + (s.sharedWith > 1 ? ' · ÷${s.sharedWith}' : ''),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ]),
      ),
    );
  }
}

/// Grup baris dalam satu kartu dengan garis pemisah.
class TileGroup extends StatelessWidget {
  final List<Widget> children;
  const TileGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 74),
            children[i],
          ],
        ]),
      ),
    );
  }
}

/// Grafik donat sederhana untuk komposisi pengeluaran.
class DonutChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final double size;
  final double stroke;
  final Widget? center;
  const DonutChart({
    super.key,
    required this.values,
    required this.colors,
    this.size = 140,
    this.stroke = 16,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(values, colors, stroke),
        child: Center(child: center),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double stroke;
  _DonutPainter(this.values, this.colors, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.surface3;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    final gap = values.where((v) => v > 0).length > 1 ? 0.06 : 0.0;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      if (sweep <= 0) continue;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = colors[i % colors.length];
      canvas.drawArc(rect, start + gap / 2, math.max(0.001, sweep - gap), false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values != values || old.colors != colors || old.stroke != stroke;
}

InputDecoration inputDeco(String label, {String? hint, String? prefix, String? helper}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefix,
    helperText: helper,
    filled: true,
    fillColor: AppColors.surface,
    labelStyle: const TextStyle(color: AppColors.muted),
    floatingLabelStyle: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w600),
    helperStyle: const TextStyle(color: AppColors.faint),
    hintStyle: const TextStyle(color: AppColors.faint),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: b(AppColors.line),
    enabledBorder: b(AppColors.line),
    focusedBorder: b(AppColors.lime, 1.6),
    errorBorder: b(AppColors.coral),
    focusedErrorBorder: b(AppColors.coral, 1.6),
  );
}

/// Kolom pencarian berbentuk kapsul.
InputDecoration searchDeco(String hint) => InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      hintStyle: const TextStyle(color: AppColors.faint),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99), borderSide: const BorderSide(color: AppColors.line)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99), borderSide: const BorderSide(color: AppColors.line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: const BorderSide(color: AppColors.lime, width: 1.4)),
    );
