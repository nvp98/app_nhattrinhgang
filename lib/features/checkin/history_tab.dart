import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'checkin_tab.dart';

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});
  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  DateTime _selectedDate = DateTime.now();

  bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = ref.watch(checkinProvider).where((r) => _sameDate(r.time, _selectedDate)).toList();

    final marks = <String, Map<SteelStage, StageMark>>{};
    for (final r in items) {
      marks.putIfAbsent(r.bin, () => {
            SteelStage.gang: StageMark(),
            SteelStage.choThep: StageMark(),
            SteelStage.raThep: StageMark(),
          });
      final m = marks[r.bin]![r.stage]!;
      if (r.action == FlowAction.checkin) {
        m.inDone = true;
        m.inTime = r.time;
      } else {
        m.outDone = true;
        m.outTime = r.time;
      }
    }
    final bins = marks.keys.toList()..sort();

    Widget timeChip(DateTime time, {required bool isIn}) {
      final tint = isIn ? theme.colorScheme.primary : const Color(0xFFB45309);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tint.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.schedule, size: 16, color: tint),
          const SizedBox(width: 6),
          Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tint)),
        ]),
      );
    }

    Widget stageCell(String bin, SteelStage stage) {
      final m = marks[bin]?[stage];
      if (m == null) return const SizedBox();
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (m.inTime != null) Padding(padding: const EdgeInsets.only(top: 6), child: timeChip(m.inTime!, isIn: true)),
        const SizedBox(height: 8),
        if (m.outTime != null) Padding(padding: const EdgeInsets.only(top: 6), child: timeChip(m.outTime!, isIn: false)),
      ]);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}')),
                  OutlinedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 1));
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: const Text('Chọn ngày'),
                  ),
                ]),
              ),
            ),
          ),
        ),
        if (bins.isNotEmpty)
          SliverPersistentHeader(
            pinned: true,
            delegate: HistoryHeaderDelegate(
              height: 44,
              buildHeader: () => Container(
                color: Colors.white,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(flex: 1, child: Text('Số thùng', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Expanded(child: Text('Vận chuyển Gang', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Expanded(child: Text('Gian chờ Thép', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Expanded(child: Text('Ra Luyện Thép', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  ]),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final b = bins[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 4))],
                    color: Colors.white,
                  ),
                  child: Row(children: [
                    Expanded(
                      flex: 1,
                      child: Row(children: [
                        Chip(
                          label: Text(b, style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
                          backgroundColor: Colors.white,
                          shape: const StadiumBorder(side: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: stageCell(b, SteelStage.gang)),
                    const SizedBox(width: 8),
                    Expanded(child: stageCell(b, SteelStage.choThep)),
                    const SizedBox(width: 8),
                    Expanded(child: stageCell(b, SteelStage.raThep)),
                  ]),
                );
              },
              childCount: bins.length,
            ),
          ),
        ),
      ],
    );
  }
}

class HistoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  HistoryHeaderDelegate({required this.height, required this.buildHeader});
  final double height;
  final Widget Function() buildHeader;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: overlapsContent
              ? const [
                  BoxShadow(color: Color(0x11000000), blurRadius: 6, offset: Offset(0, 2))
                ]
              : null,
          border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: buildHeader(),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
