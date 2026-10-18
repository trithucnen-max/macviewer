<div align="center">

<img src="docs/images/app-icon.png" width="128" alt="Biểu tượng MacViewer">

# MacViewer v2.0
### BasanCorp Enterprise Edition

**Dùng UltraViewer ngay trên máy Mac: điều khiển máy tính từ xa tốc độ cao, bảo mật tuyệt đối, hỗ trợ hoàn hảo Apple Silicon (M1/M2/M3/M4) và Intel.**

**Tiếng Việt** · [English](README.en.md) · [Tài liệu PRD](PRD.md) · [Hướng dẫn sử dụng](HUONG_DAN_SU_DUNG.md)

### [Tải về MacViewer v2.0 cho macOS (GitHub Releases)](https://github.com/Trithucnen/macviewer/releases/latest)

Bản phát hành chính thức v2.0.0 — Ký số doanh nghiệp bởi **BASAN CORPORATION**

[![Release](https://img.shields.io/github/v/release/Trithucnen/macviewer?sort=semver)](https://github.com/Trithucnen/macviewer/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B%20%7C%20Windows%20%7C%20Linux-lightgrey)
![Architecture](https://img.shields.io/badge/architecture-Universal%20(arm64%20%2B%20x86__64)-green)
![Security](https://img.shields.io/badge/signed-BASAN%20CORPORATION-success)

</div>

---

[UltraViewer](https://ultraviewer.net/vi/) là ứng dụng điều khiển máy tính phổ biến trên Windows. **MacViewer v2.0** do **BASAN CORPORATION** phát triển là giải pháp native hiện đại cho hệ sinh thái macOS và đa nền tảng, giúp kết nối tới các máy tính chạy UltraViewer (hoặc MacViewer) với hiệu năng vượt trội, độ trễ cực thấp và mức tiêu thụ tài nguyên tối thiểu.

Ứng dụng viết hoàn toàn bằng **Swift 6 & SwiftUI** (cho macOS) kết hợp động cơ giao thức lõi viết bằng **Rust**, không chạy bất kỳ file `.exe`/`.dll` nào của Windows và không phụ thuộc Wine.

> [!NOTE]
> Toàn bộ bản phát hành DMG chính thức đã được ký số bằng chứng chỉ `Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)` với Apple Hardened Runtime và Timestamping theo tiêu chuẩn kiểm định của Apple Gatekeeper.

---

## Tính năng nổi bật trên bản v2.0

### 1. Đa nền tảng toàn diện (Cross-Platform)
- **macOS Universal (M1/M2/M3/M4 + Intel)**: Gói cài đặt `MacViewer-2.0.0-Universal.dmg` tự động tương thích tối đa với mọi máy Mac chạy macOS Sonoma (14.0) trở lên.
- **Windows x86_64 & Windows ARM64 (Surface / Copilot+ PC)**: Engine UltraViewer Rust siêu nhẹ hỗ trợ điều khiển trên các dòng máy tính bảng Microsoft Surface Pro X và laptop ARM64 thế hệ mới.
- **Linux x86_64 & aarch64**: Daemon và CLI dành cho quản trị viên máy chủ và kỹ sư hệ thống.

### 2. Thiết kế tối giản Chuẩn 3 Màu (Strict 3-Color Architecture)
- Thiết kế giao diện cơ khí tối giản, triệt tiêu hoàn toàn màu sắc thừa thãi gây phân tâm.
- Hỗ trợ hoàn hảo chế độ Dark Mode (Slate `#0D1117`) và Light Mode với điểm nhấn Cobalt Blue (`#2563EB`) và tín hiệu trạng thái kết nối Emerald Green (`#10B981`).

### 3. Kết nối mượt mà & Điều khiển tức thì
- Kết nối thông qua mã hoá AES-128 và 3DES chuẩn giao thức UltraViewer.
- Tự động nhận diện kết nối ngang hàng mạng cục bộ (LAN Direct P2P) để đạt tốc độ hiển thị khung hình tối đa.
- Hỗ trợ màn hình Retina độ phân giải cao lên đến 4K/5K.
- Ánh xạ bàn phím thông minh: Phím <kbd>⌘</kbd> trên Mac tự động chuyển đổi thành phím <kbd>Win</kbd>, <kbd>⌥</kbd> thành <kbd>Alt</kbd>, và <kbd>⌃</kbd> thành <kbd>Ctrl</kbd>.
- Tích hợp nghe âm thanh từ máy đối tác theo thời gian thực (Audio Streaming qua G.722 WebRTC decoder).
- Hỗ trợ Chat trực tiếp và đồng bộ Clipboard hai chiều.

### 4. Quyền riêng tư & Bảo mật
- **Không Telemetry:** Ứng dụng không thu thập bất kỳ dữ liệu cá nhân hay lịch sử hoạt động nào của người dùng.
- **macOS Keychain:** Lưu trữ thông tin đăng nhập và mật khẩu an toàn trực tiếp trong Keychain của macOS.

---

## Cài đặt MacViewer v2.0

### Tải bộ cài DMG trực tiếp:
1. Truy cập trang [**Releases trên GitHub**](https://github.com/Trithucnen/macviewer/releases/latest).
2. Chọn gói cài đặt phù hợp:
   - **`MacViewer-2.0.0-Universal.dmg`**: Bản tối ưu nhất cho cả chip Apple Silicon và Intel.
   - **`MacViewer-2.0.0-arm64.dmg`**: Bản chuyên biệt cho Apple Silicon M1/M2/M3/M4.
   - **`MacViewer-2.0.0-x86_64.dmg`**: Bản chuyên biệt cho Mac Intel.
3. Mở file DMG và kéo `MacViewer.app` thả vào thư mục `/Applications`.

---

## Cấu trúc dự án

```
MacViewer/
├── Sources/
│   ├── MacViewer/              Giao diện người dùng SwiftUI v2.0 (Design System 3 màu)
│   └── UltraViewerProtocol/    Tầng giao thức kết nối, nén hình ảnh và âm thanh
├── macviewer-rust/             Động cơ giao thức Rust đa nền tảng (Win, Linux, Surface, Mac)
│   ├── crates/
│   │   ├── ultraviewer-protocol/   Crypto (AES/3DES), Zstd Legacy, G722, Renderer
│   │   ├── ultraviewer-ffi/        C-ABI dylib và static archive
│   │   └── ultraviewer-cli/        Công cụ CLI độc lập
│   └── bindings/swift/             Swift C-FFI Bridge
├── PRD.md                      Tài liệu yêu cầu sản phẩm chi tiết v2.0
├── HUONG_DAN_SU_DUNG.md        Hướng dẫn sử dụng đầy đủ
├── DESIGN.md                   Đặc tả hệ thống thiết kế 3 màu
└── scripts/                    Script tự động đóng gói Universal và ký số BasanCorp
```

---

## Giấy phép & Bản quyền

- Bản quyền phần mềm © 2026 **BASAN CORPORATION** (BasanCorp).
- Phát hành mã nguồn mở theo [Giấy phép MIT](LICENSE).
- UltraViewer là nhãn hiệu thuộc sở hữu của đơn vị chủ quản UltraViewer, được nhắc đến nhằm mục đích chỉ rõ khả năng tương thích của giao thức.
