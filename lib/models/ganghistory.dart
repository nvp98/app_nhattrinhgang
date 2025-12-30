class GangCheckinHistoryItem {
  final int id;
  final String soThung;
  final String congDoan;
  final String action;
  final DateTime time;
  final String note;
  final String maNhanVien;
  final int thuTu;
  final DateTime? ngaySX;
  final int? ca;

  GangCheckinHistoryItem({
    required this.id,
    required this.soThung,
    required this.congDoan,
    required this.action,
    required this.time,
    required this.note,
    required this.maNhanVien,
    required this.thuTu,
    this.ngaySX,
    this.ca,
  });

  factory GangCheckinHistoryItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return GangCheckinHistoryItem(
      id: json['ID'],
      soThung: json['SoThung'],
      congDoan: json['CongDoan'],
      action: json['Action'],
      time: DateTime.parse(json['Time']),
      note: json['Note'] ?? '',
      maNhanVien: json['MaNhanVien'],
      thuTu: json['ThuTu'],
      ngaySX: json['NgaySX'] != null ? DateTime.parse(json['NgaySX']) : null,
      ca: json['Ca'],
    );
  }
}

class GangCheckinHistoryResponse {
  final String soThung;
  final List<GangCheckinHistoryItem> history;

  GangCheckinHistoryResponse({
    required this.soThung,
    required this.history,
  });

  factory GangCheckinHistoryResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return GangCheckinHistoryResponse(
      soThung: json['sothung'],
      history: (json['history'] as List)
          .map((e) => GangCheckinHistoryItem.fromJson(e))
          .toList(),
    );
  }
}
