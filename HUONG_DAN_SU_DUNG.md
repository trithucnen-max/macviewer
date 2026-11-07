# Hướng Dẫn Sử Dụng Utralview for Mac v2.3.3
### Phát triển và bảo trợ bởi BASAN CORPORATION (BasanCorp)

---

## 1. Giới thiệu tổng quan

**Utralview for Mac v2.3.3** là giải pháp phần mềm chuyên dụng cho người dùng macOS để kết nối, điều khiển hoặc chia sẻ màn hình với các máy tính đang chạy phần mềm UltraViewer trên Windows (hoặc trên máy Mac khác).

Phiên bản **v2.3.3** được đóng gói thành **1 bản cài đặt Universal duy nhất**, hỗ trợ kết nối trực tiếp bằng mật khẩu đối tác, tính năng **Smart Clipboard Guard** bảo vệ dữ liệu nhạy cảm, tăng tốc kết nối mạng nội bộ **LAN Direct**, và chạy nguyên bản trên mọi dòng máy Mac dùng cả chip **Apple Silicon (M1, M2, M3, M4)** lẫn **Intel (x86_64)**.

---

## 2. Hướng dẫn cài đặt

### Cách 1: Cài đặt từ file DMG Universal duy nhất
1. Tải tệp **`Utralview-for-Mac-v2.3.3-Universal.dmg`** từ trang GitHub Releases (dùng chung cho mọi máy Mac Apple Silicon M1–M4 và Intel).
2. Nhấp đúp chuột để mở file `.dmg`.
3. Kéo biểu tượng **`Utralview for Mac.app`** và thả vào thư mục **Applications**.
4. Mở ứng dụng từ Launchpad, Spotlight (`⌘ + Space`) hoặc thư mục Applications.

### Cách 2: Vượt qua cảnh báo mở lần đầu (Apple Gatekeeper)
Bản phát hành chính thức đã được ký số bằng chứng chỉ `Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)` với Apple Hardened Runtime. Nếu macOS hiển thị thông báo kiểm tra lần đầu khi tải qua trình duyệt:
- **Cách nhanh nhất:** Nhấp đúp vào tệp `Mo-Utralview-Lan-Dau.command` có sẵn bên trong file DMG để tự động cấp phép và mở app.
- **Hoặc:** Vào **Cài đặt hệ thống (System Settings)** → **Quyền riêng tư & Bảo mật (Privacy & Security)** → cuộn xuống mục Bảo mật và bấm **"Vẫn mở" (Open Anyway)**.
- **Hoặc:** Giữ phím `Control` (hoặc nhấp chuột phải) vào `Utralview for Mac` trong Applications → Chọn **Mở (Open)** → Bấm **Mở**.
- **Hoặc lệnh Terminal:**
  ```bash
  xattr -cr "/Applications/Utralview for Mac.app"
  ```

---

## 3. Cấp quyền hệ thống cho macOS (Bắt buộc khi cho người khác vào máy Mac)

Khi bạn muốn người khác xem hoặc điều khiển máy Mac của mình, macOS yêu cầu bảo vệ quyền riêng tư qua 2 quyền độc lập:

### Bước 1: Quyền Ghi màn hình (Screen Recording)
- **Mục đích:** Cho phép truyền hình ảnh màn hình máy Mac sang máy đối tác.
- **Cách bật:**
  1. Vào **Cài đặt hệ thống (System Settings)** → **Quyền riêng tư & Bảo mật (Privacy & Security)** → **Ghi màn hình (Screen Recording)**.
  2. Bật công tắc gạt cho **Utralview for Mac**.
  3. Nếu macOS yêu cầu "Thoát và mở lại", hãy bấm xác nhận.

### Bước 2: Quyền Trợ năng (Accessibility)
- **Mục đích:** Cho phép đối tác thao tác chuột và bàn phím trên máy Mac khi bạn cho phép.
- **Cách bật:**
  1. Vào **Cài đặt hệ thống (System Settings)** → **Quyền riêng tư & Bảo mật (Privacy & Security)** → **Trợ năng (Accessibility)**.
  2. Bật công tắc gạt cho **Utralview for Mac**.

---

## 4. Hướng dẫn sử dụng các tính năng chính

### 4.1 Điều khiển máy tính từ xa (Máy đối tác đang bật UltraViewer / Windows)
1. Yêu cầu phía đối tác cung cấp:
   - **ID đối tác (Partner ID)**: Dãy số gồm 8 - 9 chữ số.
   - **Mật khẩu (Password)**: Mật khẩu hiển thị trên UltraViewer của đối tác.
2. Tại giao diện chính của Utralview for Mac:
   - Nhập **ID đối tác** vào ô "ID đối tác".
   - Nhập **Mật khẩu** vào ô "Mật khẩu".
   - *(Tuỳ chọn)* Đánh dấu tích vào "Ghi nhớ mật khẩu" nếu muốn lưu an toàn vào Keychain cho lần sau.
3. Bấm nút màu xanh **Kết nối đến máy khác**.
4. Cửa sổ màn hình từ xa sẽ xuất hiện. Bạn có thể:
   - Nhìn thấy màn hình làm việc của đối tác theo thời gian thực (hỗ trợ độ phân giải lên đến 4K).
   - Bật nút **Điều khiển** trên thanh công cụ để bắt đầu gõ phím và di chuột.
   - Sử dụng phím tắt thông minh: Phím <kbd>⌘ Command</kbd> trên Mac tự động ánh xạ sang phím <kbd>Win</kbd> trên Windows, <kbd>⌥ Option</kbd> ánh xạ sang <kbd>Alt</kbd>, và <kbd>⌃ Control</kbd> ánh xạ sang <kbd>Ctrl</kbd>.
   - Bật/tắt truyền âm thanh (Audio playback) từ máy đối tác.
   - Mở cửa sổ **Chat** để nhắn tin trực tiếp với người đang ngồi máy bên kia.

### 4.2 Cho phép người khác truy cập vào máy Mac của bạn
1. Tại cột bên trái **Cho phép điều khiển** của cửa sổ chính:
   - Đọc dãy số **ID của bạn** (Your ID).
   - Đọc **Mật khẩu** (Password) ngẫu nhiên được cấp.
2. Gửi thông tin trên cho đối tác.
3. Khi đối tác thực hiện kết nối, bạn có toàn quyền theo dõi và bấm **Dừng chia sẻ** bất kỳ lúc nào để chấm dứt phiên làm việc ngay lập tức.

### 4.3 Tính năng an toàn: Smart Clipboard Guard
- Khi chia sẻ bảng tạm hai chiều giữa hai máy, Clipboard Guard tự động quét nội dung văn bản được sao chép.
- Nếu phát hiện các chuỗi khoá bảo mật (`BEGIN PRIVATE KEY`, API keys `sk-`, `ghp-`, chuỗi JWT token), Utralview sẽ chặn gửi sang máy kia và phát cảnh báo trên thanh trạng thái để bảo vệ tài khoản của bạn.

---

## 5. Danh mục phím tắt & Thao tác nhanh

| Thao tác | Phím tắt Mac | Tương đương trên Windows |
| :--- | :--- | :--- |
| Mở menu Start Windows | <kbd>⌘ Command</kbd> | <kbd>Windows Key</kbd> |
| Chuyển đổi ứng dụng | <kbd>⌘ + Tab</kbd> / <kbd>⌥ + Tab</kbd> | <kbd>Alt + Tab</kbd> |
| Sao chép nội dung | <kbd>⌘ + C</kbd> hoặc <kbd>⌃ + C</kbd> | <kbd>Ctrl + C</kbd> |
| Dán nội dung | <kbd>⌘ + V</kbd> hoặc <kbd>⌃ + V</kbd> | <kbd>Ctrl + V</kbd> |
| Bật / Tắt toàn màn hình | <kbd>⌃ + ⌘ + F</kbd> | Fullscreen Toggle |
| Ngắt phiên khẩn cấp | Bấm nút **Ngắt kết nối** (`⇧ + ⌘ + D`) | Session Terminate |

---

## 6. Xử lý sự cố thường gặp (Troubleshooting)

1. **Đối tác báo màn hình đen khi kết nối vào máy Mac:**
   - *Nguyên nhân:* Chưa cấp quyền Ghi màn hình (Screen Recording) cho Utralview for Mac.
   - *Khắc phục:* Mở **System Settings** → **Privacy & Security** → **Screen Recording** → gạt bật Utralview for Mac, sau đó khởi động lại ứng dụng.
2. **Đối tác chỉ xem được mà không di được chuột:**
   - *Nguyên nhân:* Chưa cấp quyền Trợ năng (Accessibility) hoặc bạn đang chọn chế độ chỉ xem.
   - *Khắc phục:* Mở **System Settings** → **Privacy & Security** → **Accessibility** → gạt bật Utralview for Mac.
3. **Mạng báo "Không thể kết nối tới máy chủ trung gian":**
   - *Khắc phục:* Kiểm tra lại kết nối Internet hoặc tường lửa/proxy của mạng công ty.

---

## 7. Thông tin liên hệ & Hỗ trợ kỹ thuật

- **Tổ chức chủ quản:** BASAN CORPORATION (BasanCorp)
- **Kho lưu trữ mã nguồn:** `https://github.com/trithucnen-max/macviewer`
- **Website:** `https://itngon.com`
- **Phiên bản tài liệu:** v2.3.3 (Cập nhật năm 2026)
