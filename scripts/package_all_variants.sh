#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
cd "$project_root"

signing_identity="Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)"
version="${MACVIEWER_VERSION:-2.3.3}"
build_number="${MACVIEWER_BUILD_NUMBER:-233}"
app_name="Utralview for Mac"
app_dir="$project_root/dist/$app_name.app"
dmg_name="Utralview-for-Mac-v$version-Universal.dmg"
dmg_path="$project_root/dist/$dmg_name"

echo "=== Building $app_name v$version Universal (arm64 + x86_64) ==="

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

echo "=== Assembling Universal App Bundle ==="
rm -rf "$app_dir"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$project_root/.build/MacViewer.icns" "$app_dir/Contents/Resources/MacViewer.icns"

for language in en vi; do
  mkdir -p "$app_dir/Contents/Resources/$language.lproj"
  cp "Sources/Utralview/Resources/$language.lproj/Localizable.strings" "$app_dir/Contents/Resources/$language.lproj/Localizable.strings"
done

for bundle_name in MacViewer_MacViewer.bundle MacViewer_UltraViewerProtocol.bundle; do
  if [[ -d ".build/arm64-apple-macosx/release/$bundle_name" ]]; then
    cp -R ".build/arm64-apple-macosx/release/$bundle_name" "$app_dir/Contents/Resources/"
  fi
done

mkdir -p "$app_dir/Contents/Resources/Licenses/Zstandard"
cp ThirdParty/zstd/LICENSE "$app_dir/Contents/Resources/Licenses/Zstandard/LICENSE"
cp ThirdParty/zstd/COPYING "$app_dir/Contents/Resources/Licenses/Zstandard/COPYING"
mkdir -p "$app_dir/Contents/Resources/Licenses/G722"
cp ThirdParty/g722/LICENSE "$app_dir/Contents/Resources/Licenses/G722/LICENSE"
cp ThirdParty/g722/WEBRTC_LICENSE "$app_dir/Contents/Resources/Licenses/G722/WEBRTC_LICENSE"

cp ".build/universal/MacViewer" "$app_dir/Contents/MacOS/Utralview"
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

if security find-identity -v -p codesigning | grep -q "$signing_identity"; then
  echo "Signing Universal bundle with Developer ID ($signing_identity)..."
  codesign --force --sign "$signing_identity" \
    --entitlements "$project_root/Sources/Utralview/Utralview.entitlements" \
    --options runtime --timestamp "$app_dir"
else
  echo "Developer ID not in keychain, signing Universal bundle ad-hoc..."
  codesign --force --sign - \
    --entitlements "$project_root/Sources/Utralview/Utralview.entitlements" \
    "$app_dir"
fi
codesign --verify --deep --strict "$app_dir"
echo "Verified Universal bundle: OK"

echo "=== Building Single Universal DMG Installer ==="
staging_dir="$(mktemp -d)"
cp -R "$app_dir" "$staging_dir/"
ln -s /Applications "$staging_dir/Applications"

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

if security find-identity -v -p codesigning | grep -q "$signing_identity"; then
  echo "Signing $dmg_name with Developer ID..."
  codesign --force --sign "$signing_identity" --timestamp "$dmg_path"
  codesign --verify --verbose "$dmg_path"
  echo "Verified $dmg_name: OK"
  if [[ -x "$project_root/scripts/notarize_dmg.sh" && "${CI:-}" != "true" ]]; then
    "$project_root/scripts/notarize_dmg.sh" "$dmg_path" || true
  fi
else
  echo "Skipping Developer ID signature for $dmg_name (running in CI environment)"
fi

echo "=== Generating SHA256SUMS.txt ==="
(
  cd "$project_root/dist"
  shasum -a 256 "$dmg_name" > SHA256SUMS.txt
  cp SHA256SUMS.txt "$project_root/SHA256SUMS.txt"
)

echo "=== Universal DMG packaged, signed, and checksummed! ==="
ls -lh "$dmg_path"
cat "$project_root/dist/SHA256SUMS.txt"
