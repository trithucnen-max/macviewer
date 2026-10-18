<div align="center">

<img src="docs/images/app-icon.png" width="128" alt="Utralview for Mac Icon">

# Utralview for Mac v2.1.1
### BasanCorp Enterprise Edition

**Run UltraViewer on macOS: High-performance remote desktop, airtight security, full native support for Apple Silicon (M1/M2/M3/M4) and Intel.**

[Tiếng Việt](README.md) · **English** · [PRD Document](PRD.md) · [User Guide](HUONG_DAN_SU_DUNG.md)

### [Download Utralview for Mac v2.1.1 (GitHub Releases)](https://github.com/trithucnen-max/macviewer/releases/tag/v2.1.1)

Official Release v2.1.1 — Digitally signed by **BASAN CORPORATION**

[![Release](https://img.shields.io/github/v/release/trithucnen-max/macviewer?sort=semver)](https://github.com/trithucnen-max/macviewer/releases/tag/v2.1.1)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B%20%7C%20Windows%20%7C%20Linux%20%7C%20Surface-lightgrey)
![Architecture](https://img.shields.io/badge/architecture-Universal%20(arm64%20%2B%20x86__64)-green)
![Security](https://img.shields.io/badge/signed-BASAN%20CORPORATION-success)

</div>

---

## 🚀 About Utralview for Mac

[UltraViewer](https://ultraviewer.net/en/) is a widely used remote desktop application on Windows. **Utralview for Mac v2.1.1**, developed by **BASAN CORPORATION**, is a high-performance native solution for macOS and cross-platform ecosystems. It enables swift, low-latency connections to computers running UltraViewer or Utralview with minimal CPU and memory footprints.

Built with **Swift 6 & SwiftUI** (for macOS) paired with a high-performance **Rust** protocol core engine, requiring no Windows `.exe`/`.dll` binaries or Wine emulation.

> [!NOTE]
> All official DMG installers are digitally signed using `Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)` with Apple Hardened Runtime, Entitlements, and secure Timestamping in full compliance with Apple Gatekeeper.

---

## 📦 Download Installers for All Platforms (v2.1.1)

| Platform / Device | Release Artifact | Direct Download Link | Description & Architecture |
| :--- | :--- | :---: | :--- |
| 🍏 **macOS Universal** (Recommended) | `Utralview-for-Mac-v2.1.1-Universal.dmg` | [Download (.dmg)](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/Utralview-for-Mac-v2.1.1-Universal.dmg) | Combined binary for Apple Silicon (M1-M4) & Intel Macs |
| 🍏 **macOS Apple Silicon** | `Utralview-for-Mac-v2.1.1-arm64.dmg` | [Download (.dmg)](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/Utralview-for-Mac-v2.1.1-arm64.dmg) | Lightweight package dedicated for M1/M2/M3/M4 chips |
| 🍏 **macOS Intel** | `Utralview-for-Mac-v2.1.1-x86_64.dmg` | [Download (.dmg)](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/Utralview-for-Mac-v2.1.1-x86_64.dmg) | Dedicated package for Intel CPU Macs |
| 🪟 **Windows 64-bit** | `Utralview-v2.1.1-windows-x86_64.zip` | [Download (.zip)](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/Utralview-v2.1.1-windows-x86_64.zip) | For Windows 10/11 64-bit PCs & Laptops |
| 💻 **Microsoft Surface / Copilot+ PC** | `Utralview-v2.1.1-windows-arm64-surface.zip` | [Download (.zip)](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/Utralview-v2.1.1-windows-arm64-surface.zip) | Optimized for Surface Pro X & ARM64 laptops |
| 🐧 **Linux 64-bit** | `Utralview-v2.1.1-linux-x86_64.tar.gz` | [Download (.tar.gz)](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/Utralview-v2.1.1-linux-x86_64.tar.gz) | Ubuntu, Debian, Fedora, Arch Linux (CLI & Daemon) |
| ⚙️ **macOS CLI (Universal)** | `utralview-cli-v2.1.1-macos-universal` | [Download](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/utralview-cli-v2.1.1-macos-universal) | Standalone command-line tool for scripting and devops |
| 🛡️ **Checksums** | `SHA256SUMS.txt` | [View Hashes](https://github.com/trithucnen-max/macviewer/releases/download/v2.1.1/SHA256SUMS.txt) | SHA256 file verification hashes |

---

## 🛠️ Installation & macOS First-Time Launch Guide

### 1. Standard Installation
1. Download the `.dmg` installer (the **Universal** edition is recommended).
2. Double-click the downloaded DMG file.
3. Drag the **`Utralview for Mac.app`** icon into `/Applications`.

### 2. Resolving Gatekeeper Warning ("Apple cannot verify the developer")
When downloading apps via web browsers, macOS marks them with a quarantine flag. You can quickly launch the app via any of the following methods:

- **Method 1: Integrated 1-Click Launch Tool (Recommended)**
  - Double-click **`Mo-Utralview-Lan-Dau.command`** located directly inside the DMG.
  - The script clears the quarantine attribute and launches the application automatically.
- **Method 2: System Settings**
  - Go to **System Settings** > **Privacy & Security**.
  - Scroll down to the **Security** section where you will see *"Utralview for Mac was blocked..."*.
  - Click **"Open Anyway"** and confirm with your macOS password or Touch ID.
- **Method 3: Right-Click in Finder**
  - In `/Applications`, right-click (or hold `Control` and click) **`Utralview for Mac`**.
  - Select **Open** from the context menu, then click **Open** in the prompt dialog.
- **Method 4: Terminal Command**
  ```bash
  xattr -cr "/Applications/Utralview for Mac.app"
  ```

---

## 🌟 Key Features in v2.1.1

- **Cross-Platform**: Support across macOS (Apple Silicon + Intel), Windows x86_64, Windows ARM64 (Surface), and Linux x86_64.
- **Native 2-Column macOS Interface**: Dedicated hosting sidebar + clean partner workspace.
- **Strict 3-Color Visual Hierarchy**: Slate `#0D1117`, Cobalt Blue `#2563EB`, and Emerald Green `#10B981`.
- **Low-Latency & High Performance**: Hardware-accelerated rendering, AES-128 & 3DES encryption, LAN Direct P2P auto-discovery.
- **Audio & Peripherals**: Real-time G.722 audio streaming, bidirectional clipboard sync, smart modifier key translation.
- **Privacy & Security**: Zero telemetry, and saved credentials secured via macOS Keychain.

---

## 📜 License & Copyright

- Copyright © 2026 **BASAN CORPORATION** (BasanCorp).
- Released as open source under the [MIT License](LICENSE).
- UltraViewer is a registered trademark of its respective owner and is mentioned solely to state protocol interoperability.
