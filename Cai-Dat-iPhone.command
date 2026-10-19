#!/bin/bash
# ==============================================================================
# Trình Hướng Dẫn Cài Đặt Utralview for iPhone (iOS) - BasanCorp
# ==============================================================================

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "======================================================================"
echo "📱 CHƯƠNG TRÌNH HỖ TRỢ CÀI ĐẶT UTRALVIEW LÊN IPHONE (iOS)"
echo "   BasanCorp Enterprise Edition v2.3.3"
echo "======================================================================"
echo ""

IPA_URL="https://github.com/trithucnen-max/macviewer/releases/download/v2.3.3/Utralview-v2.3.3-ios.ipa"
IPA_DEST="$HOME/Downloads/Utralview-v2.3.3-ios.ipa"

echo "👉 Đang tải tệp cài đặt Utralview-v2.3.3-ios.ipa về thư mục Downloads..."
curl -fsSL -o "$IPA_DEST" "$IPA_URL" || true

if [ -f "$IPA_DEST" ]; then
    echo "✅ Đã tải tệp IPA thành công tại: $IPA_DEST"
else
    echo "⚠️ Tệp IPA đang được đồng bộ từ GitHub Release."
fi

echo ""
echo "----------------------------------------------------------------------"
echo "LỰA CHỌN PHƯƠNG THỨC CÀI ĐẶT:"
echo "1) [Khuyên dùng] Tải và mở Sideloadly (Cài 1-chạm không cần Xcode)"
echo "2) Mở App Store để cài đặt Xcode (Dành cho nhà phát triển)"
echo "3) Mở thư mục chứa tệp IPA trong Finder"
echo "4) Thoát"
echo "----------------------------------------------------------------------"
echo -n "Nhập lựa chọn của bạn (1/2/3/4) rồi nhấn Enter: "
read -r choice

case "$choice" in
    1)
        echo ""
        echo "🌐 Đang mở trang tải Sideloadly..."
        open "https://sideloadly.io"
        echo ""
        echo "📋 CÁC BƯỚC THỰC HIỆN VỚI SIDELOADLY:"
        echo " 1. Cài đặt và mở Sideloadly trên Mac."
        echo " 2. Cắm cáp iPhone vào máy Mac (chọn 'Tin cậy' trên màn hình iPhone)."
        echo " 3. Kéo tệp '$IPA_DEST' vào Sideloadly."
        echo " 4. Nhập Apple ID cá nhân của bạn và nhấn Start."
        echo " 5. Trên iPhone: Mở Cài đặt > Cài đặt chung > Quản lý VPN & Thiết bị > Chọn Tin cậy."
        echo "🎉 Hoàn tất! Biểu tượng Utralview đã sẵn sàng trên màn hình chính."
        ;;
    2)
        echo ""
        echo "🌐 Đang mở Mac App Store để tải Xcode..."
        open "macappstore://apps.apple.com/app/id497799835"
        ;;
    3)
        open -R "$IPA_DEST"
        ;;
    *)
        echo "Đã đóng trình hướng dẫn."
        ;;
esac

echo ""
read -p "Nhấn Enter để đóng cửa sổ..."
