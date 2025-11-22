import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum SteelStage { gang, choThep, raThep }

enum FlowAction { checkin, checkout }

class CheckinRecord {
  CheckinRecord(
      {required this.bin,
      required this.stage,
      required this.action,
      required this.time,
      this.note});
  final String bin;
  final SteelStage stage;
  final FlowAction action;
  final DateTime time;
  final String? note;
}

class StageMark {
  bool inDone = false;
  bool outDone = false;
  DateTime? inTime;
  DateTime? outTime;
}

class CheckinNotifier extends StateNotifier<List<CheckinRecord>> {
  CheckinNotifier() : super(const []);
  void add(CheckinRecord r) => state = [...state, r];
  void addMany(Iterable<CheckinRecord> list) => state = [...state, ...list];
  void updateTime(
      String bin, SteelStage stage, FlowAction action, DateTime time) {
    state = state
        .map((r) => r.bin == bin && r.stage == stage && r.action == action
            ? CheckinRecord(
                bin: r.bin,
                stage: r.stage,
                action: r.action,
                time: time,
                note: r.note)
            : r)
        .toList();
  }

  void remove(String bin, SteelStage stage, FlowAction action) {
    state = state
        .where((r) => !(r.bin == bin && r.stage == stage && r.action == action))
        .toList();
  }
}

final checkinProvider =
    StateNotifierProvider<CheckinNotifier, List<CheckinRecord>>(
        (ref) => CheckinNotifier());

class CheckinTab extends HookConsumerWidget {
  const CheckinTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final binCtrl = useTextEditingController();
    final bins = useState<List<String>>([]);
    final marks = useState<Map<String, Map<SteelStage, StageMark>>>({});

    void addBinsFromInput() {
      final text = binCtrl.text.trim();
      if (text.isEmpty) return;
      final parts = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      final next = [...bins.value];
      final nextMarks = Map<String, Map<SteelStage, StageMark>>.from(marks.value);
      for (final p in parts) {
        if (!next.contains(p)) next.add(p);
        nextMarks.putIfAbsent(p, () => {
              SteelStage.gang: StageMark(),
              SteelStage.choThep: StageMark(),
              SteelStage.raThep: StageMark(),
            });
      }
      binCtrl.clear();
      bins.value = next;
      marks.value = nextMarks;
    }

    void removeBin(String b) {
      final next = bins.value.where((e) => e != b).toList();
      final nextMarks = Map<String, Map<SteelStage, StageMark>>.from(marks.value);
      nextMarks.remove(b);
      bins.value = next;
      marks.value = nextMarks;
    }

    void clearBins() {
      bins.value = [];
    }

    void toggleMark(String bin, SteelStage stage, FlowAction action) {
      final m = marks.value[bin]?[stage];
      if (m == null) return;
      final t = DateTime.now();
      final nextMarks = Map<String, Map<SteelStage, StageMark>>.from(marks.value);
      if (action == FlowAction.checkin && !m.inDone) {
        m.inDone = true;
        m.inTime = t;
        ref.read(checkinProvider.notifier).add(CheckinRecord(bin: bin, stage: stage, action: FlowAction.checkin, time: t));
      } else if (action == FlowAction.checkout && !m.outDone) {
        m.outDone = true;
        m.outTime = t;
        ref.read(checkinProvider.notifier).add(CheckinRecord(bin: bin, stage: stage, action: FlowAction.checkout, time: t));
      }
      marks.value = nextMarks;
    }

    // 1) Helper: kiểm tra công đoạn trước đã hoàn thành chưa
    bool _isStageLocked(String bin, SteelStage stage) {
      final m = marks.value[bin];
      if (m == null) return true;
      switch (stage) {
        case SteelStage.gang:
          return false; // luôn được phép
        case SteelStage.choThep:
          final gang = m[SteelStage.gang];
          return gang == null || !gang.inDone || !gang.outDone;
        case SteelStage.raThep:
          final choThep = m[SteelStage.choThep];
          return choThep == null || !choThep.inDone || !choThep.outDone;
      }
    }

    // 2) Tin nhắn tooltip khi bị khóa
    String _stageLockMessage(SteelStage stage) {
      switch (stage) {
        case SteelStage.gang:
          return '';
        case SteelStage.choThep:
          return 'Hoàn thành công đoạn Gang trước';
        case SteelStage.raThep:
          return 'Hoàn thành công đoạn Chờ Thép trước';
      }
    }

    Color binBorderColor(String bin) {
      final m = marks.value[bin];
      if (m == null) return const Color(0xFFE2E8F0);
      bool any = false;
      bool all = true;
      for (final s in SteelStage.values) {
        final st = m[s];
        if (st == null) continue;
        final done = (st.inDone && st.outDone);
        if (st.inDone || st.outDone) any = true;
        if (!done) all = false;
      }
      if (all) return const Color(0xFF22C55E);
      if (any) return const Color(0xFF00529C);
      return const Color(0xFFE2E8F0);
    }

    

    

    Future<void> showTimeEditDialog(String bin, SteelStage stage, FlowAction action, DateTime current) async {
      await showDialog(
        context: context,
        builder: (context) {
          final primary = theme.colorScheme.primary;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.zero,
            title: Container(
              decoration: BoxDecoration(color: primary, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.schedule, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Chỉnh giờ / Reset', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  Text('${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')} ${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                ])),
              ]),
            ),
            content: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Card(
                  color: theme.colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: primary, child: const Icon(Icons.edit, color: Colors.white)),
                    title: const Text('Chỉnh lại giờ'),
                    subtitle: Text('${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')} ${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final nav = Navigator.of(context);
                      final now = DateTime.now();
                      final date = await showDatePicker(context: context, initialDate: current, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 1));
                      if (!context.mounted) return;
                      if (date == null) return;
                      final tod = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(current));
                      if (!context.mounted) return;
                      if (tod == null) return;
                      final nt = DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
                      final m = marks.value[bin]?[stage];
                      if (m != null) {
                        if (action == FlowAction.checkin) {
                          m.inTime = nt;
                        } else {
                          m.outTime = nt;
                        }
                      }
                      ref.read(checkinProvider.notifier).updateTime(bin, stage, action, nt);
                      marks.value = Map<String, Map<SteelStage, StageMark>>.from(marks.value);
                      nav.pop();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: const Color(0xFFFFF3E0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFB45309), child: Icon(Icons.restart_alt, color: Colors.white)),
                    title: const Text('Reset check'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final nav = Navigator.of(context);
                      final m = marks.value[bin]?[stage];
                      if (m != null) {
                        if (action == FlowAction.checkin) {
                          m.inDone = false;
                          m.inTime = null;
                        } else {
                          m.outDone = false;
                          m.outTime = null;
                        }
                      }
                      ref.read(checkinProvider.notifier).remove(bin, stage, action);
                      marks.value = Map<String, Map<SteelStage, StageMark>>.from(marks.value);
                      nav.pop();
                    },
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Đóng', style: theme.textTheme.labelLarge?.copyWith(color: primary))),
            ],
          );
        },
      );
    }

    Widget timeButton(String bin, SteelStage stage, FlowAction action, DateTime time) {
      final isIn = action == FlowAction.checkin;
      final tint = isIn ? theme.colorScheme.primary : const Color(0xFFB45309);
      return InkWell(
        onTap: () => showTimeEditDialog(bin, stage, action, time),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tint.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 16, color: tint),
              const SizedBox(width: 6),
              Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tint),
              ),
            ],
          ),
        ),
      );
    }

    Widget stageCell(String bin, SteelStage stage) {
      final m = marks.value[bin]?[stage];
      if (m == null) return const SizedBox();

      final locked = _isStageLocked(bin, stage);
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // In
          if (!m.inDone)
            FilledButton.icon(
              onPressed: locked ? null : () => toggleMark(bin, stage, FlowAction.checkin),
              icon: const Icon(Icons.login),
              label: const Text('In'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else if (m.inTime != null)
            IgnorePointer(
              ignoring: locked,
              child: Opacity(
                opacity: locked ? 0.4 : 1,
                child: Padding(padding: const EdgeInsets.only(top: 6), child: timeButton(bin, stage, FlowAction.checkin, m.inTime!)),
              ),
            ),
          const SizedBox(height: 8),
          // Out: ẩn nút nếu đã out, chỉ hiện time-button
          if (!m.outDone)
            FilledButton.icon(
              onPressed: (locked || !m.inDone) ? null : () => toggleMark(bin, stage, FlowAction.checkout),
              icon: const Icon(Icons.logout),
              label: const Text('Out'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else if (m.outTime != null)
            IgnorePointer(
              ignoring: locked,
              child: Opacity(
                opacity: locked ? 0.4 : 1,
                child: Padding(padding: const EdgeInsets.only(top: 6), child: timeButton(bin, stage, FlowAction.checkout, m.outTime!)),
              ),
            ),
        ],
      );

      // Tooltip báo khóa
      if (locked) {
        return Tooltip(
          message: _stageLockMessage(stage),
          child: content,
        );
      }
      return content;
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Check-in thùng gang', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    TextField(
                      controller: binCtrl,
                      decoration: InputDecoration(
                        labelText: 'Thêm thùng',
                        hintText: 'VD: T001, T002, T003',
                        prefixIcon: Icon(Icons.oil_barrel_outlined, color: theme.colorScheme.primary),
                        suffixIcon: IconButton(onPressed: addBinsFromInput, icon: Icon(Icons.add, color: theme.colorScheme.primary)),
                      ),
                      onSubmitted: (_) => addBinsFromInput(),
                    ),
                    if (bins.value.isNotEmpty)
                      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: clearBins, child: const Text('Xóa tất cả thùng'))),
                  ]),
                ),
              ),
            ),
          ),
        ),
        if (bins.value.isNotEmpty)
          SliverPersistentHeader(
            pinned: true,
            delegate: _BinsHeaderDelegate(
              height: 44,
              buildHeader: () => Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: const [
                    Expanded(flex: 1, child: Text('Số thùng', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Expanded(child: Text('Vận chuyển Gang', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Expanded(child: Text('Gian chờ Thép', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Expanded(child: Text('Ra Luyện Thép', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  ]),
                ),
              ),
            ),
          ),
        if (bins.value.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final b = bins.value[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: binBorderColor(b)),
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
                            deleteIconColor: theme.colorScheme.primary,
                            shape: const StadiumBorder(side: BorderSide(color: Color(0xFFE2E8F0))),
                            onDeleted: () => removeBin(b),
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
                childCount: bins.value.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _BinsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _BinsHeaderDelegate({required this.height, required this.buildHeader});
  final double height;
  final Widget Function() buildHeader;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: overlapsContent
              ? const [
                BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 6,
                    offset: Offset(0, 2))
              ]
              : null,
          border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: buildHeader(),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
