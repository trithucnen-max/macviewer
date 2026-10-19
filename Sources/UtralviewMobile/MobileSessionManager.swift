import Foundation
import CoreGraphics
import SwiftUI
import UltraViewerProtocol

#if canImport(UIKit)
import UIKit

@MainActor
public final class MobileSessionManager: ObservableObject {
    public enum ConnectionState: Equatable {
        case disconnected
        case connecting(String)
        case connected
        case failed(String)
    }

    @Published public private(set) var state: ConnectionState = .disconnected
    @Published public private(set) var currentFrame: CGImage?
    @Published public private(set) var remoteWidth: Int = 1920
    @Published public private(set) var remoteHeight: Int = 1080
    @Published public private(set) var partnerDisplayName: String = "Windows PC"
    @Published public private(set) var allowsInput: Bool = true
    @Published public private(set) var statusMessage: String = ""
    @Published public private(set) var frameCount: Int = 0

    private var session: UltraViewerRelaySession?
    private var readTask: Task<Void, Never>?
    private var currentToken = UUID()

    public init() {}

    public func connect(partnerId: String, password: String) {
        disconnect()
        let token = UUID()
        currentToken = token
        state = .connecting("Đang kết nối tới máy chủ UltraViewer...")
        statusMessage = "Đang kết nối..."

        let cleanId = partnerId.filter { $0.isNumber }
        let cleanPwd = password.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                let profile = try MobileRegistrationProfile.loadOrCreate()
                let screenBounds = UIScreen.main.bounds
                let scale = UIScreen.main.scale
                let localW = Int32(clamping: Int(screenBounds.width * scale))
                let localH = Int32(clamping: Int(screenBounds.height * scale))

                var configuration = UltraViewerRelaySession.Configuration(
                    registration: profile,
                    localScreenWidth: localW > 0 ? localW : 1170,
                    localScreenHeight: localH > 0 ? localH : 2532,
                    displayName: "iPhone Viewer"
                )
                configuration.enableLANDirect = true

                let engine = UltraViewerRelaySession()
                self.session = engine

                let incoming = try await engine.connect(
                    configuration: configuration,
                    partnerID: cleanId,
                    password: cleanPwd
                )

                guard currentToken == token else {
                    await engine.close()
                    return
                }

                self.readTask = Task { [weak self] in
                    do {
                        for try await event in incoming {
                            guard let self, self.currentToken == token else { break }
                            switch event {
                            case let .status(msg):
                                self.statusMessage = msg
                                if case .connecting = self.state {
                                    self.state = .connecting(msg)
                                }
                            case let .accepted(peer):
                                self.remoteWidth = peer.width > 0 ? peer.width : 1920
                                self.remoteHeight = peer.height > 0 ? peer.height : 1080
                                self.partnerDisplayName = peer.displayName ?? "Windows PC"
                                self.allowsInput = peer.allowsRemoteInput
                                self.state = .connected
                                self.statusMessage = "Đã kết nối: \(self.partnerDisplayName)"
                            case let .frame(bitmap):
                                if let cgImage = bitmap.makeCGImage() {
                                    self.currentFrame = cgImage
                                    self.frameCount += 1
                                    if case .connecting = self.state {
                                        self.state = .connected
                                    }
                                }
                            case let .screenChanged(peer):
                                self.remoteWidth = peer.width > 0 ? peer.width : 1920
                                self.remoteHeight = peer.height > 0 ? peer.height : 1080
                                self.allowsInput = peer.allowsRemoteInput
                            case let .inputPermission(allowed):
                                self.allowsInput = allowed
                            default:
                                break
                            }
                        }
                        if self?.currentToken == token {
                            self?.state = .disconnected
                            self?.statusMessage = "Đã ngắt kết nối"
                        }
                    } catch {
                        if self?.currentToken == token {
                            self?.state = .failed(error.localizedDescription)
                            self?.statusMessage = "Lỗi: \(error.localizedDescription)"
                        }
                    }
                }
            } catch {
                if currentToken == token {
                    state = .failed(error.localizedDescription)
                    statusMessage = "Lỗi kết nối: \(error.localizedDescription)"
                }
            }
        }
    }

    public func refreshScreen() {
        guard let session, state == .connected else { return }
        Task {
            try? await session.refreshScreen()
        }
    }

    public func disconnect() {
        currentToken = UUID()
        readTask?.cancel()
        readTask = nil
        let oldSession = session
        session = nil
        Task {
            await oldSession?.close()
        }
        currentFrame = nil
        frameCount = 0
        state = .disconnected
        statusMessage = ""
    }

    public func sendMouseMove(normalizedX: CGFloat, normalizedY: CGFloat) {
        guard let session, state == .connected else { return }
        let clampedX = max(0, min(1, normalizedX))
        let clampedY = max(0, min(1, normalizedY))
        let targetX = Int32(clamping: Int(clampedX * CGFloat(remoteWidth)))
        let targetY = Int32(clamping: Int(clampedY * CGFloat(remoteHeight)))

        let msg = MouseMessage.move(wParam: 0, x: targetX, y: targetY)
        Task {
            try? await session.send(msg.encode())
        }
    }

    public func sendMouseClick(normalizedX: CGFloat, normalizedY: CGFloat, isRightClick: Bool = false) {
        guard let session, state == .connected else { return }
        let clampedX = max(0, min(1, normalizedX))
        let clampedY = max(0, min(1, normalizedY))
        let targetX = Int32(clamping: Int(clampedX * CGFloat(remoteWidth)))
        let targetY = Int32(clamping: Int(clampedY * CGFloat(remoteHeight)))
        let packed = MouseMessage.packedPosition(x: Int16(clamping: targetX), y: Int16(clamping: targetY))

        let moveMsg = MouseMessage.move(wParam: 0, x: targetX, y: targetY)
        let buttonDown: MouseMessage.Button = isRightClick ? .rightDown : .leftDown
        let buttonUp: MouseMessage.Button = isRightClick ? .rightUp : .leftUp
        let downMsg = MouseMessage.button(buttonDown, wParam: isRightClick ? 2 : 1, lParam: packed)
        let upMsg = MouseMessage.button(buttonUp, wParam: 0, lParam: packed)

        Task {
            try? await session.send(moveMsg.encode())
            try? await session.send(downMsg.encode())
            try? await Task.sleep(for: .milliseconds(40))
            try? await session.send(upMsg.encode())
        }
    }

    public func sendMouseScroll(deltaY: Int16) {
        guard let session, state == .connected else { return }
        let wheelMsg = MouseMessage.verticalWheel(
            wParam: MouseMessage.wheelWParam(delta: deltaY, keyFlags: 0),
            lParam: 0
        )
        Task {
            try? await session.send(wheelMsg.encode())
        }
    }

    public func sendKey(_ key: String) {
        guard let session, state == .connected else { return }
        let vk: UInt8
        let scan: UInt16
        switch key {
        case "Enter": vk = 0x0D; scan = 0x1C
        case "Esc": vk = 0x1B; scan = 0x01
        case "Tab": vk = 0x09; scan = 0x0F
        case "Win": vk = 0x5B; scan = 0x5B
        case "Del": vk = 0x2E; scan = 0x53
        case "↑": vk = 0x26; scan = 0x48
        case "↓": vk = 0x28; scan = 0x50
        case "←": vk = 0x25; scan = 0x4B
        case "→": vk = 0x27; scan = 0x4D
        default: return
        }

        let downMsg = KeyboardMessage(kind: .keyDown, virtualKey: vk, scanCode: scan, character: 0, capsLockOn: false)
        let upMsg = KeyboardMessage(kind: .keyUp, virtualKey: vk, scanCode: scan, character: 0, capsLockOn: false)
        Task {
            try? await session.send(downMsg.encode())
            try? await Task.sleep(for: .milliseconds(30))
            try? await session.send(upMsg.encode())
        }
    }
}
#endif
