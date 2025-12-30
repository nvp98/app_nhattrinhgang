# nhattrinhgang_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Cấu trúc JSON để API nhận dữ liệu (POST)

- Content-Type: `application/json`
- Authorization: `Bearer <token>` (bắt buộc, nếu API yêu cầu xác thực)
- Múi giờ thời gian: ISO 8601 (`YYYY-MM-DDTHH:mm:ssZ`) hoặc `YYYY-MM-DDTHH:mm:ss+07:00`

### Bản ghi check-in/check-out (đơn lẻ)
- Trường:
  - `bin`: chuỗi mã thùng
  - `stage`: công đoạn, một trong: `gang`, `choThep`, `raThep`
  - `action`: hành động, một trong: `checkin`, `checkout`
  - `time`: thời gian hành động (ISO 8601)
  - `note`: ghi chú (tùy chọn)
- Ví dụ:
  ```json
  {
    "bin": "T001",
    "stage": "gang",
    "action": "checkin",
    "time": "2025-11-24T09:30:00+07:00",
    "note": "Vào công đoạn vận chuyển gang"
  }
  ```

### Gửi theo lô (nhiều bản ghi)
- Trường:
  - `records`: mảng các bản ghi theo cấu trúc ở trên
- Ví dụ:
  ```json
  {
    "records": [
      {
        "bin": "T001",
        "stage": "gang",
        "action": "checkin",
        "time": "2025-11-24T09:30:00+07:00"
      },
      {
        "bin": "T001",
        "stage": "gang",
        "action": "checkout",
        "time": "2025-11-24T10:05:00+07:00"
      },
      {
        "bin": "T001",
        "stage": "choThep",
        "action": "checkin",
        "time": "2025-11-24T10:20:00+07:00"
      }
    ]
  }
  ```

### Phản hồi thành công (gợi ý)
- Đơn lẻ:
  ```json
  {
    "id": "rec_01HFQ1...",
    "status": "ok",
    "createdAt": "2025-11-24T09:30:02Z"
  }
  ```
- Theo lô:
  ```json
  {
    "status": "ok",
    "accepted": 3,
    "failed": 0
  }
  ```

### Lỗi thường gặp (gợi ý)
- Thiếu trường bắt buộc:
  ```json
  {
    "error": {
      "code": "VALIDATION_ERROR",
      "message": "Missing field: time"
    }
  }
  ```
- Không đúng thứ tự công đoạn:
  ```json
  {
    "error": {
      "code": "STAGE_ORDER_INVALID",
      "message": "Stage choThep requires gang to be completed"
    }
  }
  ```

### Ghi chú triển khai
- Ứng dụng tự động đính `Authorization` nếu đã lưu `access_token`.
- Thời gian gửi theo chuẩn ISO 8601; phía server nên chuẩn hóa về UTC hoặc múi giờ kinh doanh cố định.
