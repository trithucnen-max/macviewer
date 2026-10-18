<div align="center">

<img src="docs/images/app-icon.png" width="128" alt="Utralview for Mac Icon">

# Utralview for Mac v2.2.2
### BasanCorp Enterprise Edition

**UltraViewer client tailored for macOS: high-speed, secure remote desktop control with full Apple Silicon (M1/M2/M3/M4) and Intel Mac support.**

[Tiếng Việt](README.md) · **English** · [PRD Specification](PRD.md) · [User Manual](HUONG_DAN_SU_DUNG.md)

### [Download Utralview for Mac v2.2.2 (GitHub Releases)](https://github.com/trithucnen-max/macviewer/releases/tag/v2.2.2)

Official Release v2.2.2 — Digitally signed by **BASAN CORPORATION**

[![Release](https://img.shields.io/github/v/release/trithucnen-max/macviewer?sort=semver)](https://github.com/trithucnen-max/macviewer/releases/tag/v2.2.2)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B%20%7C%20Windows%20%7C%20Linux%20%7C%20Surface-lightgrey)
![Architecture](https://img.shields.io/badge/architecture-Universal%20(arm64%20%2B%20x86__64)-green)
![Security](https://img.shields.io/badge/signed-BASAN%20CORPORATION-success)

</div>

---

## 🚀 Introduction

[UltraViewer](https://ultraviewer.net/en/) is a widely used remote desktop application on Windows. **Utralview for Mac v2.2.2**, developed by **BASAN CORPORATION**, is a high-performance native solution for macOS and cross-platform ecosystems. It enables swift, low-latency connections to computers running UltraViewer or Utralview with minimal CPU and memory footprints.

Built with **Swift 6 & SwiftUI** (for macOS) alongside a high-throughput **Rust** core protocol engine, Utralview executes without any Wine emulators or Windows `.exe`/`.dll` dependencies.

> [!NOTE]
> All DMG installer packages are digitally signed with `Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)`, equipped with Apple Hardened Runtime, Entitlements, and Apple Timestamping to satisfy macOS Gatekeeper security requirements.

---

## 📦 Download Installers for All Platforms (v2.2.2)

| Platform / Device | Package Name | Download Link | Architecture & Specs |
| :--- | :--- | :---: | :--- |
| 🍏 **macOS Universal** (Recommended) | `Utralview-for-Mac-v2.2.2-Universal.dmg` | [Download (.dmg)](https://github.com/trithucnen-max/macviewer/releases/download/v2.2.2/Utralview-for-Mac-v2.2.2-Universal.dmg) | Combined binary for Apple Silicon (M1-M4) & Intel Macs |
| 🍏 **macOS Apple Silicon** | `Utralview-for-Mac-v2.2.2-arm64.dmg` | [Download (.dmg)](https://github.com/trithucnen-max/macviewer/releases/download/v2.2.2/Utralview-for-Mac-v2.2.2-arm64.dmg) | Lightweight package dedicated for M1/M2/M3/M4 chips |
| 🍏 **macOS Intel** | `Utralview-for-Mac-v2.2.2-x86_64.dmg` | [Download (.dmg)](https://github.com/trithucnen-max/macviewer/releases/download/v2.2.2/Utralview-for-Mac-v2.2.2-x86_64.dmg) | Dedicated package for Intel CPU Macs |
| 🪟 **Windows 64-bit** | `Utralview-v2.2.2-windows-x86_64.zip` | [Download (.zip)](https://github.com/trithucnen-max/macviewer/releases/download/v2.2.2/Utralview-v2.2.2-windows-x86_64.zip) | For Windows 10/11 64-bit PCs & Laptops |
| 💻 **Microsoft Surface / Copilot+ PC** | `Utralview-v2.2.2-windows-arm64-surface.zip` | [Download (.zip)](https://github.com/trithucnen-max/macviewer/releases/download/v2.2.2/Utralview-v2.2.2-windows-arm64-surface.zip) | Optimized for Surface Pro X & ARM64 laptops |
| 🐧 **Linux 64-bit** | `Utralview-v2.2.2-linux-x86_64.tar.gz` | [Download (.tar.gz)](https://github.com/trithucnen-max/macviewer/releases/download/v2.2.2/Utralview-v2.2.2-linux-x86_64.tar.gz) | Ubuntu, Debian, Fedora, Arch Linux (CLI & Daemon) |
| 🤖 **Android (APK)** | `Utralview-v2.2.2-android.apk` | [Download (.apk)](https://github.com/trithucnen-max/macviewer/releases/download/v2.2.2/Utralview-v2.2.2-android.apk) | Direct APK package for Android smartphones and tablets |
| 📱 **iOS (iPhone & iPad)** | `Utralview-v2.2.2-ios.zip` | [Download](https://github.com/trithucnen-max/macviewer/releases/download/v2.2.2/Utralview-v2.2.2-ios.zip) | Touch-optimized client for iOS 17+ (SwiftUI Touch) |
| ⚙️ **macOS CLI (Universal)** | `utralview-cli-v2.2.2-macos-universal` | [Download](https://github.com/trithucnen-max/macviewer/releases/download/v2.2.2/utralview-cli-v2.2.2-macos-universal) | Standalone command-line tool for scripting and devops |
| 🛡️ **Checksums** | `SHA256SUMS.txt` | [View Hashes](https://github.com/trithucnen-max/macviewer/releases/download/v2.2.2/SHA256SUMS.txt) | SHA256 file verification hashes |

### Release Checksums (SHA-256)
```text
69fe873a0729cec37018b343c0660a30d08891aa040e533d7addd68e15146a2b  Utralview-for-Mac-v2.2.2-Universal.dmg
2055bb52344fa5e1116cb89285b1d06091458a2b24f00a5fd74698d100f447f6  Utralview-for-Mac-v2.2.2-arm64.dmg
43dcddf286eda7b61b7b407d24e711543132a38a23cde7f41ccf4cf1a1deaa6a  Utralview-for-Mac-v2.2.2-x86_64.dmg
e76d87e5b013f1f852d47db4fbcae95f3b09c8813830c4e2f91fd1220b911865  Utralview-v2.2.2-windows-arm64-surface.zip
bc2d52adeb844896335d660a957ff53d2ff580674c18bd7cd824e062953166ea  Utralview-v2.2.2-windows-x86_64.zip
15bbc085277ff0527e81a571ec4bce701da5ef25cf08bd8a7c4f923a07cb2e7a  Utralview-v2.2.2-linux-x86_64.tar.gz
4489319054d09fd08569a3e419e79db8164752965829a3c6b59a174fa62994ba  utralview-cli-v2.2.2-macos-universal
```

---

## 🛠️ Installation & Apple Gatekeeper Resolution

### 1. Standard Installation
1. Download the preferred DMG installer (Universal recommended).
2. Double-click the downloaded `.dmg` file.
3. Drag **`Utralview for Mac.app`** into your **`/Applications`** folder.

### 2. Resolving Gatekeeper Prompts
Browsers attach a quarantine attribute to downloaded binaries. Choose any of these quick solutions:

- **Method 1: One-Click Helper Script (Included in DMG)**
  - Double-click **`Mo-Utralview-Lan-Dau.command`** inside the DMG disk. It clears quarantine flags and launches Utralview immediately.
- **Method 2: System Settings**
  - Go to **System Settings** > **Privacy & Security**.
  - Scroll down to **Security** and click **"Open Anyway"** under Utralview for Mac.
- **Method 3: Terminal Command**
  ```bash
  xattr -cr "/Applications/Utralview for Mac.app"
  ```

---

## 🌟 Key Features in v2.2.2

### 1. Full Cross-Platform Support
- **macOS Universal (M1/M2/M3/M4 + Intel)**: Native performance on macOS 14.0 Sonoma and newer.
- **Windows x86_64 & Windows ARM64 (Surface / Copilot+ PC)**: Rust CLI engine tailored for Surface Pro X and Snapdragon X Elite.
- **Linux 64-bit**: Server daemons and command-line management for automated workflows.

### 2. Native 2-Column Interface
- Clean macOS navigation with dedicated sidebar for local credentials and main workspace for remote partner control.
- Tri-color design system: Slate (`#0D1117`), Cobalt Blue (`#2563EB`), Emerald Green (`#10B981`).

### 3. High Performance Remote Desktop
- AES-128 and 3DES standard UltraViewer cryptosuites.
- Peer-to-Peer LAN Direct connection for maximum local network frame rates.
- Retina 4K/5K resolution streaming.
- Intelligent keyboard mapping (<kbd>⌘</kbd> to <kbd>Win</kbd>, <kbd>⌥</kbd> to <kbd>Alt</kbd>, <kbd>⌃</kbd> to <kbd>Ctrl</kbd>).
- Low latency real-time audio playback using G.722 WebRTC decoder.
- Live chat and bidirectional clipboard synchronization.

### 4. Smart Clipboard Guard & Enterprise Security
- **Clipboard Guard:** Detects and blocks accidental clipboard sharing of sensitive credentials (private keys, JWT tokens, GitHub PATs, API keys).
- **Zero Telemetry:** No user tracking or behavioral analytics.
- **macOS Keychain:** Credential management integrated directly into Apple Keychain.

---

## 📜 License & Copyright

- Copyright © 2026 **BASAN CORPORATION**.
- Distributed under the [MIT License](LICENSE).
- UltraViewer is a trademark of its respective owner; mentioned strictly for interoperability documentation.
