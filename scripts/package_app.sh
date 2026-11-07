#!/bin/zsh
set -euo pipefail

# Produce the local signed Mac app without executing supplied Windows code.
project_root="${0:A:h:h}"
cd "$project_root"
configuration="${1:-release}"
if [[ "$configuration" != "release" && "$configuration" != "debug" ]]; then
  print -u2 "Usage: scripts/package_app.sh [release|debug]"
  exit 2
fi

signing_identity="${MACVIEWER_SIGNING_IDENTITY:-}"
identity_file="$project_root/dist/.macviewer-signing-identity"
if [[ -z "$signing_identity" && -f "$identity_file" ]]; then
  signing_identity="$(cat "$identity_file")"
fi
if [[ -z "$signing_identity" ]]; then
  if security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)"; then
    signing_identity="Developer ID Application: BASAN CORPORATION (JFT5TLZ3HK)"
  else
    development_identities=("${(@f)$(security find-identity -v -p codesigning 2>/dev/null | awk '/"Apple Development:/{print $2}')}" )
    if (( ${#development_identities[@]} == 1 )) && [[ "${development_identities[1]}" =~ '^[A-Fa-f0-9]{40}$' ]]; then
      signing_identity="${development_identities[1]}"
    else
      signing_identity="-"
    fi
  fi
fi

app_name="Utralview for Mac"
app_version="${MACVIEWER_VERSION:-2.3.3}"
build_number="${MACVIEWER_BUILD_NUMBER:-233}"
build_flags=(--configuration "$configuration")
if [[ "${MACVIEWER_UNIVERSAL:-1}" == "1" ]]; then
  build_flags+=(--arch arm64 --arch x86_64)
fi

swift build "${build_flags[@]}" --product MacViewer
binary_directory="$(swift build "${build_flags[@]}" --show-bin-path)"
app_directory="$project_root/dist/$app_name.app"
mkdir -p "$app_directory/Contents/MacOS" "$app_directory/Contents/Resources"
icon_directory="$project_root/.build/MacViewer.iconset"
swift scripts/make_app_icon.swift "$icon_directory"
iconutil -c icns "$icon_directory" -o "$app_directory/Contents/Resources/MacViewer.icns"
for language in en vi; do
  mkdir -p "$app_directory/Contents/Resources/$language.lproj"
  cp "Sources/Utralview/Resources/$language.lproj/Localizable.strings" "$app_directory/Contents/Resources/$language.lproj/Localizable.strings"
done
for bundle_name in MacViewer_MacViewer.bundle MacViewer_UltraViewerProtocol.bundle; do
  if [[ -d "$binary_directory/$bundle_name" ]]; then
    rm -rf "$app_directory/Contents/Resources/$bundle_name"
    cp -R "$binary_directory/$bundle_name" "$app_directory/Contents/Resources/"
  fi
done
mkdir -p "$app_directory/Contents/Resources/Licenses/Zstandard"
cp ThirdParty/zstd/LICENSE "$app_directory/Contents/Resources/Licenses/Zstandard/LICENSE"
cp ThirdParty/zstd/COPYING "$app_directory/Contents/Resources/Licenses/Zstandard/COPYING"
mkdir -p "$app_directory/Contents/Resources/Licenses/G722"
cp ThirdParty/g722/LICENSE "$app_directory/Contents/Resources/Licenses/G722/LICENSE"
cp ThirdParty/g722/WEBRTC_LICENSE "$app_directory/Contents/Resources/Licenses/G722/WEBRTC_LICENSE"
cp "$binary_directory/MacViewer" "$app_directory/Contents/MacOS/Utralview.new"
mv -f "$app_directory/Contents/MacOS/Utralview.new" "$app_directory/Contents/MacOS/Utralview"
chmod +x "$app_directory/Contents/MacOS/Utralview"
cp Sources/UltraViewerProtocol/Resources/8bit.dat "$app_directory/Contents/Resources/8bit.dat"
cat > "$app_directory/Contents/Info.plist" <<PLIST
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
  <key>CFBundleShortVersionString</key><string>$app_version</string>
  <key>CFBundleVersion</key><string>$build_number</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHumanReadableCopyright</key><string>Copyright © 2026 BASAN CORPORATION. All rights reserved.</string>
</dict>
</plist>
PLIST
if [[ "$signing_identity" == "-" ]]; then
  codesign --force --sign - --entitlements "$project_root/Sources/Utralview/Utralview.entitlements" "$app_directory"
else
  codesign --force --sign "$signing_identity" --entitlements "$project_root/Sources/Utralview/Utralview.entitlements" --options runtime --timestamp "$app_directory"
fi
codesign --verify --deep --strict "$app_directory"
touch "$app_directory/Contents" "$app_directory"
registration_tool="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ "${CI:-}" != "true" && -x "$registration_tool" ]]; then
  "$registration_tool" -f "$app_directory"
fi
print -r -- "$signing_identity" > "$identity_file"
print "App ready: $app_directory"
