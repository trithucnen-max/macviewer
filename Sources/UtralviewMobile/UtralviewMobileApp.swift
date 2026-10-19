import SwiftUI

#if canImport(UIKit)
import UIKit

@main
public struct UtralviewMobileApp: App {
    @StateObject private var sessionManager = MobileSessionManager()
    @State private var activePartnerId: String = ""

    public init() {}

    public var body: some Scene {
        WindowGroup {
            Group {
                switch sessionManager.state {
                case .connected, .connecting:
                    MobileRemoteScreenView(
                        sessionManager: sessionManager,
                        partnerId: activePartnerId
                    )
                case .disconnected, .failed:
                    MobileConnectView(sessionManager: sessionManager, activePartnerId: $activePartnerId)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
#else
@main
public struct UtralviewMobilePlaceholderApp: App {
    public init() {}
    public var body: some Scene {
        WindowGroup {
            Text("Utralview Mobile (iOS)")
        }
    }
}
#endif
