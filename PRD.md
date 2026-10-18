# Product Requirements Document (PRD)
## Dự án: MacViewer v2.0 — BasanCorp Enterprise Edition

---

| **Thuộc tính** | **Chi tiết** |
| :--- | :--- |
| **Tên sản phẩm** | **MacViewer v2.0** |
| **Đơn vị phát triển** | **BASAN CORPORATION (BasanCorp)** |
| **Bản quyền** | © 2026 BASAN CORPORATION. All rights reserved. |
| **Chứng chỉ ký số** | `Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)` |
| **Mã định danh (Bundle ID)** | `com.basancorp.macviewer` |
| **Phiên bản** | `v2.0.0` (Build 200) |
| **Trạng thái** | Phát hành chính thức (Production Ready) |
| **Kho mã nguồn** | `https://github.com/Trithucnen/macviewer` |

---

## 1. Giới thiệu & Tầm nhìn sản phẩm

### 1.1 Bối cảnh
UltraViewer là giải pháp điều khiển máy tính từ xa phổ biến rộng rãi tại Việt Nam và khu vực, tuy nhiên phần mềm gốc chỉ hỗ trợ hệ điều hành Windows. Trước đây, người dùng máy Mac hoàn toàn bị cô lập hoặc phải chạy qua máy ảo nặng nề, không bảo đảm tính ổn định và bảo mật.

**MacViewer v2.0** do **BASAN CORPORATION** phát triển và bảo trợ là phiên bản kiến trúc thế hệ mới, tái thiết kế toàn bộ hệ thống từ tầng protocol, engine tính toán cho đến giao diện hiển thị người dùng, mang lại trải nghiệm điều khiển từ xa nguyên bản, tốc độ cao, tiêu thụ tài nguyên tối thiểu và tuân thủ các chuẩn mực bảo mật khắt khe nhất của Apple và các nền tảng hiện đại.

### 1.2 Mục tiêu cốt lõi
1. **Bảo mật tuyệt đối (Zero Windows Execution on Mac):** Tuyệt đối không thực thi binary Windows (`.exe`/`.dll`), không sử dụng Wine. Toàn bộ logic giao thức được thiết kế và thực thi an toàn trong môi trường sandbox của macOS.
2. **Ký số định danh doanh nghiệp (Developer ID Application):** Ứng dụng và bộ cài đặt DMG được ký số chính thức bởi `BASAN CORPORATION (JFT5TLZ3HK)` với Apple Hardened Runtime và Secure Timestamping, vượt qua kiểm định Apple Gatekeeper không cảnh báo rủi ro.
3. **Đa nền tảng toàn diện:**
   - **macOS Apple Silicon (M1/M2/M3/M4)**: Tối ưu hoá tối đa cho kiến trúc ARM64 Apple Silicon.
   - **macOS Intel (x86_64)**: Hỗ trợ trọn vẹn cho các dòng Mac Intel trước đây.
   - **macOS Universal 2**: Gói nhị phân hợp nhất hỗ trợ cả hai kiến trúc trong 1 file cài đặt duy nhất.
   - **Windows x86_64 & Windows ARM64 (Surface Pro / Copilot+ PC)**: Engine Rust độc lập phục vụ điều khiển và tự động hoá CLI/GUI.
   - **Linux x86_64 & aarch64**: Binary daemon và CLI siêu nhẹ cho server và máy trạm Linux.
4. **Hệ thống thiết kế tối giản Chuẩn 3 Màu (Strict 3-Color Visual System):** Triệt tiêu hoàn toàn sự lộn xộn về màu sắc, mang lại diện mạo cơ khí hiện đại, tập trung vào năng suất và độ chính xác.

---

## 2. Kiến trúc kỹ thuật (System Architecture)

### 2.1 Tầng Giao thức & Động cơ lõi (Core Engine - Rust)
- **Crate `ultraviewer-protocol`**:
  - **Mã hoá lệnh (Legacy Command Cipher - 3DES)**: Tương thích thuật toán 3DES cấu hình tĩnh với khóa chuyển đổi chuẩn, xử lý an toàn unicode password và block boundary.
  - **Mã hoá AES truyền thông (Legacy AES)**: Tương thích cơ chế MD5 overlap key derivation đặc thù, sinh vector khởi tạo (IV) ngẫu nhiên tươi mới cho từng frame dữ liệu.
  - **Giải nén hình ảnh siêu tốc (Zstandard Legacy Decoder)**: Tích hợp thư viện C FFI `libzstd` với cờ `ZSTD_LEGACY_SUPPORT=4` giải mã các block dữ liệu nén định dạng v0.4 của UltraViewer gốc.
  - **Giải mã âm thanh (G.722 WebRTC Decoder)**: Thuật toán giải nén âm thanh sub-band ADPCM 64 kbps băng rộng với độ trễ dưới 15ms.
  - **Framing & Chunking**: Ghép nối frame `[Header: 4 bytes length] [Payload]` và phân rã multipart payload mượt mà.
  - **Modern Screen Bitmap Renderer**: Thuật toán render và blit pixel trực tiếp lên bộ đệm frame RGBA/BGRA với khả năng co giãn đa màn hình Retina 4K/5K.
- **Crate `ultraviewer-ffi`**: Cung cấp C-ABI an toàn (`libultraviewer_ffi.dylib` và `libultraviewer_ffi.a`) để liên kết động/tĩnh với Swift hoặc các ngôn ngữ bậc cao khác.
- **Crate `ultraviewer-cli`**: Công cụ dòng lệnh độc lập hỗ trợ kết nối, truyền lệnh, benchmark và tự động hoá từ xa.

### 2.2 Tầng Giao diện & Trải nghiệm macOS (SwiftUI / AppKit)
- **Kiến trúc Native:** Viết 100% bằng Swift 6 và SwiftUI, tận dụng Apple Silicon Metal Acceleration để hiển thị màn hình mượt mà ở tần số quét ProMotion 120Hz.
- **Cơ chế quyền riêng tư hai lớp:**
  - **Xem màn hình (Screen Recording)**: Hướng dẫn người dùng cấp quyền rõ ràng theo chuẩn Privacy & Security của macOS Sequoia / Sonoma.
  - **Điều khiển chuột & bàn phím (Accessibility)**: Quyền điều khiển được cách ly độc lập, người dùng có thể cấp quyền xem mà không cho phép thao tác chuột/phím.
  - **Quản lý mật khẩu an toàn (macOS Keychain)**: Mật khẩu đối tác và mật khẩu ngẫu nhiên lưu trữ mã hóa trong Keychain của máy, không lưu plain text.

---

## 3. Hệ thống thiết kế (Design System: Strict 3-Color Architecture)

Tuân thủ nghiêm ngặt nguyên tắc thiết kế chuyên nghiệp không dùng màu thừa:

| Thứ tự | Vai trò token | Mã màu Dark Mode | Mã màu Light Mode | Ứng dụng thực tế |
| :---: | :--- | :--- | :--- | :--- |
| **Màu 1** | **Foundation Neutral** (Nền & Chữ) | `#0D1117` / `#161B22` / `#F0F6FC` | `#F6F8FA` / `#FFFFFF` / `#1F2328` | Background, Card Surface, Border, Primary Text, Secondary Text |
| **Màu 2** | **Accent Core** (Hành động chính) | `#2563EB` (Cobalt) | `#2563EB` (Cobalt) | Nút bấm chính (Connect), Focus Ring, Active Tab, Icon thương hiệu |
| **Màu 3** | **Status Signal** (Trạng thái hệ thống) | `#10B981` (Emerald) | `#059669` (Emerald) | Đèn tín hiệu Sẵn sàng kết nối, Badge trạng thái mạng, Checkmark xác nhận |

*Quy tắc cấm:* Tuyệt đối không dùng các màu phụ (tím gradient, cam, vàng chói lọi) làm rối mắt người dùng kỹ thuật.

---

## 4. Ma trận hỗ trợ nền tảng & Gói cài đặt

| Nền tảng | Kiến trúc chip | Tên gói phát hành | Định dạng | Trạng thái ký số |
| :--- | :--- | :--- | :--- | :--- |
| **macOS Universal** | Apple Silicon & Intel | `MacViewer-2.0.0-Universal.dmg` | DMG Drag-and-Drop | Ký số Developer ID: BASAN CORPORATION |
| **macOS Apple Silicon** | M1/M2/M3/M4 (arm64) | `MacViewer-2.0.0-arm64.dmg` | DMG Drag-and-Drop | Ký số Developer ID: BASAN CORPORATION |
| **macOS Intel** | Intel Core i5/i7/i9 (x86_64) | `MacViewer-2.0.0-x86_64.dmg` | DMG Drag-and-Drop | Ký số Developer ID: BASAN CORPORATION |
| **Windows x86_64** | Intel / AMD 64-bit | `macviewer-windows-x86_64.zip` | Portable Binary / Executable | CI/CD Automated Build |
| **Windows ARM64** | Surface Pro / Copilot+ PC | `macviewer-windows-arm64.zip` | Portable Binary / Executable | CI/CD Automated Build |
| **Linux x86_64** | Ubuntu / Debian / RHEL | `macviewer-linux-x86_64.tar.gz` | Tarball / Systemd service | CI/CD Automated Build |

---

## 5. Tiêu chuẩn chất lượng & Kiểm thử (Verification & Clean Code)

1. **Rust Core Tests:** Đạt 100% (21/21 test suites passed) bao gồm kiểm tra block padding, AES overlap, 3DES static key vectors, G.722 audio decoding, và Zstd decompression.
2. **Swift Compilation:** Biên dịch cảnh báo 0-error với Swift 6 release profile.
3. **Apple Gatekeeper Verification:** Lệnh `codesign --verify --deep --strict` và `spctl -a -t exec -vv` xác nhận tính hợp lệ của chữ ký BASAN CORPORATION.
4. **Không thu thập dữ liệu (No Telemetry):** Không gửi dữ liệu người dùng, vị trí địa lý hoặc telemetry về bất kỳ máy chủ bên thứ ba nào.

---
*Biên soạn bởi Phòng Kỹ thuật BASAN CORPORATION (BasanCorp) — 2026.*
