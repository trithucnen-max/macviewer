# MacViewer Rust Edition (Engine & Cross-Platform Protocol)

Dự án tái hiện và chuyển dịch toàn bộ lõi giao thức remote desktop **UltraViewer** từ Swift sang **Rust (2021/2024 Edition)**.

## Kiến trúc Workspace

```
macviewer-rust/
├── Cargo.toml                      # Cargo workspace root
├── crates/
│   ├── ultraviewer-protocol/       # Lõi giao thức mạng, mã hoá và codec thuần Rust
│   │   ├── src/
│   │   │   ├── crypto/             # LegacyAES (MD5 overlap key derivation), LegacyCommandCipher (3DES)
│   │   │   ├── codecs/             # Zstd legacy (hỗ trợ v0.4-v0.7), G.722 audio decoder
│   │   │   ├── transport/          # LengthPrefixedFrame encoder & streaming decoder
│   │   │   ├── renderer/           # ModernScreenBitmap, RGB555 <-> BGRA32, BGR24 converter
│   │   │   ├── messages/           # Mouse, Keyboard, Chat, Multipart payload
│   │   │   └── session/            # Quản lý trạng thái phiên kết nối
│   │   └── c_src/                  # Mã nguồn C Zstandard legacy & G.722 biên dịch qua build.rs
│   ├── ultraviewer-ffi/            # Thư viện C-ABI (cdylib / staticlib) để nhúng vào Swift/macOS
│   └── ultraviewer-cli/            # Ứng dụng dòng lệnh kiểm thử kết nối UltraViewer
└── bindings/
    └── swift/                      # Swift Bridge để cắm trực tiếp vào MacViewer App hiện tại
```

## Kiểm thử & Xác thực (Test Verification)

Tất cả 21 unit tests đã được xác thực với bộ test vector độc lập từ Windows/OpenSSL:

```bash
# Chạy toàn bộ test suite
cargo test

# Chạy thử CLI client
cargo run -p ultraviewer-cli -- 12345678 password
```

## Điểm nhấn kỹ thuật đã hoàn thành:

1. **Mã hoá tương thích tuyệt đối (100% UltraViewer Compatible):**
   - Thuật toán `LegacyAES` với key derivation MD5 ghi đè byte thứ 15 đặc thù của UltraViewer.
   - Thuật toán `LegacyCommandCipher` 3DES với SHA-1 UTF-16LE.
2. **Codec nhúng trực tiếp C-FFI:**
   - Zstandard với flag `ZSTD_LEGACY_SUPPORT=4` đảm bảo giải nén được các luồng hình ảnh nén từ server UltraViewer cũ (v0.4 - v0.7).
   - Bộ giải mã âm thanh G.722 WebRTC decode ra 16kHz PCM audio.
3. **Hiệu năng & An toàn:**
   - Xử lý mượt mà ghép các khung hình bitmap (differential dirty rects) trực tiếp trong buffer BGRA 32-bit.
   - Thư viện C-ABI `libultraviewer_ffi` hỗ trợ cả dynamic library (`.dylib`) và static library (`.a`) để nhúng vào Xcode.
