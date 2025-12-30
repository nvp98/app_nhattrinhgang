class GangCheckinRequest {
  final String soThung;
  final String congDoan;
  final String action;
  final DateTime time;
  final String note;
  final String maNv;

  GangCheckinRequest({
    required this.soThung,
    required this.congDoan,
    required this.action,
    required this.time,
    required this.maNv,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'sothung': soThung,
      'congdoan': congDoan,
      'action': action,
      'time': time.toIso8601String(),
      'note': note,
      'manv': maNv,
    };
  }
}
