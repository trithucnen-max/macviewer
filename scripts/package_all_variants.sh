#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
cd "$project_root"

signing_identity="Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)"
version="2.1.1"
build_number="211"
app_name="Utralview for Mac"

echo "=== Building $app_name v$version for arm64 & x86_64 ==="

swift build -c release --triple arm64-apple-macosx14.0 --product MacViewer
swift build -c release --triple x86_64-apple-macosx14.0 --product MacViewer

mkdir -p .build/universal
lipo -create -output .build/universal/MacViewer \
  .build/arm64-apple-macosx/release/MacViewer \
  .build/x86_64-apple-macosx/release/MacViewer

echo "=== Generating Application Icons ==="
icon_directory="$project_root/.build/MacViewer.iconset"
swift scripts/make_app_icon.swift "$icon_directory"
mkdir -p "$project_root/.build"
iconutil -c icns "$icon_directory" -o "$project_root/.build/MacViewer.icns"

create_bundle() {
  local arch="$1"
  local bin_src="$2"
  local app_dir="$project_root/dist/$arch/$app_name.app"

  rm -rf "$app_dir"
  mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
  cp "$project_root/.build/MacViewer.icns" "$app_dir/Contents/Resources/MacViewer.icns"

  for language in en vi; do
    mkdir -p "$app_dir/Contents/Resources/$language.lproj"
    cp "Sources/MacViewer/Resources/$language.lproj/Localizable.strings" "$app_dir/Contents/Resources/$language.lproj/Localizable.strings"
  done

  if [[ -d ".build/arm64-apple-macosx/release/MacViewer_MacViewer.bundle" ]]; then
    cp -R ".build/arm64-apple-macosx/release/MacViewer_MacViewer.bundle" "$app_dir/Contents/Resources/"
  fi

  mkdir -p "$app_dir/Contents/Resources/Licenses/Zstandard"
  cp ThirdParty/zstd/LICENSE "$app_dir/Contents/Resources/Licenses/Zstandard/LICENSE"
  cp ThirdParty/zstd/COPYING "$app_dir/Contents/Resources/Licenses/Zstandard/COPYING"
  mkdir -p "$app_dir/Contents/Resources/Licenses/G722"
  cp ThirdParty/g722/LICENSE "$app_dir/Contents/Resources/Licenses/G722/LICENSE"
  cp ThirdParty/g722/WEBRTC_LICENSE "$app_dir/Contents/Resources/Licenses/G722/WEBRTC_LICENSE"

  cp "$bin_src" "$app_dir/Contents/MacOS/Utralview"
  chmod +x "$app_dir/Contents/MacOS/Utralview"
  cp Sources/UltraViewerProtocol/Resources/8bit.dat "$app_dir/Contents/Resources/8bit.dat"

  cat > "$app_dir/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>Utralview</string>
  <key>CFBundleIdentifier</key><string>com.basancorp.utralview</string>
  <key>CFBundleName</key><string>$app_name</string>
  <key>CFBundleDisplayName</key><string>$app_name</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>MacViewer.icns</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleLocalizations</key><array><string>en</string><string>vi</string></array>
  <key>CFBundleShortVersionString</key><string>$version</string>
  <key>CFBundleVersion</key><string>$build_number</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHumanReadableCopyright</key><string>Copyright © 2026 BASAN CORPORATION. All rights reserved.</string>
</dict>
</plist>
PLIST

  echo "Signing $arch bundle with entitlements..."
  codesign --force --sign "$signing_identity" \
    --entitlements "$project_root/Sources/MacViewer/Ultraview.entitlements" \
    --options runtime --timestamp "$app_dir"
  codesign --verify --deep --strict "$app_dir"
  echo "Verified $arch bundle: OK"
}

create_bundle "arm64" ".build/arm64-apple-macosx/release/MacViewer"
create_bundle "x86_64" ".build/x86_64-apple-macosx/release/MacViewer"
create_bundle "universal" ".build/universal/MacViewer"

# Copy Universal to dist/Utralview for Mac.app as main app
rm -rf "$project_root/dist/$app_name.app"
cp -R "$project_root/dist/universal/$app_name.app" "$project_root/dist/$app_name.app"

echo "=== Building DMG Installers with Gatekeeper Bypass Helper ==="
create_dmg() {
  local arch="$1"
  local dmg_name="Utralview-for-Mac-v$version-$arch.dmg"
  local dmg_path="$project_root/dist/$dmg_name"
  local staging_dir="$(mktemp -d)"

  echo "Creating DMG for $arch -> $dmg_name..."
  cp -R "$project_root/dist/$arch/$app_name.app" "$staging_dir/"
  ln -s /Applications "$staging_dir/Applications"

  # Helper script for 1-click Gatekeeper bypass
  cat > "$staging_dir/Mo-Utralview-Lan-Dau.command" <<'LAUNCHER'
#!/bin/bash
clear
echo "=========================================================="
echo "  Kích hoạt Utralview for Mac (Bỏ chặn Apple Gatekeeper)  "
echo "  Bản quyền © 2026 BASAN CORPORATION                     "
echo "=========================================================="
echo ""
echo "Đang cấp phép mở ứng dụng an toàn..."
xattr -cr /Applications/"Utralview for Mac.app" 2>/dev/null || true
xattr -cr "$(dirname "$0")"/"Utralview for Mac.app" 2>/dev/null || true
echo "✅ Đã gỡ bỏ giới hạn cách ly (Quarantine Flag) thành công!"
echo "🚀 Đang khởi động Utralview for Mac..."
open /Applications/"Utralview for Mac.app" 2>/dev/null || open "$(dirname "$0")"/"Utralview for Mac.app"
exit 0
LAUNCHER
  chmod +x "$staging_dir/Mo-Utralview-Lan-Dau.command"

  rm -f "$dmg_path"
  hdiutil create -volname "$app_name" -srcfolder "$staging_dir" -ov -format UDZO "$dmg_path"
  rm -rf "$staging_dir"

  echo "Signing $dmg_name with Developer ID..."
  codesign --force --sign "$signing_identity" --timestamp "$dmg_path"
  codesign --verify --verbose "$dmg_path"
  echo "Verified $dmg_name: OK"
}

create_dmg "Universal"
create_dmg "arm64"
create_dmg "x86_64"

echo "=== All DMG variants packaged and signed! ==="
ls -lh "$project_root/dist/"Utralview-for-Mac-v$version-*.dmg
