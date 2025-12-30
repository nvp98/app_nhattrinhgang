import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nhattrinhgang_mobile/core/stores/localstore.dart';
import 'package:nhattrinhgang_mobile/models/gangoperation.dart';
import 'package:nhattrinhgang_mobile/services/GangCheckinApiService.dart';

enum SteelStage { gang, choThep, raThep }

extension SteelStageApi on SteelStage {
  String get apiValue {
    switch (this) {
      case SteelStage.gang:
        return 'START_LG'; // Luyện gang
      case SteelStage.choThep:
        return 'IN_LT'; // Gian chờ thép
      case SteelStage.raThep:
        return 'OUT_LT'; // Ra luyện thép
    }
  }
}

SteelStage? _mapCongDoan(String code) {
  switch (code) {
    case 'START_LG':
      return SteelStage.gang;
    case 'IN_LT':
      return SteelStage.choThep;
    case 'OUT_LT':
      return SteelStage.raThep;
    default:
      return null;
  }
}

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

    Future<void> loadBinFromApi(String soThung) async {
      final res = await GangCheckinApiService.getStatus(soThung);
      final history = res.history;

      // Khởi tạo đủ công đoạn
      final Map<SteelStage, StageMark> stageMap = {
        SteelStage.gang: StageMark(),
        SteelStage.choThep: StageMark(),
        SteelStage.raThep: StageMark(),
      };

      const List<SteelStage> stageOrder = [
        SteelStage.gang,
        SteelStage.choThep,
        SteelStage.raThep,
      ];

      // Fill từ DB
      final hasOutLt = history.any(
        (h) => _mapCongDoan(h.congDoan) == SteelStage.raThep,
      );
      if (!hasOutLt) {
        // không có công đoạn hợp lệ nào
      }

      for (final h in history) {
        final stage = _mapCongDoan(h.congDoan);
        if (stage == null) continue;

        stageMap[stage]!
          ..inDone = true
          ..inTime = h.time;
      }

      // marks.value = {
      //   ...marks.value,
      //   soThung: stageMap,
      // };

      // 3️⃣ Xác định có được tạo "dòng mới" hay không
      // → tìm công đoạn CHƯA inDone đầu tiên
      SteelStage? nextStage;
      for (final s in stageOrder) {
        if (!stageMap[s]!.inDone) {
          nextStage = s;
          break;
        }
      }

      // 4️⃣ Trường hợp đặc biệt:
      // - history rỗng
      // - hoặc toàn bộ congDoan không map được
      final bool hasValidStage = stageMap.values.any((m) => m.inDone);

      final bool hasAllStageDone = stageMap.values.every((m) => m.inDone);

      if (!hasValidStage) {
        // coi như thùng mới → mở Gang
        stageMap[SteelStage.gang] = StageMark();
      } else if (hasAllStageDone) {
        // 👉 ĐÃ ĐỦ TẤT CẢ CÔNG ĐOẠN
        // mở dòng mới → reset toàn bộ
        stageMap..updateAll((_, __) => StageMark());
      }

      // 5️⃣ Set state
      marks.value = {
        ...marks.value,
        soThung: stageMap,
      };

      // (optional) debug log
      debugPrint(
        nextStage == null
            ? 'Thùng $soThung đã hoàn thành tất cả công đoạn'
            : 'Thùng $soThung mở công đoạn: $nextStage',
      );
    }

    void addBinsFromInput() async {
      final text = binCtrl.text.trim();
      if (text.isEmpty) return;
      final parts =
          text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      final next = [...bins.value];
      final nextMarks =
          Map<String, Map<SteelStage, StageMark>>.from(marks.value);
      for (final p in parts) {
        // if (!next.contains(p)) next.add(p);
        if (next.contains(p)) continue;
        next.add(p);
        // nextMarks.putIfAbsent(
        //     p,
        //     () => {
        //           SteelStage.gang: StageMark(),
        //           SteelStage.choThep: StageMark(),
        //           SteelStage.raThep: StageMark(),
        //         });
        await loadBinFromApi(p);
      }
      binCtrl.clear();
      bins.value = next;
      // marks.value = nextMarks;
    }

    void removeBin(String b) {
      final next = bins.value.where((e) => e != b).toList();
      final nextMarks =
          Map<String, Map<SteelStage, StageMark>>.from(marks.value);
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
      final nextMarks =
          Map<String, Map<SteelStage, StageMark>>.from(marks.value);
      if (action == FlowAction.checkin && !m.inDone) {
        m.inDone = true;
        m.inTime = t;
        ref.read(checkinProvider.notifier).add(CheckinRecord(
            bin: bin, stage: stage, action: FlowAction.checkin, time: t));
      } else if (action == FlowAction.checkout && !m.outDone) {
        m.outDone = true;
        m.outTime = t;
        ref.read(checkinProvider.notifier).add(CheckinRecord(
            bin: bin, stage: stage, action: FlowAction.checkout, time: t));
      }
      marks.value = nextMarks;
    }

    Future<void> checkinStage(
      String bin,
      SteelStage stage,
      String maNv,
    ) async {
      final binMarks = marks.value[bin]!;
      final old = binMarks[stage]!;
      if (old.inDone) return;

      final now = DateTime.now();
      final manv = await LocalStore.getUsername();

      // POST CHECK-IN LÊN DB Ở ĐÂY
      final req = GangCheckinRequest(
        soThung: bin,
        congDoan: stage.apiValue, // lấy công đoạn
        action: 'in',
        time: now,
        maNv: manv ?? 'MANV001',
      );

      await GangCheckinApiService.postCheckin(req);
      toggleMark(bin, stage, FlowAction.checkin);

      // 🟢 API OK → cập nhật state local
      marks.value = {
        ...marks.value,
        bin: {
          ...binMarks,
          // stage: old.copyWith(
          //   inDone: true,
          //   inTime: now,
          // ),
        },
      };
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
          return gang == null || !gang.inDone;
        case SteelStage.raThep:
          final choThep = m[SteelStage.choThep];
          return choThep == null || !choThep.inDone;
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

    Future<void> showTimeEditDialog(String bin, SteelStage stage,
        FlowAction action, DateTime current) async {
      await showDialog(
        context: context,
        builder: (context) {
          final primary = theme.colorScheme.primary;
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.zero,
            title: Container(
              decoration: BoxDecoration(
                  color: primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16))),
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.schedule, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Chỉnh giờ / Reset',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      Text(
                          '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')} ${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white70)),
                    ])),
              ]),
            ),
            content: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Card(
                  color: theme.colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: primary,
                        child: const Icon(Icons.edit, color: Colors.white)),
                    title: const Text('Chỉnh lại giờ'),
                    subtitle: Text(
                        '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')} ${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final nav = Navigator.of(context);
                      final now = DateTime.now();
                      final date = await showDatePicker(
                          context: context,
                          initialDate: current,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 1));
                      if (!context.mounted) return;
                      if (date == null) return;
                      final tod = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(current));
                      if (!context.mounted) return;
                      if (tod == null) return;
                      final nt = DateTime(date.year, date.month, date.day,
                          tod.hour, tod.minute);
                      final m = marks.value[bin]?[stage];
                      if (m != null) {
                        if (action == FlowAction.checkin) {
                          m.inTime = nt;
                        } else {
                          m.outTime = nt;
                        }
                      }
                      ref
                          .read(checkinProvider.notifier)
                          .updateTime(bin, stage, action, nt);
                      marks.value =
                          Map<String, Map<SteelStage, StageMark>>.from(
                              marks.value);
                      nav.pop();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: const Color(0xFFFFF3E0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: Color(0xFFB45309),
                        child: Icon(Icons.restart_alt, color: Colors.white)),
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
                      ref
                          .read(checkinProvider.notifier)
                          .remove(bin, stage, action);
                      marks.value =
                          Map<String, Map<SteelStage, StageMark>>.from(
                              marks.value);
                      nav.pop();
                    },
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Đóng',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: primary))),
            ],
          );
        },
      );
    }

    Widget timeButton(
        String bin, SteelStage stage, FlowAction action, DateTime time) {
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
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: tint),
              ),
            ],
          ),
        ),
      );
    }

    Widget _stageContent(
      String bin,
      SteelStage stage,
      StageMark m,
      bool locked,
    ) {
      if (!m.inDone) {
        return FilledButton(
          onPressed: locked ? null : () => checkinStage(bin, stage, 'MANV001'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('CHECK-IN'),
        );
      }

      return timeButton(bin, stage, FlowAction.checkin, m.inTime!);
    }

    String _stageTitle(SteelStage stage) {
      switch (stage) {
        case SteelStage.gang:
          return 'Vận chuyển Gang';
        case SteelStage.choThep:
          return 'Gian chờ Thép';
        case SteelStage.raThep:
          return 'Ra Luyện Thép';
      }
    }

    Widget stageCell(String bin, SteelStage stage) {
      final m = marks.value[bin]?[stage];
      if (m == null) return const SizedBox();

      final locked = _isStageLocked(bin, stage);
      // final content = Column(
      //   crossAxisAlignment: CrossAxisAlignment.stretch,
      //   children: [
      //     // In
      //     if (!m.inDone)
      //       FilledButton.icon(
      //         onPressed: locked
      //             ? null
      //             : () => checkinStage(bin, stage,
      //                 'MANV001'), // TODO: Thay 'MANV001' bằng mã nhân viên thực tế
      //         icon: const Icon(Icons.login),
      //         label: const Text('In'),
      //         style: FilledButton.styleFrom(
      //           minimumSize: const Size.fromHeight(44),
      //           shape: RoundedRectangleBorder(
      //               borderRadius: BorderRadius.circular(12)),
      //         ),
      //       )
      //     else if (m.inTime != null)
      //       IgnorePointer(
      //         ignoring: locked,
      //         child: Opacity(
      //           opacity: locked ? 0.4 : 1,
      //           child: Padding(
      //               padding: const EdgeInsets.only(top: 6),
      //               child:
      //                   timeButton(bin, stage, FlowAction.checkin, m.inTime!)),
      //         ),
      //       ),
      //     const SizedBox(height: 8),
      //     // Out: ẩn nút nếu đã out, chỉ hiện time-button
      //     // if (!m.outDone)
      //     //   FilledButton.icon(
      //     //     onPressed: (locked || !m.inDone)
      //     //         ? null
      //     //         : () => toggleMark(bin, stage, FlowAction.checkout),
      //     //     icon: const Icon(Icons.logout),
      //     //     label: const Text('Out'),
      //     //     style: FilledButton.styleFrom(
      //     //       minimumSize: const Size.fromHeight(44),
      //     //       shape: RoundedRectangleBorder(
      //     //           borderRadius: BorderRadius.circular(12)),
      //     //     ),
      //     //   )
      //     // else if (m.outTime != null)
      //     //   IgnorePointer(
      //     //     ignoring: locked,
      //     //     child: Opacity(
      //     //       opacity: locked ? 0.4 : 1,
      //     //       child: Padding(
      //     //           padding: const EdgeInsets.only(top: 6),
      //     //           child: timeButton(
      //     //               bin, stage, FlowAction.checkout, m.outTime!)),
      //     //     ),
      //     //   ),
      //   ],
      // );

      // // Tooltip báo khóa
      // if (locked) {
      //   return Tooltip(
      //     message: _stageLockMessage(stage),
      //     child: content,
      //   );
      // }
      // return content;
      return Card(
        elevation: locked ? 0 : 2,
        color: locked ? Colors.grey.shade100 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(
                _stageTitle(stage),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: locked ? Colors.grey : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              _stageContent(bin, stage, m, locked),
            ],
          ),
        ),
      );
    }

    Widget _binHeader(
      BuildContext context,
      String bin,
      Map<SteelStage, StageMark> marks,
    ) {
      final theme = Theme.of(context);

      String status;
      Color color;

      if (marks.values.every((m) => m.inDone)) {
        status = 'Hoàn thành';
        color = Colors.green;
      } else if (marks.values.any((m) => m.inDone)) {
        status = 'Đang xử lý';
        color = theme.colorScheme.primary;
      } else {
        status = 'Thùng mới';
        color = Colors.grey;
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Chip(
            avatar: const Icon(Icons.inventory, size: 16),
            label: Text('Thùng $bin'),
            onDeleted: () => removeBin(bin),
          ),
          Chip(
            label: Text(status),
            backgroundColor: color.withOpacity(0.15),
            labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      );
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
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Text('Check-in thùng gang',
                        //     style: theme.textTheme.titleLarge?.copyWith(
                        //         color: theme.colorScheme.onPrimaryContainer)),
                        // const SizedBox(height: 12),
                        // const SizedBox(height: 12),
                        // TextField(
                        //   controller: binCtrl,
                        //   decoration: InputDecoration(
                        //     labelText: 'Thêm thùng',
                        //     hintText: 'VD: 01, 02, 03',
                        //     prefixIcon: Icon(Icons.oil_barrel_outlined,
                        //         color: theme.colorScheme.primary),
                        //     suffixIcon: IconButton(
                        //         onPressed: addBinsFromInput,
                        //         icon: Icon(Icons.add,
                        //             color: theme.colorScheme.primary)),
                        //   ),
                        //   onSubmitted: (_) => addBinsFromInput(),
                        // ),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: binCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'Nhập số thùng (VD: 11,12)',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: addBinsFromInput,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Thêm'),
                                )
                              ],
                            ),
                          ),
                        ),
                        if (bins.value.isNotEmpty)
                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  onPressed: clearBins,
                                  child: const Text('Xóa tất cả thùng'))),
                      ]),
                ),
              ),
            ),
          ),
        ),
        if (bins.value.isNotEmpty)
          // SliverPersistentHeader(
          //   pinned: true,
          //   delegate: _BinsHeaderDelegate(
          //     height: 44,
          //     buildHeader: () => Container(
          //       color: Colors.white,
          //       child: Padding(
          //         padding: const EdgeInsets.symmetric(horizontal: 16),
          //         child: Row(children: const [
          //           Expanded(
          //               flex: 1,
          //               child: Text('Số thùng',
          //                   textAlign: TextAlign.center,
          //                   style: TextStyle(
          //                       fontWeight: FontWeight.bold, fontSize: 14))),
          //           Expanded(
          //               child: Text('Vận chuyển Gang',
          //                   textAlign: TextAlign.center,
          //                   style: TextStyle(
          //                       fontWeight: FontWeight.bold, fontSize: 14))),
          //           Expanded(
          //               child: Text('Gian chờ Thép',
          //                   textAlign: TextAlign.center,
          //                   style: TextStyle(
          //                       fontWeight: FontWeight.bold, fontSize: 14))),
          //           Expanded(
          //               child: Text('Ra Luyện Thép',
          //                   textAlign: TextAlign.center,
          //                   style: TextStyle(
          //                       fontWeight: FontWeight.bold, fontSize: 14))),
          //         ]),
          //       ),
          //     ),
          //   ),
          // ),
          if (bins.value.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final b = bins.value[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: binBorderColor(b), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _binHeader(context, b, marks.value[b]!),
                            const Divider(height: 20),
                            Row(
                              children: [
                                Expanded(child: stageCell(b, SteelStage.gang)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: stageCell(b, SteelStage.choThep)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: stageCell(b, SteelStage.raThep)),
                              ],
                            ),
                          ],
                        ),
                      ),
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
