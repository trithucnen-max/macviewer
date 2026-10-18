import SwiftUI

#if canImport(UIKit)
import UIKit

@main
public struct UtralviewMobileApp: App {
    @State private var activePartnerId: String?

    public init() {}

    public var body: some Scene {
        WindowGroup {
            if let partnerId = activePartnerId {
                MobileRemoteScreenView(
                    partnerId: partnerId,
                    onDisconnect: { activePartnerId = nil },
                    onSendMouse: { pos, button, isDown in
                        // Send mouse event via UltraViewerProtocol
                    },
                    onSendKey: { key in
                        // Send key event via UltraViewerProtocol
                    }
                )
            } else {
                MobileConnectView(
                    onConnect: { id, pwd in
                        activePartnerId = id
                    }
                )
            }
        }
    }
}
#endif
