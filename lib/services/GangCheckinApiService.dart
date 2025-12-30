import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nhattrinhgang_mobile/models/ganghistory.dart';
import 'package:nhattrinhgang_mobile/models/gangoperation.dart';

class GangCheckinApiService {
  static const String _baseUrl = 'https://chart.hoaphatdungquat.vn/api';

  static Future<void> postCheckin(GangCheckinRequest req) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/gang/checkin'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(req.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Check-in failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// GET: lấy toàn bộ lịch sử công đoạn của thùng
  static Future<GangCheckinHistoryResponse> getStatus(
    String soThung,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/gang/$soThung/status'),
    );

    if (res.statusCode != 200) {
      throw Exception('Không lấy được trạng thái thùng');
    }

    return GangCheckinHistoryResponse.fromJson(
      jsonDecode(res.body),
    );
  }
}
