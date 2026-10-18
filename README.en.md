<div align="center">

<img src="docs/images/app-icon.png" width="128" alt="MacViewer Icon">

# MacViewer v2.0
### BasanCorp Enterprise Edition

**Run UltraViewer natively on macOS: high-speed, secure remote desktop client engineered for Apple Silicon (M1/M2/M3/M4) and Intel Macs.**

[Tiếng Việt](README.md) · **English** · [PRD](PRD.md) · [User Guide](HUONG_DAN_SU_DUNG.md)

### [Download MacViewer v2.0 for macOS (GitHub Releases)](https://github.com/Trithucnen/macviewer/releases/latest)

Official v2.0.0 Release — Digitally signed by **BASAN CORPORATION**

[![Release](https://img.shields.io/github/v/release/Trithucnen/macviewer?sort=semver)](https://github.com/Trithucnen/macviewer/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B%20%7C%20Windows%20%7C%20Linux-lightgrey)
![Architecture](https://img.shields.io/badge/architecture-Universal%20(arm64%20%2B%20x86__64)-green)
![Security](https://img.shields.io/badge/signed-BASAN%20CORPORATION-success)

</div>

---

[UltraViewer](https://ultraviewer.net) is a popular remote desktop tool originally built for Windows. **MacViewer v2.0**, backed and developed by **BASAN CORPORATION**, brings a pure native solution to macOS and cross-platform ecosystems. It connects directly to computers running UltraViewer (or MacViewer) with exceptional responsiveness, ultra-low latency, and minimal resource usage.

Built with **Swift 6 & SwiftUI** on macOS paired with a high-performance **Rust core engine**, it runs zero Windows executables (`.exe`/`.dll`) and has zero Wine dependencies.

> [!NOTE]
> All official DMG release bundles are digitally signed with `Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)` with Apple Hardened Runtime and Timestamping, passing Apple Gatekeeper verification out of the box.

---

## What's New in v2.0

### 1. True Cross-Platform Architecture
- **macOS Universal (M1/M2/M3/M4 + Intel)**: A single unified package `MacViewer-2.0.0-Universal.dmg` running natively on all Apple Silicon and Intel machines running macOS Sonoma (14.0) or later.
- **Windows x86_64 & Windows ARM64 (Surface / Copilot+ PC)**: Lightweight cross-platform Rust engine for remote operations on Microsoft Surface Pro X and modern Windows ARM64 devices.
- **Linux x86_64 & aarch64**: Lean background daemon and CLI for server administrators.

### 2. Strict 3-Color Design System
- Focused industrial aesthetic with no distracting color clutter.
- Cohesive Dark Mode (Slate `#0D1117`) and Light Mode anchored by Cobalt Blue (`#2563EB`) and connection status Emerald Green (`#10B981`).

### 3. High Performance Remote Desktop
- End-to-end AES-128 and 3DES protocol support.
- Automatic Local Network Direct P2P discovery for maximum framerates.
- Retina 4K/5K multi-monitor support.
- Smart keyboard translation (<kbd>⌘</kbd> to Win, <kbd>⌥</kbd> to Alt, <kbd>⌃</kbd> to Ctrl).
- Integrated low-latency audio streaming powered by G.722 WebRTC decoder.
- Real-time in-session Chat and bidirectional Clipboard synchronization.

---

## Installation

1. Visit [**GitHub Releases**](https://github.com/Trithucnen/macviewer/releases/latest).
2. Download the appropriate image:
   - **`MacViewer-2.0.0-Universal.dmg`**: Recommended for both Apple Silicon and Intel Macs.
   - **`MacViewer-2.0.0-arm64.dmg`**: Optimized for M1/M2/M3/M4.
   - **`MacViewer-2.0.0-x86_64.dmg`**: For Intel Macs.
3. Open the `.dmg` and drag `MacViewer.app` to your `/Applications` directory.

---

## Copyright & License

- Copyright © 2026 **BASAN CORPORATION** (BasanCorp). All rights reserved.
- Released as open source under the [MIT License](LICENSE).
- UltraViewer is a trademark of its respective owner, mentioned solely for protocol interoperability.
