import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/subscription.dart';
import '../services/repository.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

/// Kalender tagihan: tanggal mana saja ada tagihan dalam sebulan.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = dateOnly(now);
  }

  void _shift(int months) {
    setState(() {
      _month = DateTime(_month.year, _month.month + months);
      final today = dateOnly(DateTime.now());
      _selected = (today.year == _month.year && today.month == _month.month)
          ? today
          : DateTime(_month.year, _month.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repo.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final due = repo.dueInMonth(_month);
        final total = due.values
            .expand((l) => l)
            .fold<double>(0, (a, s) => a + s.amountIdr / (s.sharedWith < 1 ? 1 : s.sharedWith));
        final today = dateOnly(DateTime.now());
        final dayList = due[_selected] ?? const <Subscription>[];
        final sortedDays = due.keys.toList()..sort();

        return Scaffold(
          appBar: AppBar(title: const Text('Kalender tagihan')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              // ---------- Navigasi bulan ----------
              Row(children: [
                IconButton(
                  tooltip: 'Bulan sebelumnya',
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Column(children: [
                    Text(DateFormat('MMMM yyyy', 'id_ID').format(_month),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${due.values.fold<int>(0, (a, l) => a + l.length)} tagihan · ${rupiah(total)}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13, fontFeatures: kTabular)),
                  ]),
                ),
                IconButton(
                  tooltip: 'Bulan berikutnya',
                  onPressed: () => _shift(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ]),
              const SizedBox(height: 12),

              // ---------- Grid ----------
              AppCard(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                child: _MonthGrid(
                  month: _month,
                  selected: _selected,
                  today: today,
                  due: due,
                  onTap: (d) => setState(() => _selected = d),
                ),
              ),

              // ---------- Daftar hari terpilih ----------
              SectionTitle(DateFormat('EEEE, d MMMM', 'id_ID').format(_selected)),
              if (dayList.isEmpty)
                const AppCard(
                  child: Text('Tidak ada tagihan di tanggal ini.',
                      style: TextStyle(color: AppColors.muted)),
                )
              else
                TileGroup(children: [
                  for (final s in dayList)
                    _DayTile(
                      s: s,
                      due: _selected,
                      paid: repo.isPaid(s, _selected),
                    ),
                ]),

              // ---------- Semua tagihan bulan ini ----------
              if (sortedDays.isNotEmpty) ...[
                const SectionTitle('Semua tagihan bulan ini'),
                TileGroup(children: [
                  for (final d in sortedDays)
                    for (final s in due[d]!) _DayTile(s: s, due: d, paid: repo.isPaid(s, d), showDate: true),
                ]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final Map<DateTime, List<Subscription>> due;
  final ValueChanged<DateTime> onTap;
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.today,
    required this.due,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1; // Senin = kolom pertama
    final cells = <Widget>[
      for (final n in names)
        Center(
          child: Text(n,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
      for (var d = 1; d <= days; d++) _cell(DateTime(month.year, month.month, d)),
    ];
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 0.9,
      children: cells,
    );
  }

  Widget _cell(DateTime d) {
    final list = due[d] ?? const <Subscription>[];
    final isSel = d == selected;
    final isToday = d == today;
    final past = d.isBefore(today);
    return Semantics(
      button: true,
      label: '${d.day}, ${list.length} tagihan',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(d),
        child: Container(
          decoration: BoxDecoration(
            color: isSel ? AppColors.lime : (list.isNotEmpty ? AppColors.surface2 : null),
            borderRadius: BorderRadius.circular(12),
            border: isToday && !isSel ? Border.all(color: AppColors.lime, width: 1.4) : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${d.day}',
                style: TextStyle(
                  fontWeight: list.isNotEmpty || isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isSel
                      ? AppColors.onLime
                      : past
                          ? AppColors.faint
                          : AppColors.text,
                )),
            const SizedBox(height: 4),
            SizedBox(
              height: 6,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final s in list.take(3))
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.onLime : Color(s.color),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(40), width: 0.5),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final Subscription s;
  final DateTime due;
  final bool paid;
  final bool showDate;
  const _DayTile({required this.s, required this.due, required this.paid, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final past = due.isBefore(dateOnly(DateTime.now()));
    final status = paid
        ? const Pill('Dibayar', fg: AppColors.lime, bg: AppColors.limeDeep, icon: Icons.check_rounded)
        : past
            ? const Pill('Sudah lewat', fg: AppColors.muted, bg: AppColors.surface3)
            : (dateOnly(s.nextDue) == due ? Pill.forSub(s) : Pill.due(due));
    return InkWell(
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(sub: s))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          SubAvatar(logoKey: s.catalogKey, name: s.name, color: s.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 5),
              Row(children: [
                status,
                if (showDate) ...[
                  const SizedBox(width: 8),
                  Text(tanggalPendek(due),
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                ],
              ]),
            ]),
          ),
          const SizedBox(width: 10),
          Text(s.amountLabel,
              style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: kTabular)),
        ]),
      ),
    );
  }
}
