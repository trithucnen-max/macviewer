# Hướng Dẫn Sử Dụng Ultraview for Mac v2.0 (Utralview for Mac)
### Phát triển và bảo trợ bởi BASAN CORPORATION (BasanCorp)

---

## 1. Giới thiệu tổng quan

**Ultraview for Mac v2.0** (Utralview for Mac) là giải pháp phần mềm chuyên dụng cho người dùng macOS để kết nối, điều khiển hoặc chia sẻ màn hình với các máy tính đang chạy phần mềm UltraViewer trên Windows (hoặc trên máy Mac khác).

Phiên bản **v2.0** sở hữu động cơ xử lý hình ảnh và giao thức thế hệ mới, giao diện Dark/Light tối giản chuẩn 3 màu, đồng thời hỗ trợ trọn vẹn cả hai thế hệ chip: **Apple Silicon (M1, M2, M3, M4)** và **Intel (x86_64)**.

---

## 2. Hướng dẫn cài đặt

### Cách 1: Tải file cài đặt DMG (Khuyên dùng)
1. Tải phiên bản phù hợp từ trang GitHub Releases:
   - **`MacViewer-2.0.0-Universal.dmg`**: Bản hợp nhất, chạy hoàn hảo trên cả chip Apple Silicon (M1/M2/M3/M4) và chip Intel.
   - **`MacViewer-2.0.0-arm64.dmg`**: Dành riêng cho MacBook, Mac mini, iMac, Mac Studio dùng chip Apple Silicon.
   - **`MacViewer-2.0.0-x86_64.dmg`**: Dành riêng cho các dòng máy Mac dùng vi xử lý Intel.
2. Nhấp đúp chuột để mở file `.dmg`.
3. Kéo biểu tượng **MacViewer** và thả vào thư mục **Applications**.
4. Mở ứng dụng từ Launchpad, Spotlight (`⌘ + Space`) hoặc thư mục Applications.

> **Lưu ý bảo mật:** Bản phát hành chính thức đã được ký số bằng chứng chỉ `Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)`. Nếu macOS hiển thị thông báo lần đầu, chỉ cần bấm **Mở (Open)** để khởi động an toàn.

---

## 3. Cấp quyền hệ thống cho macOS (Bắt buộc khi cho người khác vào máy Mac)

Khi bạn muốn người khác xem hoặc điều khiển máy Mac của mình, macOS yêu cầu bảo vệ quyền riêng tư qua 2 quyền độc lập:

### Bước 1: Quyền Ghi màn hình (Screen Recording)
- **Mục đích:** Cho phép truyền hình ảnh màn hình máy Mac sang máy đối tác.
- **Cách bật:**
  1. Vào **Cài đặt hệ thống (System Settings)** → **Quyền riêng tư & Bảo mật (Privacy & Security)** → **Ghi màn hình (Screen Recording)**.
  2. Bật công tắc gạt cho **MacViewer**.
  3. Nếu macOS yêu cầu "Thoát và mở lại", hãy bấm xác nhận.

### Bước 2: Quyền Trợ năng (Accessibility)
- **Mục đích:** Cho phép đối tác thao tác chuột và bàn phím trên máy Mac khi bạn cho phép.
- **Cách bật:**
  1. Vào **Cài đặt hệ thống (System Settings)** → **Quyền riêng tư & Bảo mật (Privacy & Security)** → **Trợ năng (Accessibility)**.
  2. Bật công tắc gạt cho **MacViewer**.

---

## 4. Hướng dẫn sử dụng các tính năng chính

### 4.1 Điều khiển máy tính từ xa (Máy đối tác đang bật UltraViewer / Windows)
1. Yêu cầu phía đối tác cung cấp:
   - **ID đối tác (Partner ID)**: Dãy số gồm 8 - 9 chữ số.
   - **Mật khẩu (Password)**: Mật khẩu hiển thị trên UltraViewer của đối tác.
2. Tại giao diện chính của MacViewer:
   - Nhập **ID đối tác** vào ô "ID đối tác".
   - Nhập **Mật khẩu** vào ô "Mật khẩu".
   - *(Tùy chọn)* Đánh dấu tích vào "Ghi nhớ mật khẩu" nếu muốn lưu vào Keychain cho lần sau.
3. Bấm nút màu xanh **Kết nối đến máy khác**.
4. Cửa sổ màn hình từ xa sẽ xuất hiện. Bạn có thể:
   - Nhìn thấy màn hình làm việc của đối tác theo thời gian thực (hỗ trợ độ phân giải lên đến 4K).
   - Bật nút **Điều khiển** trên thanh công cụ để bắt đầu gõ phím và di chuột.
   - Sử dụng phím tắt thông minh: Phím <kbd>⌘ Command</kbd> trên Mac tự động ánh xạ sang phím <kbd>Win</kbd> trên Windows, <kbd>⌥ Option</kbd> ánh xạ sang <kbd>Alt</kbd>, và <kbd>⌃ Control</kbd> ánh xạ sang <kbd>Ctrl</kbd>.
   - Bật/tắt truyền âm thanh (Audio playback) từ máy đối tác.
   - Mở cửa sổ **Chat** để nhắn tin trực tiếp với người đang ngồi máy bên kia.

### 4.2 Cho phép người khác truy cập vào máy Mac của bạn
1. Tại khung **Cho phép điều khiển** ở bên trái cửa sổ chính:
   - Đọc dãy số **ID của bạn** (Your ID).
   - Đọc **Mật khẩu** (Password) ngẫu nhiên được cấp.
2. Gửi thông tin trên cho đối tác.
3. Khi đối tác thực hiện kết nối:
   - MacViewer sẽ hiển thị bảng thông báo yêu cầu xác nhận.
   - Bạn có thể lựa chọn: **Chỉ cho phép xem màn hình** hoặc **Cho phép toàn quyền điều khiển chuột/bàn phím**.
4. Bạn có toàn quyền bấm **Ngắt kết nối** bất kỳ lúc nào để chấm dứt phiên làm việc ngay lập tức.

---

## 5. Danh mục phím tắt & Thao tác nhanh

| Thao tác | Phím tắt Mac | Tương đương trên Windows |
| :--- | :--- | :--- |
| Mở menu Start Windows | <kbd>⌘ Command</kbd> | <kbd>Windows Key</kbd> |
| Chuyển đổi ứng dụng | <kbd>⌘ + Tab</kbd> / <kbd>⌥ + Tab</kbd> | <kbd>Alt + Tab</kbd> |
| Sao chép nội dung | <kbd>⌘ + C</kbd> hoặc <kbd>⌃ + C</kbd> | <kbd>Ctrl + C</kbd> |
| Dán nội dung | <kbd>⌘ + V</kbd> hoặc <kbd>⌃ + V</kbd> | <kbd>Ctrl + V</kbd> |
| Bật / Tắt toàn màn hình | <kbd>⌃ + ⌘ + F</kbd> | Fullscreen Toggle |
| Ngắt phiên khẩn cấp | Bấm nút **Ngắt kết nối** trên thanh công cụ | Session Terminate |

---

## 6. Xử lý sự cố thường gặp (Troubleshooting)

1. **Đối tác báo màn hình đen khi kết nối vào máy Mac:**
   - *Nguyên nhân:* Chưa cấp quyền Ghi màn hình (Screen Recording) cho MacViewer.
   - *Khắc phục:* Mở **System Settings** → **Privacy & Security** → **Screen Recording** → gạt bật MacViewer, sau đó khởi động lại ứng dụng.
2. **Đối tác chỉ xem được mà không di được chuột:**
   - *Nguyên nhân:* Chưa cấp quyền Trợ năng (Accessibility) hoặc bạn đang chọn chế độ chỉ xem.
   - *Khắc phục:* Mở **System Settings** → **Privacy & Security** → **Accessibility** → gạt bật MacViewer.
3. **Mạng báo "Không thể kết nối tới máy chủ trung gian":**
   - *Khắc phục:* Kiểm tra lại kết nối Internet hoặc tường lửa/proxy của mạng công ty. Đảm bảo cổng mạng tiêu chuẩn 211.x / 443 không bị chặn.

---

## 7. Thông tin liên hệ & Hỗ trợ kỹ thuật

- **Tổ chức chủ quản:** BASAN CORPORATION (BasanCorp)
- **Kho lưu trữ mã nguồn:** `https://github.com/Trithucnen/macviewer`
- **Email hỗ trợ kỹ thuật:** `contact@basancorp.com` / `support@trithucnen.vn`
- **Phiên bản tài liệu:** 2.0 (Cập nhật tháng 10/2026)
