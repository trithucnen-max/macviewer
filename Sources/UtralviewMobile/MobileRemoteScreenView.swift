import SwiftUI
import CoreGraphics

#if canImport(UIKit)
import UIKit

public struct MobileRemoteScreenView: View {
    public let partnerId: String
    public let onDisconnect: () -> Void
    public let onSendMouse: (CGPoint, Int, Bool) -> Void
    public let onSendKey: (String) -> Void

    @State private var cursorPosition = CGPoint(x: 180, y: 300)
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showKeyboard = false

    public init(
        partnerId: String,
        onDisconnect: @escaping () -> Void,
        onSendMouse: @escaping (CGPoint, Int, Bool) -> Void,
        onSendKey: @escaping (String) -> Void
    ) {
        self.partnerId = partnerId
        self.onDisconnect = onDisconnect
        self.onSendMouse = onSendMouse
        self.onSendKey = onSendKey
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Status Bar
            HStack {
                Circle()
                    .fill(Color(red: 0.06, green: 0.73, blue: 0.51))
                    .frame(width: 8, height: 8)
                Text("ID: \(partnerId)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)

                Spacer()

                Button(action: { showKeyboard.toggle() }) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(red: 0.15, green: 0.39, blue: 0.92))
                }
                .padding(.horizontal, 8)

                Button("Ngắt kết nối", action: onDisconnect)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.08, green: 0.10, blue: 0.13))

            // Canvas Workspace with Virtual Cursor
            GeometryReader { geo in
                ZStack {
                    Color.black

                    // Remote cursor pointer
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .background(Circle().fill(Color(red: 0.15, green: 0.39, blue: 0.92)))
                        .frame(width: 14, height: 14)
                        .position(cursorPosition)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            cursorPosition = value.location
                            onSendMouse(cursorPosition, 0, false)
                        }
                )
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            onSendMouse(cursorPosition, 1, true)
                            onSendMouse(cursorPosition, 1, false)
                        }
                )
            }

            if showKeyboard {
                MobileKeyboardBar(onKeyPress: onSendKey)
            }
        }
        .background(Color.black)
    }
}
#endif
