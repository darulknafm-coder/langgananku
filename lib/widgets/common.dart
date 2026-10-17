import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../utils/format.dart';

class SubAvatar extends StatelessWidget {
  final String name;
  final int color;
  final double size;
  const SubAvatar({super.key, required this.name, required this.color, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words.isEmpty || words.first.isEmpty
        ? '?'
        : (words.length == 1
                ? words.first.substring(0, words.first.length >= 2 ? 2 : 1)
                : '${words[0][0]}${words[1][0]}')
            .toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color(color),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(initials,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.36)),
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
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(children: [
        Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class SubTile extends StatelessWidget {
  final Subscription s;
  final VoidCallback? onTap;
  const SubTile({super.key, required this.s, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final days = daysUntil(s.nextDue);
    final urgent = s.active && days <= 3;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Opacity(
          opacity: s.active ? 1 : 0.4, child: SubAvatar(name: s.name, color: s.color)),
      title: Text(s.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: s.active ? null : TextDecoration.lineThrough)),
      subtitle: Text(
        s.active
            ? '${tanggalPendek(s.nextDue)} · ${sisaHari(s.nextDue)} · ${s.paymentMethod}'
            : 'Nonaktif',
        style: TextStyle(color: urgent ? cs.error : null),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(rupiah(s.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(s.cycle.perLabel + (s.sharedWith > 1 ? ' · ÷${s.sharedWith}' : ''),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Kartu datar dengan sudut membulat.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const AppCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withAlpha(120)),
      ),
      child: child,
    );
  }
}

InputDecoration inputDeco(String label, {String? hint, String? prefix, String? helper}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      helperText: helper,
      border: const OutlineInputBorder(),
    );
