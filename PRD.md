# Product Requirements Document (PRD)
## Dự án: Utralview for Mac v2.3.3 — BasanCorp Enterprise Edition

---

| **Thuộc tính** | **Chi tiết** |
| :--- | :--- |
| **Tên sản phẩm** | **Utralview for Mac v2.3.3** |
| **Đơn vị phát triển** | **BASAN CORPORATION (BasanCorp)** |
| **Bản quyền** | © 2026 BASAN CORPORATION. All rights reserved. |
| **Chứng chỉ ký số** | `Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)` |
| **Mã định danh (Bundle ID)** | `com.basancorp.utralview` |
| **Phiên bản** | `v2.3.3` (Build 233) |
| **Nền tảng mục tiêu** | macOS 14.0 Sonoma trở lên — Universal (`arm64` + `x86_64`) |
| **Trạng thái** | Phát hành chính thức (Production Ready) |
| **Kho mã nguồn** | `https://github.com/trithucnen-max/macviewer` |

---

## 1. Giới thiệu & Tầm nhìn sản phẩm

### 1.1 Bối cảnh
UltraViewer là giải pháp điều khiển máy tính từ xa phổ biến rộng rãi tại Việt Nam và khu vực, tuy nhiên phần mềm gốc chỉ hỗ trợ hệ điều hành Windows. Trước đây, người dùng máy Mac hoàn toàn bị cô lập hoặc phải chạy qua máy ảo nặng nề, không bảo đảm tính ổn định và bảo mật.

**Utralview for Mac v2.3.3** do **BASAN CORPORATION** phát triển và bảo trợ là ứng dụng macOS Native thế hệ mới, tái thiết kế toàn bộ hệ thống từ tầng giao thức (`UltraViewerProtocol`) đến giao diện hiển thị người dùng (`Utralview`), mang lại trải nghiệm điều khiển từ xa nguyên bản, tốc độ cao, tiêu thụ tài nguyên tối thiểu và tuân thủ các chuẩn mực bảo mật khắt khe nhất của Apple.

### 1.2 Mục tiêu cốt lõi
1. **Bảo mật tuyệt đối (Zero Windows Execution on Mac):** Tuyệt đối không thực thi binary Windows (`.exe`/`.dll`), không sử dụng Wine. Toàn bộ logic giao thức được thiết kế và thực thi bằng Swift 6 an toàn trên macOS.
2. **Ký số định danh doanh nghiệp (Developer ID Application):** Ứng dụng và bộ cài đặt DMG được ký số chính thức bởi `BASAN CORPORATION (JFT5TLZ3HK)` với Apple Hardened Runtime, Entitlements và Secure Timestamping.
3. **1 bản cài đặt macOS Universal duy nhất:**
   - Gói nhị phân hợp nhất (`arm64` + `x86_64`) chạy nguyên bản trên tất cả các dòng máy Mac dùng chip **Apple Silicon (M1/M2/M3/M4)** và chip **Intel** từ macOS 14.0 trở lên, giúp người dùng không bao giờ chọn nhầm phiên bản.
4. **Hệ thống thiết kế tối giản Chuẩn 3 Màu (Strict 3-Color Visual System):** Triệt tiêu hoàn toàn sự lộn xộn về màu sắc, mang lại diện mạo cơ khí hiện đại, tập trung vào năng suất và độ chính xác.
5. **Smart Clipboard Guard:** Ngăn chặn lộ lọt các chuỗi khoá nhạy cảm (Private Key, API token, JWT) khi bật tính năng đồng bộ clipboard.

---

## 2. Kiến trúc kỹ thuật (System Architecture)

### 2.1 Tầng Giao thức & Động cơ lõi (`UltraViewerProtocol` — Swift 6 + C)
- **Mã hoá lệnh (Legacy Command Cipher — 3DES)**: Tương thích thuật toán 3DES cấu hình tĩnh qua CommonCrypto, xử lý an toàn mật khẩu và block boundary.
- **Mã hoá AES truyền thông (`UltraViewerAES`)**: Tương thích cơ chế MD5 overlap key derivation đặc thù, sinh vector khởi tạo (IV) ngẫu nhiên tươi mới cho từng frame dữ liệu.
- **Giải nén & Nén hình ảnh siêu tốc (`CZstd`)**: Tích hợp thư viện C `libzstd` với cờ `ZSTD_LEGACY_SUPPORT=4` giải mã và nén các block dữ liệu định dạng v0.4–v0.7 của UltraViewer gốc.
- **Giải mã âm thanh (`CG722`)**: Thuật toán giải nén âm thanh WebRTC G.722 sub-band ADPCM 64 kbps băng rộng với độ trễ cực thấp.
- **Framing & Multipart Payload**: Ghép nối frame `[Header: 4 bytes length] [Payload]`, hỗ trợ kênh song song LAN Direct P2P (`TCPDirectPeerTransport`) và Relay (`FramedTCPTransport`).
- **Modern Screen Bitmap Renderer**: Giải mã và vẽ pixel trực tiếp lên bộ đệm frame RGBA với khả năng hỗ trợ đa màn hình Retina 4K/5K.

### 2.2 Tầng Giao diện & Trải nghiệm macOS (`Utralview` — SwiftUI / AppKit)
- **Kiến trúc Native:** Viết 100% bằng Swift 6, SwiftUI và AppKit, xử lý chụp màn hình qua `ScreenCaptureKit` và tách việc đóng gói pixel `RGB555` khỏi `@MainActor` để giữ tốc độ phản hồi giao diện mượt mà.
- **Cơ chế quyền riêng tư hai lớp:**
  - **Xem màn hình (Screen Recording)**: Hướng dẫn người dùng cấp quyền rõ ràng theo chuẩn Privacy & Security của macOS.
  - **Điều khiển chuột & bàn phím (Accessibility)**: Quyền điều khiển được cách ly độc lập, người dùng có thể cấp quyền xem mà không cho phép thao tác chuột/phím.
  - **Quản lý mật khẩu an toàn (macOS Keychain)**: Mật khẩu đối tác được lưu trữ mã hoá trong Keychain (`com.basancorp.utralview.partner-passwords`), tuyệt đối không lưu plaintext trong `UserDefaults`.
  - **Bảo vệ Bảng tạm (Clipboard Guard)**: Kiểm tra tự động các mẫu chuỗi bảo mật trước khi gửi qua mạng.

---

## 3. Hệ thống thiết kế (Design System: Strict 3-Color Architecture)

Tuân thủ nghiêm ngặt nguyên tắc thiết kế chuyên nghiệp không dùng màu thừa:

| Thứ tự | Vai trò token | Mã màu Dark Mode | Mã màu Light Mode | Ứng dụng thực tế |
| :---: | :--- | :--- | :--- | :--- |
| **Màu 1** | **Foundation Neutral** (Nền & Chữ) | `#0D1117` / `#161B22` / `#F0F6FC` | `#F6F8FA` / `#FFFFFF` / `#1F2328` | Background, Card Surface, Border, Primary Text, Secondary Text |
| **Màu 2** | **Accent Core** (Hành động chính) | `#2563EB` (Cobalt) | `#2563EB` (Cobalt) | Nút bấm chính (Connect), Focus Ring, Active Tab, Icon thương hiệu |
| **Màu 3** | **Status Signal** (Trạng thái hệ thống) | `#10B981` (Emerald) | `#059669` (Emerald) | Đèn tín hiệu Sẵn sàng kết nối, Badge trạng thái mạng, Checkmark xác nhận |

---

## 4. Gói cài đặt phát hành chính thức v2.3.3

| Nền tảng | Kiến trúc chip | Tên gói phát hành | Định dạng | Trạng thái ký số |
| :--- | :--- | :--- | :--- | :--- |
| **macOS Universal (Mọi máy Mac)** | Apple Silicon (`arm64`) & Intel (`x86_64`) | `Utralview-for-Mac-v2.3.3-Universal.dmg` | DMG Drag-and-Drop | Ký số Developer ID: BASAN CORPORATION (`JFT5TLZ3HK`) |

---

## 5. Tiêu chuẩn chất lượng & Kiểm thử (Verification & Quality Assurance)

1. **Swift Test Suite:** Kiểm thử tự động toàn diện trên cả hai tầng `UltraViewerProtocolTests` và `MacViewerTests` (bao gồm kiểm thử logic điều khiển từ xa, clipboard bảo mật, session tools, xác thực Keychain, nén/giải nén hình ảnh Zstd và giải mã âm thanh G.722).
2. **Apple Gatekeeper & Codesign Verification:** Lệnh `codesign --verify --deep --strict` xác nhận tính hợp lệ của chữ ký `BASAN CORPORATION` trên Universal binary (`arm64` + `x86_64`).
3. **Không thu thập dữ liệu (No Telemetry):** Không gửi dữ liệu người dùng, vị trí địa lý hoặc telemetry về bất kỳ máy chủ bên thứ ba nào.

---
*Biên soạn bởi Phòng Kỹ thuật BASAN CORPORATION (BasanCorp) — 2026.*
