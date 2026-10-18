import SwiftUI

/// Hệ thống Design System 3 màu tối giản, đạt chuẩn UX/UI Apple Human Interface Guidelines:
/// 1. Foundation Neutral: Monochrome Slate (nền, bề mặt card, viền, chữ chính và phụ)
/// 2. Accent Core: Electric Cobalt (#2563EB - Nút hành động chính, tiêu điểm, tương tác)
/// 3. Status Signal: Sage Emerald (#10B981 - Trạng thái sẵn sàng, kết nối, quyền hạn)
public enum MacTheme {
    // 1. Foundation Neutral
    public static let baseBackground = Color(nsColor: .windowBackgroundColor)
    public static let cardBackground = Color(nsColor: .controlBackgroundColor)
    public static let cardBorder = Color.primary.opacity(0.08)
    public static let textPrimary = Color.primary
    public static let textSecondary = Color.secondary
    public static let surfaceSubtle = Color.primary.opacity(0.03)

    // 2. Accent Core (Electric Cobalt #2563EB)
    public static let accent = Color(red: 37 / 255, green: 99 / 255, blue: 235 / 255)
    public static let accentSubtle = accent.opacity(0.08)
    public static let accentBorder = accent.opacity(0.25)

    // 3. Status Signal (Sage Emerald #10B981)
    public static let signal = Color(red: 16 / 255, green: 185 / 255, blue: 129 / 255)
    public static let signalSubtle = signal.opacity(0.08)
    public static let signalBorder = signal.opacity(0.25)

    // Cấu hình góc bo chuẩn mực
    public static let radiusCard: CGFloat = 12
    public static let radiusControl: CGFloat = 8
    public static let radiusBadge: CGFloat = 6
}
