import AppKit
import SwiftUI

@main
struct UtralviewApp: App {
    @StateObject private var model = ConnectionModel(adapter: NativeUtralviewAdapter())
    @StateObject private var hosting = MacHostingModel()
    @StateObject private var capture = RemoteCaptureController()
    @StateObject private var updater = UpdateChecker()
    @NSApplicationDelegateAdaptor(UtralviewAppDelegate.self) private var applicationDelegate
    @AppStorage(AppLanguage.defaultsKey) private var language = AppLanguage.system.rawValue

    var body: some Scene {
        WindowGroup("Utralview for Mac") {
            ConnectionView(model: model, hosting: hosting, remoteCapture: capture, updater: updater)
                .frame(minWidth: 780, minHeight: 520)
                .onAppear {
                    applicationDelegate.capture = capture
                    applicationDelegate.model = model
                    applicationDelegate.hosting = hosting
                    updater.startAutomaticChecks()
                }
                .appLanguage()
        }
        .defaultSize(width: 840, height: 560)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button(L("Check for Updates…")) { updater.check(userInitiated: true) }
            }
            CommandMenu(L("Connection")) {
                Button(L("Connect")) { model.connect() }
                    .keyboardShortcut("k", modifiers: [.command])
                    .disabled(!model.canConnect)
                Button(L("Disconnect")) { model.disconnect() }
                    .keyboardShortcut("d", modifiers: [.command, .shift])
                    .disabled(!model.isSessionActive)
            }
        }

        Settings {
            UtralviewSettings(model: model, updater: updater).appLanguage()
        }
    }
}

struct UtralviewSettings: View {
    private static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.2.2"
    @ObservedObject var model: ConnectionModel
    @ObservedObject var updater: UpdateChecker
    @AppStorage(ConnectionModel.rememberPartnersKey) private var rememberPartners = true
    @AppStorage("Utralview.smoothScreen") private var smoothScreen = true
    @AppStorage("Utralview.scrollSensitivity") private var scrollSensitivity = 1.0
    @AppStorage("Utralview.preferLANDirect") private var preferLANDirect = true
    @AppStorage(AppLanguage.defaultsKey) private var language = AppLanguage.system.rawValue
    @AppStorage(UpdateChecker.automaticKey) private var checkForUpdates = true
    @AppStorage(SessionToolsModel.shareClipboardKey) private var shareClipboard = true
    @AppStorage(SessionToolsModel.clipboardGuardKey) private var clipboardGuard = true

    var body: some View {
        Form {
            Section("Language") {
                Picker("App language", selection: $language) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(LocalizedStringKey(option.title)).tag(option.rawValue)
                    }
                }
                Text("Language changes apply immediately.").font(.caption).foregroundStyle(.secondary)
            }
            Section("History") {
                Toggle("Remember successfully connected partner IDs", isOn: $rememberPartners)
                    .onChange(of: rememberPartners) { _, enabled in
                        if !enabled { model.clearRecentPartners() }
                    }
                Text("Saved passwords are kept separately in macOS Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Clear Recent Partners") { model.clearRecentPartners() }
                    .disabled(model.recentPartners.isEmpty)
                Button("Forget saved passwords", action: model.forgetSavedPasswords)
            }
            Section("Network & Performance") {
                Toggle("Ưu tiên kết nối trực tiếp LAN P2P khi cùng mạng Wi-Fi", isOn: $preferLANDirect)
                Text("Tự động bỏ qua máy chủ trung gian khi đối tác ở cùng mạng nội bộ để đạt độ trễ cực thấp.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Clipboard & Security") {
                Toggle("Share clipboard with the other computer", isOn: $shareClipboard)
                Text("Text copied on either computer can be pasted on the other. Applies to new sessions.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Clipboard Guard (Bảo vệ thông tin nhạy cảm)", isOn: $clipboardGuard)
                Text("Cảnh báo và ngăn chặn chia sẻ tự động khi sao chép mật khẩu hoặc token cá nhân.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Remote screen") {
                Toggle("Smooth image scaling", isOn: $smoothScreen)
                Slider(value: $scrollSensitivity, in: 0.25...2, step: 0.25) {
                    Text("Scroll speed")
                }
                LabeledContent("Scroll speed", value: String(format: "%.2g×", scrollSensitivity))
            }
            Section("About") {
                LabeledContent("Application", value: "Utralview for Mac v\(Self.version)")
                LabeledContent("Developed by", value: "itngon.com")
                LabeledContent("Website", value: "https://itngon.com")
                Toggle("Automatically check for updates", isOn: $checkForUpdates)
                Button(L("Check for Updates…")) { updater.check(userInitiated: true) }
                    .disabled(updater.state == .checking)
                Text("An independent native Mac app for UltraViewer interoperability.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 600)
    }
}

typealias MacViewerApp = UtralviewApp
typealias MacViewerSettings = UtralviewSettings

@MainActor
final class UtralviewAppDelegate: NSObject, NSApplicationDelegate {
    weak var capture: RemoteCaptureController?
    weak var model: ConnectionModel?
    weak var hosting: MacHostingModel?
    private var isFinishing = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let url = Bundle.main.url(forResource: "MacViewer", withExtension: "icns"),
           let icon = NSImage(contentsOf: url) { NSApp.applicationIconImage = icon }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !isFinishing else { return .terminateLater }
        isFinishing = true
        Task {
            if let capture, capture.isRecording || capture.isFinishingRecording || capture.isPreparingRecording {
                await capture.stopRecording()
            }
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.closeConnections() }
                group.addTask { try? await Task.sleep(for: .seconds(2)) }
                await group.next()
                group.cancelAll()
            }
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    private func closeConnections() async {
        await model?.shutdown()
        await hosting?.shutdown()
    }
}

typealias MacViewerAppDelegate = UtralviewAppDelegate
