<div align="center">

<img src="docs/images/app-icon.png" width="128" alt="Biểu tượng Utralview for Mac">

# Utralview for Mac v2.1.1
### BasanCorp Enterprise Edition

**Dùng UltraViewer ngay trên máy Mac: điều khiển máy tính từ xa tốc độ cao, bảo mật tuyệt đối, hỗ trợ hoàn hảo Apple Silicon (M1/M2/M3/M4) và Intel.**

**Tiếng Việt** · [English](README.en.md) · [Tài liệu PRD](PRD.md) · [Hướng dẫn sử dụng](HUONG_DAN_SU_DUNG.md)

### [Tải về Utralview for Mac v2.1.1 cho macOS (GitHub Releases)](https://github.com/trithucnen-max/macviewer/releases/tag/v2.1.1)

Bản phát hành chính thức v2.1.1 — Ký số doanh nghiệp bởi **BASAN CORPORATION**

[![Release](https://img.shields.io/github/v/release/trithucnen-max/macviewer?sort=semver)](https://github.com/trithucnen-max/macviewer/releases/tag/v2.1.1)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B%20%7C%20Windows%20%7C%20Linux%20%7C%20Surface-lightgrey)
![Architecture](https://img.shields.io/badge/architecture-Universal%20(arm64%20%2B%20x86__64)-green)
![Security](https://img.shields.io/badge/signed-BASAN%20CORPORATION-success)

</div>

---

## 🚀 Giới thiệu Utralview for Mac

[UltraViewer](https://ultraviewer.net/vi/) là ứng dụng điều khiển máy tính phổ biến trên Windows. **Utralview for Mac v2.1.1** do **BASAN CORPORATION** phát triển là giải pháp native hiện đại cho hệ sinh thái macOS và đa nền tảng, giúp kết nối tới các máy tính chạy UltraViewer (hoặc Utralview) với hiệu năng vượt trội, độ trễ cực thấp và mức tiêu thụ tài nguyên tối thiểu.

Ứng dụng viết hoàn toàn bằng **Swift 6 & SwiftUI** (cho macOS) kết hợp động cơ giao thức lõi viết bằng **Rust**, không chạy bất kỳ file `.exe`/`.dll` nào của Windows và không phụ thuộc Wine.

> [!NOTE]
> Toàn bộ bản phát hành DMG chính thức đã được ký số bằng chứng chỉ `Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)` với Apple Hardened Runtime, Entitlements và Timestamping theo tiêu chuẩn kiểm định của Apple Gatekeeper.

---

## 📦 Danh sách link tải bộ cài đặt v2.1.1 cho các nền tảng

| Nền tảng / Thiết bị | Tên tệp phát hành | Link tải trực tiếp | Mô tả & Kiến trúc |
| :--- | :--- | :---: | :--- |
| 🍏 **macOS Universal** (Khuyên dùng) | `Utralview-for-Mac-v2.1.1-Universal.dmg` | [Tải về (.dmg)](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/Utralview-for-Mac-v2.1.1-Universal.dmg) | Tối ưu cho cả chip Apple Silicon (M1/M2/M3/M4) & Intel |
| 🍏 **macOS Apple Silicon** | `Utralview-for-Mac-v2.1.1-arm64.dmg` | [Tải về (.dmg)](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/Utralview-for-Mac-v2.1.1-arm64.dmg) | Bản riêng siêu nhẹ cho MacBook/Mac Mini chip M1-M4 |
| 🍏 **macOS Intel** | `Utralview-for-Mac-v2.1.1-x86_64.dmg` | [Tải về (.dmg)](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/Utralview-for-Mac-v2.1.1-x86_64.dmg) | Bản riêng cho các dòng Mac sử dụng CPU Intel (x86_64) |
| 🪟 **Windows 64-bit** | `Utralview-v2.1.1-windows-x86_64.zip` | [Tải về (.zip)](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/Utralview-v2.1.1-windows-x86_64.zip) | Dành cho Windows 10/11 64-bit PC & Laptop |
| 💻 **Microsoft Surface / Copilot+ PC** | `Utralview-v2.1.1-windows-arm64-surface.zip` | [Tải về (.zip)](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/Utralview-v2.1.1-windows-arm64-surface.zip) | Bản tối ưu cho Surface Pro X, Surface Laptop ARM64 |
| 🐧 **Linux 64-bit** | `Utralview-v2.1.1-linux-x86_64.tar.gz` | [Tải về (.tar.gz)](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/Utralview-v2.1.1-linux-x86_64.tar.gz) | Ubuntu, Debian, Fedora, Arch Linux (CLI & Daemon) |
| ⚙️ **macOS CLI (Universal)** | `utralview-cli-v2.1.1-macos-universal` | [Tải về](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/utralview-cli-v2.1.1-macos-universal) | Command-line tool độc lập cho lập trình viên & tự động hóa |
| 🛡️ **Bảng mã băm kiểm tra** | `SHA256SUMS.txt` | [Xem mã băm](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/SHA256SUMS.txt) | Dùng để đối soát tính toàn vẹn và bảo mật của tập tin |

---

## 🛠️ Hướng dẫn cài đặt & Khắc phục cảnh báo mở trên macOS

### 1. Cài đặt thông thường
1. Tải tệp `.dmg` phù hợp (khuyên dùng bản **Universal**).
2. Nhấp đúp vào tệp DMG đã tải về.
3. Kéo biểu tượng **`Utralview for Mac.app`** thả vào thư mục **`/Applications`**.

### 2. Khắc phục cảnh báo Apple Gatekeeper ("Apple không thể xác minh nhà phát triển")
Khi tải ứng dụng từ trình duyệt Web (Chrome, Safari), macOS sẽ tự động gắn cờ cách ly (Quarantine Flag). Bạn có thể mở nhanh bằng 1 trong các cách sau:

- **Cách 1: Sử dụng công cụ mở nhanh tích hợp trong DMG (Khuyên dùng)**
  - Bên trong file DMG có sẵn tệp **`Mo-Utralview-Lan-Dau.command`**.
  - Nhấp đúp chuột vào tệp này, hệ thống sẽ tự động gỡ bỏ cờ cách ly và khởi chạy ứng dụng ngay lập tức.
- **Cách 2: Cấp phép qua Cài đặt hệ thống (System Settings)**
  - Mở **Cài đặt hệ thống** (System Settings) > **Quyền riêng tư & Bảo mật** (Privacy & Security).
  - Cuộn xuống phần **Bảo mật** (Security), bạn sẽ thấy thông báo: *"Utralview for Mac đã bị chặn mở..."*.
  - Nhấp vào nút **"Vẫn mở"** (Open Anyway) và nhập mật khẩu máy Mac để xác nhận.
- **Cách 3: Mở bằng phím Control hoặc chuột phải**
  - Mở thư mục `/Applications`, nhấp chuột phải (hoặc giữ phím `Control` và bấm chuột) vào **`Utralview for Mac`**.
  - Chọn **Mở** (Open) > Bấm tiếp **Mở** (Open) trong hộp thoại xác nhận.
- **Cách 4: Sử dụng lệnh Terminal (Dành cho Pro/Admin)**
  ```bash
  xattr -cr "/Applications/Utralview for Mac.app"
  ```

---

## 🌟 Tính năng nổi bật trên bản v2.1.1

### 1. Đa nền tảng toàn diện (Cross-Platform)
- **macOS Universal (M1/M2/M3/M4 + Intel)**: Gói cài đặt tự động tương thích tối đa với mọi máy Mac chạy macOS Sonoma (14.0) trở lên.
- **Windows x86_64 & Windows ARM64 (Surface / Copilot+ PC)**: Engine Rust siêu nhẹ hỗ trợ điều khiển trên các dòng máy tính bảng Microsoft Surface Pro X và laptop ARM64 thế hệ mới.
- **Linux x86_64**: Daemon và CLI dành cho quản trị viên máy chủ và kỹ sư hệ thống.

### 2. Giao diện 2 cột Native & Hệ màu 3 sắc thái
- Bố cục 2 cột chuẩn mực gồm cột bên quản lý chia sẻ ID/Password và không gian làm việc kết nối đối tác.
- Hệ màu 3 sắc thái tối giản (Slate `#0D1117`, Cobalt Blue `#2563EB`, Emerald Green `#10B981`), loại bỏ hoàn toàn sự rối mắt, tối ưu tập trung cao độ.

### 3. Kết nối mượt mà & Điều khiển tức thì
- Kết nối thông qua mã hoá AES-128 và 3DES chuẩn giao thức UltraViewer.
- Tự động nhận diện kết nối ngang hàng mạng cục bộ (LAN Direct P2P) để đạt tốc độ hiển thị khung hình tối đa.
- Hỗ trợ màn hình Retina độ phân giải cao lên đến 4K/5K.
- Ánh xạ bàn phím thông minh: Phím <kbd>⌘</kbd> trên Mac tự động chuyển đổi thành phím <kbd>Win</kbd>, <kbd>⌥</kbd> thành <kbd>Alt</kbd>, và <kbd>⌃</kbd> thành <kbd>Ctrl</kbd>.
- Tích hợp nghe âm thanh từ máy đối tác theo thời gian thực (Audio Streaming qua G.722 WebRTC decoder).
- Hỗ trợ Chat trực tiếp và đồng bộ Clipboard hai chiều.

### 4. Quyền riêng tư & Bảo mật tối đa
- **Không Telemetry:** Ứng dụng không thu thập bất kỳ dữ liệu cá nhân hay lịch sử hoạt động nào của người dùng.
- **macOS Keychain:** Lưu trữ thông tin đăng nhập và mật khẩu an toàn trực tiếp trong Keychain của macOS.

---

## 📂 Cấu trúc dự án

```
MacViewer/
├── Sources/
│   ├── MacViewer/              Giao diện người dùng SwiftUI v2.1.1 (Native macOS Layout)
│   └── UltraViewerProtocol/    Tầng giao thức kết nối, nén hình ảnh và âm thanh
├── macviewer-rust/             Động cơ giao thức Rust đa nền tảng (Win, Linux, Surface, Mac)
│   ├── crates/
│   │   ├── ultraviewer-protocol/   Crypto (AES/3DES), Zstd Legacy, G722, Renderer
│   │   ├── ultraviewer-ffi/        C-ABI dylib và static archive
│   │   └── ultraviewer-cli/        Công cụ CLI độc lập
│   └── bindings/swift/             Swift C-FFI Bridge
├── PRD.md                      Tài liệu yêu cầu sản phẩm chi tiết v2.1.1
├── HUONG_DAN_SU_DUNG.md        Hướng dẫn sử dụng đầy đủ
├── DESIGN.md                   Đặc tả hệ thống thiết kế
└── scripts/                    Script tự động đóng gói Universal và ký số BasanCorp
```

---

## 📜 Giấy phép & Bản quyền

- Bản quyền phần mềm © 2026 **BASAN CORPORATION** (BasanCorp).
- Phát hành mã nguồn mở theo [Giấy phép MIT](LICENSE).
- UltraViewer là nhãn hiệu thuộc sở hữu của đơn vị chủ quản UltraViewer, được nhắc đến nhằm mục đích chỉ rõ khả năng tương thích của giao thức.
