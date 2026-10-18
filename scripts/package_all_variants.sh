#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
cd "$project_root"

signing_identity="Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)"
version="2.0.0"
build_number="200"

echo "=== Building MacViewer v$version for arm64 & x86_64 ==="

swift build -c release --triple arm64-apple-macosx14.0 --product MacViewer
swift build -c release --triple x86_64-apple-macosx14.0 --product MacViewer

mkdir -p .build/universal
lipo -create -output .build/universal/MacViewer \
  .build/arm64-apple-macosx/release/MacViewer \
  .build/x86_64-apple-macosx/release/MacViewer

echo "=== Packaging App Bundles ==="
icon_directory="$project_root/.build/MacViewer.iconset"
swift scripts/make_app_icon.swift "$icon_directory"
mkdir -p "$project_root/.build"
iconutil -c icns "$icon_directory" -o "$project_root/.build/MacViewer.icns"

create_bundle() {
  local arch="$1"
  local bin_src="$2"
  local app_dir="$project_root/dist/$arch/MacViewer.app"

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

  cp "$bin_src" "$app_dir/Contents/MacOS/MacViewer"
  chmod +x "$app_dir/Contents/MacOS/MacViewer"
  cp Sources/UltraViewerProtocol/Resources/8bit.dat "$app_dir/Contents/Resources/8bit.dat"

  cat > "$app_dir/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>MacViewer</string>
  <key>CFBundleIdentifier</key><string>com.basancorp.macviewer</string>
  <key>CFBundleName</key><string>MacViewer</string>
  <key>CFBundleDisplayName</key><string>MacViewer</string>
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

  echo "Signing $arch bundle..."
  codesign --force --sign "$signing_identity" --options runtime --timestamp "$app_dir"
  codesign --verify --deep --strict "$app_dir"
  echo "Verified $arch bundle signature: OK"
}

create_bundle "arm64" ".build/arm64-apple-macosx/release/MacViewer"
create_bundle "x86_64" ".build/x86_64-apple-macosx/release/MacViewer"
create_bundle "universal" ".build/universal/MacViewer"

# Copy Universal to dist/MacViewer.app as main app
rm -rf "$project_root/dist/MacViewer.app"
cp -R "$project_root/dist/universal/MacViewer.app" "$project_root/dist/MacViewer.app"

echo "=== Building DMG Installers ==="
create_dmg() {
  local arch="$1"
  local dmg_name="MacViewer-$version-$arch.dmg"
  local dmg_path="$project_root/dist/$dmg_name"
  local staging_dir="$(mktemp -d)"

  echo "Creating DMG for $arch -> $dmg_name..."
  cp -R "$project_root/dist/$arch/MacViewer.app" "$staging_dir/"
  ln -s /Applications "$staging_dir/Applications"

  rm -f "$dmg_path"
  hdiutil create -volname "MacViewer" -srcfolder "$staging_dir" -ov -format UDZO "$dmg_path"
  rm -rf "$staging_dir"

  echo "Signing $dmg_name..."
  codesign --force --sign "$signing_identity" --timestamp "$dmg_path"
  codesign --verify --verbose "$dmg_path"
  echo "Verified $dmg_name: OK"
}

create_dmg "Universal"
create_dmg "arm64"
create_dmg "x86_64"

echo "=== All variants successfully built, packaged, and signed! ==="
ls -lh "$project_root/dist/"*.dmg
