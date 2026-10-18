# Kế hoạch chi tiết: Viết lại MacViewer bằng Rust (2 Giai đoạn)

> **File:** `macviewer-rust-plan.md`  
> **Dự án:** MacViewer (UltraViewer Client for macOS) → Rust Engine & Cross-Platform Desktop App  
> **Thời gian tạo:** 2026-10-17  
> **Chế độ:** PLANNING ONLY (Không viết code thực thi)

---

## 1. Tổng quan (Overview)

Mục tiêu của dự án là hiện đại hoá và mở rộng dự án **MacViewer** từ mã nguồn Swift 6 (vốn chỉ hỗ trợ macOS 14+) sang ngôn ngữ **Rust**, giải quyết 2 bài toán lớn:
1. **Hiệu năng & An toàn bộ nhớ:** Lõi giao thức mạng (TCP relay/peer), giải mã nén dữ liệu màn hình (Zstd legacy), xử lý âm thanh (G.722) và giải mã đồ hoạ (differential bitmap chunking) được tối ưu hoá tối đa bằng Rust không qua garbage collector/ARC overhead.
2. **Khả năng chạy đa nền tảng (Cross-Platform):** Đưa client kết nối UltraViewer lên cả **Linux**, **Windows** và **macOS** mà không phụ thuộc vào hệ sinh thái Apple thuần.

Lộ trình được chia làm **2 giai đoạn chiến lược**:
- **Giai đoạn 1:** Xây dựng crate `ultraviewer-protocol-rs` thuần Rust đóng gói thành thư viện, tích hợp ngược lại vào ứng dụng MacViewer (SwiftUI) qua FFI/UniFFI để kiểm chứng tính tương thích 100% với server UltraViewer thật mà không làm gián đoạn trải nghiệm người dùng.
- **Giai đoạn 2:** Phát triển ứng dụng Desktop độc lập hoàn chỉnh đa nền tảng bằng **Tauri v2 + Rust Engine**, thay thế hoàn toàn app Swift và hỗ trợ macOS, Linux, Windows.

---

## 2. Loại dự án & Yêu cầu thành công (Success Criteria)

- **Project Type:** `DESKTOP_SYSTEM` & `SYSTEM_LIBRARY`
- **Tiêu chuẩn hoàn thành (Measurable Outcomes):**
  - [ ] 100% test vectors của `LegacyAES` (MD5 overlap key derivation, PKCS7 padding) trên Swift pass trên Rust.
  - [ ] Giải mã thành công luồng Zstandard nén cũ (v0.4 - v0.7) từ UltraViewer protocol không crash.
  - [ ] Frame rate hiển thị màn hình qua Rust renderer đạt 60fps mượt mà, latency buffer < 16ms.
  - [ ] Crate `ultraviewer-protocol-rs` biên dịch được sang staticlib/cdylib và nhúng mượt vào Xcode/Swift.
  - [ ] Giai đoạn 2 build được bundle cài đặt `.dmg` (macOS), `.msi` (Windows) và `.deb` / `.AppImage` (Linux).

---

## 3. Tech Stack & Quyết định kiến trúc

| Thành phần | Công nghệ lựa chọn | Lý do lựa chọn |
|---|---|---|
| **Language** | Rust 2024 Edition (MSRV 1.85+) | An toàn bộ nhớ tuyệt đối, zero-cost abstractions, hiệu năng parse nhị phân cao. |
| **Async Runtime** | `tokio` (full) + `bytes` | Xử lý I/O non-blocking cho hàng chục luồng TCP relay, P2P peer và frame socket. |
| **Binary Parser** | `nom` + `byteorder` | Parse các cấu trúc frame nhị phân phức tạp của UltraViewer an toàn, không buffer overflow. |
| **Cryptography** | `aes`, `cbc`, `md-5` | Tái tạo chính xác thuật toán `LegacyAES` và cipher cũ của UltraViewer. |
| **Compression** | `zstd-sys` (C FFI với legacy support) | UltraViewer dùng stream Zstandard cũ (v0.4–v0.7); crate `zstd-sys` cho phép bật flag `ZSTD_LEGACY_SUPPORT=4`. |
| **Audio Codec** | `g722` (Rust port hoặc C FFI) | Giải mã luồng voice 16kHz PCM từ UltraViewer. |
| **FFI Bridge (Giai đoạn 1)** | `uniffi-rs` hoặc C-ABI | Tự động sinh Swift bindings an toàn, dễ bảo trì, zero manual pointer leaks. |
| **Desktop App (Giai đoạn 2)** | `Tauri v2` (Rust + Svelte/React + Canvas WebGL) | Tiết kiệm RAM, binary nhỏ gọn (<20MB so với Electron >150MB), native OS integration. |
| **OS Input & Capture** | `screencapturekit-rs` (macOS), `xcap` / `enigo` | Chụp màn hình và giả lập bàn phím/chuột đa nền tảng. |

---

## 4. Cấu trúc thư mục dự kiến (Workspace Structure)

```
macviewer-rust/
├── Cargo.toml                      # Cargo Workspace
├── crates/
│   ├── ultraviewer-protocol/       # GIAI ĐOẠN 1: Core Protocol Library
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── crypto/             # LegacyAES, MD5 overlap, PKCS7
│   │       ├── transport/          # Framed TCP, Relay, Direct P2P
│   │       ├── codecs/             # Zstd legacy decoder, G722 audio
│   │       ├── renderer/           # Screen pixel storage, differential bitmap 8/16/24/32bpp
│   │       ├── messages/           # Mouse, Keyboard, Cursor, Chat, Clipboard
│   │       └── session/            # HostSession & RelaySession state machines
│   ├── ultraviewer-ffi/            # GIAI ĐOẠN 1: UniFFI / C-ABI for Swift
│   │   ├── Cargo.toml
│   │   └── src/
│   │       └── lib.rs              # Swift binding definitions
│   └── ultraviewer-desktop/        # GIAI ĐOẠN 2: Tauri v2 App Backend
│       ├── Cargo.toml
│       └── src/
│           ├── main.rs
│           ├── capture/            # Screen capture (ScreenCaptureKit / DXGI / PipeWire)
│           ├── input/              # Input simulation (CGEvent / WinAPI / X11)
│           └── permissions/        # macOS Permissions & Keychain abstraction
├── bindings/
│   └── swift/                      # Generated Swift code for MacViewer app
└── ui/                             # GIAI ĐOẠN 2: Tauri Frontend (Canvas/WebGL + UI)
    ├── package.json
    ├── src/
    └── index.html
```

---

## 5. Phân rã nhiệm vụ (Task Breakdown)

### 📌 GIAI ĐOẠN 1: Crate `ultraviewer-protocol-rs` & Tích hợp FFI vào MacViewer

#### Task 1.1: Khởi tạo Workspace & Lớp Mã hoá `crypto` [x]
- **Agent:** `backend-specialist` (Rust Pro)
- **Skill:** `clean-code`, `rust-pro`
- **Kết quả:** Đã triển khai `crates/ultraviewer-protocol/src/crypto/legacy_aes.rs` và `legacy_command_cipher.rs`.
- **VERIFY:** 100% test vectors (MD5 overlap key derivation, PKCS7 padding, 3DES) khớp tuyệt đối với test vector Windows/OpenSSL.

#### Task 1.2: Codecs - Tích hợp Zstandard Legacy & G.722 Audio Decoder [x]
- **Agent:** `backend-specialist`
- **Skill:** `rust-pro`
- **Kết quả:** Biên dịch thành công mã nguồn C của `zstd` với `ZSTD_LEGACY_SUPPORT=4` và `g722_decode` qua `build.rs`.
- **VERIFY:** `test_zstd_compression_and_decompression_roundtrip` & `test_g722_create_and_decode` PASS.

#### Task 1.3: Network Framing & Relay/Peer Transport [x]
- **Agent:** `backend-specialist`
- **Skill:** `rust-pro`, `api-patterns`
- **Kết quả:** Đã viết `LengthPrefixedFrame` encoder và streaming `FrameDecoder` hỗ trợ phân mảnh và ghép frame.
- **VERIFY:** `test_encode_and_decode_roundtrip`, `test_fragmented_frame_reconstruction`, `test_coalesced_frames` PASS.

#### Task 1.4: Bộ giải mã đồ hoạ `ModernScreenRenderer` [x]
- **Agent:** `backend-specialist`
- **Skill:** `rust-pro`, `performance-profiling`
- **Kết quả:** `ModernScreenBitmap`, `ScreenPixelConverter` hỗ trợ RGB555 sang BGRA32, BGR24 sang BGRA32 và blit dirty rects.
- **VERIFY:** `test_pixel_conversions` và `test_bitmap_blitting` PASS.

#### Task 1.5: Giao thức Thông điệp Điều khiển (Input, Chat, Clipboard) [x]
- **Agent:** `backend-specialist`
- **Skill:** `rust-pro`
- **Kết quả:** `MouseMessage`, `KeyboardMessage`, `ChatProtocol`, `MultipartPayload` được hiện thực chuẩn xác.
- **VERIFY:** Test serialize/deserialize roundtrip PASS.

#### Task 1.6: Xây dựng FFI Bridge (C-ABI) & Tích hợp vào Xcode MacViewer [x]
- **Agent:** `backend-specialist` + `orchestrator`
- **Skill:** `rust-pro`, `verify-changes`
- **Kết quả:** Build thành công thư viện tĩnh `libultraviewer_ffi.a` và dynamic `libultraviewer_ffi.dylib`; tạo file cầu nối Swift [UltraViewerRustBridge.swift](file:///Users/kimtrungduong/Downloads/macviewer-rust/bindings/swift/UltraViewerRustBridge.swift).
- **VERIFY:** `cargo build -p ultraviewer-ffi` thành công với 0 cảnh báo.

---

### 📌 GIAI ĐOẠN 2: Ứng dụng Desktop Đa Nền Tảng Hoàn Chỉnh (Tauri v2 + Rust)

#### Task 2.1: Khởi tạo kiến trúc Tauri v2 & State Management
- **Agent:** `frontend-specialist` + `backend-specialist`
- **Skill:** `app-builder`, `clean-code`
- **Mục tiêu:** Scaffold project Tauri v2 tích hợp trực tiếp `ultraviewer-protocol`.
- **INPUT:** Workspace Rust hiện có.
- **OUTPUT:** Cấu trúc `crates/ultraviewer-desktop` và thư mục `ui/`.
- **VERIFY:** `cargo tauri dev` hiển thị cửa sổ giao diện chính nhập ID / Password.

#### Task 2.2: Hệ thống Chụp màn hình Đa nền tảng (Screen Capture Engine)
- **Agent:** `backend-specialist`
- **Skill:** `rust-pro`
- **Mục tiêu:** 
  - macOS: Binding `ScreenCaptureKit` (qua `screencapturekit-rs`).
  - Windows: Tích hợp Desktop Duplication API (DXGI).
  - Linux: Tích hợp X11 / Wayland (PipeWire).
- **INPUT:** `MacScreenCapture.swift`.
- **OUTPUT:** `crates/ultraviewer-desktop/src/capture/mod.rs`.
- **VERIFY:** Chụp được stream 30-60fps trên từng hệ điều hành mà CPU tiêu thụ < 8%.

#### Task 2.3: Giả lập Chuột & Bàn phím (Input Injection Engine)
- **Agent:** `backend-specialist`
- **Skill:** `rust-pro`
- **Mục tiêu:** Chuyển đổi mã phím từ xa sang OS events (`CGEvent` cho Mac, `SendInput` cho Windows, `uinput` cho Linux).
- **INPUT:** `MacHostInputController.swift`, `MacRemoteInputEncoder.swift`.
- **OUTPUT:** `crates/ultraviewer-desktop/src/input/mod.rs`.
- **VERIFY:** Thử nghiệm click, scroll trackpad, và gõ tổ hợp phím Win/Cmd/Alt trên máy khách.

#### Task 2.4: Giao diện Remote Screen Viewer (WebGL / WebGPU Canvas)
- **Agent:** `frontend-specialist`
- **Skill:** `frontend-design`, `antigravity-design-expert`
- **Mục tiêu:** Xây dựng màn hình hiển thị stream chất lượng cao, hỗ trợ zoom 4K, toolbar điều khiển, chat box, clipboard sync, fullscreen.
- **INPUT:** Wireframe và logic từ `RemoteScreenView.swift`, `ConnectionView.swift`.
- **OUTPUT:** Frontend Svelte/React kết nối với Rust stream qua SharedMemory / Binary IPC.
- **VERIFY:** Hiển thị video mượt mà, độ trễ input < 20ms trên mạng LAN.

#### Task 2.5: Đóng gói & Ký số Đa nền tảng (Packaging & Release CI)
- **Agent:** `backend-specialist`
- **Skill:** `deployment-procedures`
- **Mục tiêu:** Cấu hình GitHub Actions CI/CD xuất file release:
  - macOS: DMG & Universal Binary (Apple Silicon + Intel), cấu hình Notarization.
  - Windows: Installer `.msi` / `.exe`.
  - Linux: `.deb` và `.AppImage`.
- **INPUT:** `.github/workflows/ci.yml` và script đóng gói cũ.
- **OUTPUT:** Pipeline GitHub Actions tự động build đa nền tảng.
- **VERIFY:** Cài đặt và chạy thử trên cả 3 hệ điều hành thành công.

---

## 6. Phase X: Kế hoạch Kiểm tra & Nghiệm thu (Verification Checklist)

Trước khi coi dự án là hoàn thành, toàn bộ các tiêu chí sau phải được nghiệm thu thực tế:

- [ ] **Mã hoá:** `cargo test -p ultraviewer-protocol --lib crypto` đạt 100% pass (tương thích hoàn toàn với server UltraViewer).
- [ ] **Tương thích Protocol:** Kết nối thử nghiệm P2P và Relay trung gian giữa bản Rust và một máy Windows chạy UltraViewer 6.x chính thức.
- [ ] **Audio/Video Stream:** Hình ảnh không bị rách (tearing), không lệch màu palette 8-bit/16-bit, âm thanh G.722 không bị rè.
- [ ] **Độ an toàn bộ nhớ:** Chạy `cargo clippy --all-targets -- -D warnings` không có cảnh báo nào; chạy kiểm tra rò rỉ bộ nhớ với `valgrind` / Instruments không bị leak memory khi stream liên tục 2 giờ.
- [ ] **Quyền hệ thống:** Trên macOS, hiển thị đúng modal cấp quyền Screen Recording & Accessibility khi người dùng bắt đầu chia sẻ máy.

---

## 7. Kết luận & Khuyến nghị thực thi

Kế hoạch 2 giai đoạn này giúp kiểm soát rủi ro triệt để:
- **Giai đoạn 1** đảm bảo tính khả thi của giao thức ngược (Reverse Engineered Protocol) trong môi trường Rust trước khi bận tâm về giao diện.
- **Giai đoạn 2** giải phóng phần mềm khỏi sự phụ thuộc vào macOS, đưa UltraViewer trở thành ứng dụng client mã nguồn mở đa nền tảng mạnh mẽ.
