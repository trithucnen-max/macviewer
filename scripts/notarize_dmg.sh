#!/bin/bash
set -e

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$project_root/.env.local" ]]; then
  export $(grep -v '^#' "$project_root/.env.local" | xargs)
fi

keychain_profile="${NOTARY_KEYCHAIN_PROFILE:-basancorp-notary}"
target_file="${1:-$project_root/dist/Utralview-for-Mac-v2.3.3-Universal.dmg}"

if [[ ! -f "$target_file" ]]; then
  echo "❌ File not found: $target_file"
  exit 1
fi

echo "=========================================================="
echo "  Apple Notarization & Stapling Tool                      "
echo "  Keychain Profile: $keychain_profile                     "
echo "=========================================================="

echo "Submitting $target_file to Apple Notary Service..."
set +e
if [[ -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  output=$(xcrun notarytool submit "$target_file" \
    --apple-id "${APPLE_ID:-basancorp@gmail.com}" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "${APPLE_TEAM_ID:-JFT5TLZ3HK}" \
    --wait 2>&1)
else
  output=$(xcrun notarytool submit "$target_file" \
    --keychain-profile "$keychain_profile" \
    --wait 2>&1)
fi
exit_code=$?
set -e

echo "$output"

if [[ $exit_code -eq 0 ]]; then
  echo "✅ Notarization succeeded! Stapling ticket to DMG..."
  xcrun stapler staple "$target_file"
  echo "✅ Staple completed! App is now 100% notarized and ready for Gatekeeper-free distribution."
else
  echo ""
  echo "⚠️ Notarization pending or failed with code $exit_code."
  if echo "$output" | grep -q "agreement that has not been signed or has expired"; then
    echo "🚨 LƯU Ý QUAN TRỌNG:"
    echo "Tài khoản Apple Developer có điều khoản thoả thuận mới chưa được ký (Apple Developer Program License Agreement)."
    echo "Chủ tài khoản (Account Holder) chỉ cần đăng nhập https://developer.apple.com/account và nhấn 'Review Agreement' -> 'Accept'."
    echo "Sau khi accept, chạy lại './scripts/notarize_dmg.sh' để tự động công chứng file DMG."
  fi
fi
