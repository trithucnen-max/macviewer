import SwiftUI
import CoreGraphics

#if canImport(UIKit)
import UIKit

public struct MobileRemoteScreenView: View {
    @ObservedObject public var sessionManager: MobileSessionManager
    public let partnerId: String

    @State private var cursorNormalizedPosition = CGPoint(x: 0.5, y: 0.5)
    @State private var showKeyboard = false
    @State private var scale: CGFloat = 1.0
    @State private var lastDragPosition: CGPoint?

    public init(sessionManager: MobileSessionManager, partnerId: String) {
        self.sessionManager = sessionManager
        self.partnerId = partnerId
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Status Bar
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(sessionManager.currentFrame != nil ? Color(red: 0.06, green: 0.73, blue: 0.51) : Color.orange)
                        .frame(width: 8, height: 8)

                    Text("ID: \(partnerId)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)

                    Text("(\(sessionManager.remoteWidth)x\(sessionManager.remoteHeight))")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Button(action: { sessionManager.refreshScreen() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }

                Button(action: { showKeyboard.toggle() }) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.15, green: 0.39, blue: 0.92))
                        .padding(6)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }

                Button("Ngắt kết nối", action: { sessionManager.disconnect() })
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.85))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.08, green: 0.10, blue: 0.13))

            // Main Desktop Workspace
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()

                    if let cgImage = sessionManager.currentFrame {
                        let renderSize = calculateRenderSize(in: geo.size)
                        let originX = (geo.size.width - renderSize.width) / 2
                        let originY = (geo.size.height - renderSize.height) / 2
                        let screenRect = CGRect(origin: CGPoint(x: originX, y: originY), size: renderSize)

                        // Remote Screen Display
                        Image(decorative: cgImage, scale: 1.0, orientation: .up)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: renderSize.width, height: renderSize.height)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)

                        // Virtual Cursor Pointer
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .background(Circle().fill(Color(red: 0.15, green: 0.39, blue: 0.92).opacity(0.85)))
                            .frame(width: 20, height: 20)
                            .position(
                                x: screenRect.minX + cursorNormalizedPosition.x * screenRect.width,
                                y: screenRect.minY + cursorNormalizedPosition.y * screenRect.height
                            )
                            .shadow(color: .black.opacity(0.5), radius: 3)

                        // Touch Interaction Layer
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let relX = (value.location.x - screenRect.minX) / screenRect.width
                                        let relY = (value.location.y - screenRect.minY) / screenRect.height
                                        let normX = max(0, min(1, relX))
                                        let normY = max(0, min(1, relY))
                                        cursorNormalizedPosition = CGPoint(x: normX, y: normY)
                                        sessionManager.sendMouseMove(normalizedX: normX, normalizedY: normY)
                                    }
                                    .onEnded { value in
                                        let relX = (value.location.x - screenRect.minX) / screenRect.width
                                        let relY = (value.location.y - screenRect.minY) / screenRect.height
                                        let normX = max(0, min(1, relX))
                                        let normY = max(0, min(1, relY))
                                        cursorNormalizedPosition = CGPoint(x: normX, y: normY)
                                        sessionManager.sendMouseClick(normalizedX: normX, normalizedY: normY, isRightClick: false)
                                    }
                            )
                    } else {
                        // Connecting / Loading State
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)

                            Text(sessionManager.statusMessage.isEmpty ? "Đang kết nối tới máy tính Windows..." : sessionManager.statusMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            Text("Đang nhận luồng hình ảnh trực tiếp...")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
            }

            // Quick Mouse Bar (Left Click, Right Click, Scroll)
            HStack(spacing: 12) {
                Button(action: {
                    sessionManager.sendMouseClick(
                        normalizedX: cursorNormalizedPosition.x,
                        normalizedY: cursorNormalizedPosition.y,
                        isRightClick: false
                    )
                }) {
                    Label("Chuột trái", systemImage: "hand.tap")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.15, green: 0.39, blue: 0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button(action: {
                    sessionManager.sendMouseClick(
                        normalizedX: cursorNormalizedPosition.x,
                        normalizedY: cursorNormalizedPosition.y,
                        isRightClick: true
                    )
                }) {
                    Label("Chuột phải", systemImage: "hand.tap.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Spacer()

                Button(action: { sessionManager.sendMouseScroll(deltaY: 120) }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Button(action: { sessionManager.sendMouseScroll(deltaY: -120) }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 0.08, green: 0.10, blue: 0.13))

            // Virtual Keyboard Bar
            if showKeyboard {
                MobileKeyboardBar(onKeyPress: { key in
                    sessionManager.sendKey(key)
                })
            }
        }
        .background(Color.black)
    }

    private func calculateRenderSize(in viewSize: CGSize) -> CGSize {
        let imageAspect = CGFloat(sessionManager.remoteWidth) / CGFloat(max(1, sessionManager.remoteHeight))
        let viewAspect = viewSize.width / max(1, viewSize.height)

        if imageAspect > viewAspect {
            let width = viewSize.width
            let height = width / imageAspect
            return CGSize(width: width, height: height)
        } else {
            let height = viewSize.height
            let width = height * imageAspect
            return CGSize(width: width, height: height)
        }
    }
}
#endif
