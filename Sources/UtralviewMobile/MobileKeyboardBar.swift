import SwiftUI

#if canImport(UIKit)
import UIKit

public struct MobileKeyboardBar: View {
    public let onKeyPress: (String) -> Void
    private let keys = ["Esc", "Tab", "Ctrl", "Alt", "Win", "Shift", "Del", "Enter", "↑", "↓", "←", "→"]

    public init(onKeyPress: @escaping (String) -> Void) {
        self.onKeyPress = onKeyPress
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(keys, id: \.self) { key in
                    Button(action: { onKeyPress(key) }) {
                        Text(key)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.15, green: 0.17, blue: 0.20))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(Color(red: 0.08, green: 0.10, blue: 0.13))
    }
}
#endif
