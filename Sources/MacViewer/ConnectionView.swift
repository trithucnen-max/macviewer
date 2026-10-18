import AppKit
import SwiftUI
import UltraViewerProtocol

struct ConnectionView: View {
    @ObservedObject var model: ConnectionModel
    @ObservedObject var hosting: MacHostingModel
    @AppStorage("MacViewer.smoothScreen") private var smoothScreen = true
    @AppStorage("MacViewer.scrollSensitivity") private var scrollSensitivity = 1.0
    @ObservedObject var remoteCapture: RemoteCaptureController
    @ObservedObject var updater: UpdateChecker
    @State private var remoteDisplayScale: RemoteDisplayScale = .fit
    @State private var remoteImageQuality: RemoteImageQuality = .automatic
    @State private var showSession = false
    @State private var showSessionToolbar = true
    @State private var remoteWallpaperVisible = true
    @State private var revealPassword = false
    @State private var copiedID = false
    @State private var copiedPassword = false
    @FocusState private var focusedField: Field?
    @Environment(\.locale) private var appLocale
    @State private var confirmSideSwitch = false
    @State private var isSwitchingSides = false
    private enum Field { case partner, password }

    var body: some View {
        let _ = appLocale
        VStack(spacing: 0) {
            if showSession && model.isSessionActive {
                remoteSession
            } else {
                appHeader
                Divider().overlay(MacTheme.cardBorder)
                dashboard
            }
        }
        .background(MacTheme.baseBackground)
        .sheet(isPresented: Binding(get: { hosting.pendingRequest != nil }, set: { if !$0 { hosting.decline() } })) {
            IncomingMacConnectionView(hosting: hosting)
        }
        .onAppear {
            focusedField = .partner
            hosting.onApprovedSideSwitch = { id, password in
                model.disconnect()
                model.partnerID = id
                model.password = password
                model.connect()
                showSession = true
            }
        }
        .confirmationDialog("Switch control sides?", isPresented: $confirmSideSwitch, titleVisibility: .visible) {
            Button("Let Windows connect to this Mac") { requestSideSwitch() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("MacViewer will share this Mac’s connection ID and password with the connected Windows computer. You will approve its incoming request here.")
        }
        .confirmationDialog("Windows requests a control switch", isPresented: Binding(
            get: { hosting.pendingSideSwitch != nil },
            set: { if !$0 { hosting.declineSideSwitch() } }), titleVisibility: .visible) {
                Button("Connect to Windows", action: hosting.approveSideSwitch)
                Button("Decline", role: .cancel, action: hosting.declineSideSwitch)
            } message: {
                Text("End this incoming session and connect to the same Windows computer? Control will stay off until you enable it.")
            }
        .onDisappear { remoteCapture.endSession(); model.disconnect(); hosting.stop() }
        .onChange(of: hosting.identifier) { _, id in if id == nil { revealPassword = false } }
        .onChange(of: model.phase) { _, phase in
            if phase == .connecting || phase == .connected { showSession = true }
            if phase == .disconnected || phase == .idle { remoteCapture.endSession() }
        }
        .onChange(of: model.displayedFrame?.id) { _, _ in
            if let image = model.displayedFrame?.image { remoteCapture.recordFrame(image) }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            hosting.refreshPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            model.releaseRemoteInput()
            revealPassword = false
        }
        .alert(updateAlertTitle, isPresented: $updater.showResult) {
            Button("OK", role: .cancel) {}
        } message: {
            if case let .failed(message) = updater.state { Text(message) }
            else { Text("You have the latest version, \(updater.currentVersion).") }
        }
        .background(EmptyView().sheet(isPresented: $updater.showSheet) {
            UpdateSheet(updater: updater, endsConnections: model.isSessionActive || hosting.viewer != nil)
                .appLanguage()
        })
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            model.disconnect(); hosting.stop()
        }
    }

    private func updateButton(_ release: UpdateChecker.Release) -> some View {
        Button { updater.showSheet = true } label: {
            Label("Update to \(release.version)", systemImage: "arrow.down.circle.fill")
        }
        .buttonStyle(.borderedProminent)
        .tint(MacTheme.accent)
        .controlSize(.small)
        .help("Install the new version and restart MacViewer")
    }

    private var updateAlertTitle: LocalizedStringKey {
        if case .failed = updater.state { "Update failed" } else { "MacViewer is up to date" }
    }

    private var appHeader: some View {
        HStack(spacing: 12) {
            // Clean Logo Icon with solid Electric Cobalt background
            Image(systemName: "display.2")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(MacTheme.accent, in: RoundedRectangle(cornerRadius: MacTheme.radiusControl))

            VStack(alignment: .leading, spacing: 1) {
                Text("MacViewer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MacTheme.textPrimary)
                Text("Works with UltraViewer on Windows")
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.textSecondary)
            }

            Spacer()

            if hosting.phase == .sharing {
                Menu {
                    Text("Viewing: \(hosting.viewer?.displayName ?? "Windows computer")")
                    Toggle("Allow control of this Mac", isOn: incomingControlBinding)
                        .disabled(incomingControlDisabled)
                    if !hosting.permissions.accessibility {
                        Button("Enable Accessibility…", action: hosting.requestAccessibility)
                    }
                    Divider()
                    Button("End incoming session", role: .destructive, action: hosting.endViewer)
                        .disabled(hosting.isEndingViewer)
                    Button("Pause incoming access", action: hosting.stop)
                } label: {
                    HStack(spacing: 6) {
                        Circle().fill(MacTheme.signal).frame(width: 7, height: 7)
                        Text(LocalizedStringKey(hosting.isEndingViewer ? "Ending incoming session…" : "Mac screen shared"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(MacTheme.signal)
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Manage Windows access to this Mac")

                SessionToolsButton(tools: hosting.tools, peerName: incomingPeerName,
                                   title: "Incoming chat", context: "Incoming", onOpen: model.releaseRemoteInput)
                    .controlSize(.small)
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(hosting.isRunning ? MacTheme.signal : MacTheme.textSecondary)
                        .frame(width: 6, height: 6)
                    Text(LocalizedStringKey(hosting.isRunning ? "Ready for connections" : "Incoming access paused"))
                        .font(.system(size: 12))
                        .foregroundStyle(MacTheme.textSecondary)
                }
            }

            if let release = updater.availableRelease {
                updateButton(release)
            }

            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(MacTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Settings")
            .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(MacTheme.baseBackground)
    }

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Value Proposition
                VStack(alignment: .leading, spacing: 4) {
                    Text("Remote Desktop")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(MacTheme.textPrimary)
                    Text("Fast, secure remote control between Mac and Windows computers.")
                        .font(.system(size: 13))
                        .foregroundStyle(MacTheme.textSecondary)
                }
                .padding(.top, 4)

                // 2-Column Balanced Cards (Hick's Law)
                HStack(alignment: .top, spacing: 16) {
                    partnerCard
                    hostingCard
                }
                .fixedSize(horizontal: false, vertical: true)

                if !model.recentPartners.isEmpty {
                    recentPartners
                }
            }
            .frame(maxWidth: 880)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
        .clipped()
    }

    // Card 1: Remote Control (Mac -> Windows)
    private var partnerCard: some View {
        utilityPanel(title: "Control Remote Computer", direction: "MAC → WINDOWS", symbol: "display") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Partner ID")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MacTheme.textPrimary)

                    if model.isSessionActive {
                        Text(formattedID(model.remoteInfo?.partnerID ?? model.partnerID.filter { $0.isNumber }))
                            .font(.system(size: 19, weight: .semibold, design: .monospaced))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                    } else {
                        TextField("e.g. 12 345 678", text: $model.partnerID)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.large)
                            .focused($focusedField, equals: .partner)
                            .onSubmit { focusedField = .password }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Partner Password")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MacTheme.textPrimary)

                    if model.isSessionActive {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 12))
                                .foregroundStyle(MacTheme.signal)
                            Text("Session Authenticated")
                                .font(.system(size: 13))
                                .foregroundStyle(MacTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                    } else {
                        SecureField("Password from remote PC", text: $model.password)
                            .font(.system(size: 14))
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.large)
                            .focused($focusedField, equals: .password)
                            .onSubmit { if model.canConnect { model.connect() } }
                    }
                }

                if !model.isSessionActive {
                    Toggle("Save credentials securely in Keychain", isOn: Binding(
                        get: { model.rememberPassword }, set: { model.setRememberPassword($0) }))
                        .toggleStyle(.checkbox)
                        .font(.system(size: 12))
                        .foregroundStyle(MacTheme.textSecondary)
                }

                if model.isSessionActive {
                    HStack(spacing: 10) {
                        Circle().fill(MacTheme.signal).frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(model.phase == .connected ? "Windows is connected" : "Connecting…"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(MacTheme.textPrimary)
                            Text(L(model.status))
                                .font(.system(size: 11))
                                .foregroundStyle(MacTheme.textSecondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(MacTheme.surfaceSubtle, in: RoundedRectangle(cornerRadius: MacTheme.radiusControl))
                }

                if let error = model.errorMessage {
                    errorLabel(error)
                }

                Spacer(minLength: 8)
            }
        } actions: {
            VStack(alignment: .leading, spacing: 8) {
                if model.isSessionActive {
                    HStack(spacing: 10) {
                        Button { showSession = true } label: {
                            Label("Open Window", systemImage: "arrow.up.right.square")
                                .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(MacTheme.accent)

                        Button("Disconnect", role: .destructive, action: model.disconnect)
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                    }
                } else {
                    Button(action: model.connect) {
                        Label("Connect to Partner", systemImage: "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 34)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MacTheme.accent)
                    .disabled(!model.canConnect)
                }

                Text("Remote desktop control will start immediately after connection.")
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // Card 2: Share this Mac (Windows -> Mac)
    private var hostingCard: some View {
        utilityPanel(title: "Allow Remote Access", direction: "WINDOWS → MAC", symbol: "laptopcomputer") {
            VStack(alignment: .leading, spacing: 14) {
                if hosting.identifier != nil {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Connection ID")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(MacTheme.textPrimary)

                        HStack(spacing: 8) {
                            if let id = hosting.identifier {
                                Text(formattedID(id))
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .foregroundStyle(MacTheme.textPrimary)
                                    .textSelection(.enabled)

                                Spacer(minLength: 0)

                                Button {
                                    copy(id)
                                    copiedID = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedID = false }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: copiedID ? "checkmark" : "doc.on.doc")
                                        if copiedID {
                                            Text("Copied").font(.system(size: 11))
                                        }
                                    }
                                    .font(.system(size: 12))
                                    .foregroundStyle(copiedID ? MacTheme.signal : MacTheme.accent)
                                }
                                .buttonStyle(.borderless)
                                .help("Copy connection ID")
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Password")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(MacTheme.textPrimary)

                        HStack(spacing: 8) {
                            Text(revealPassword ? hosting.password : "••••••••")
                                .font(.system(size: 17, weight: .medium, design: .monospaced))
                                .foregroundStyle(MacTheme.textPrimary)

                            Spacer()

                            Button { revealPassword.toggle() } label: {
                                Image(systemName: revealPassword ? "eye.slash" : "eye")
                                    .font(.system(size: 12))
                                    .foregroundStyle(MacTheme.textSecondary)
                            }
                            .buttonStyle(.borderless)
                            .help(revealPassword ? "Hide password" : "Show password")

                            Button {
                                copy(hosting.password)
                                copiedPassword = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedPassword = false }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedPassword ? "checkmark" : "doc.on.doc")
                                    if copiedPassword {
                                        Text("Copied").font(.system(size: 11))
                                    }
                                }
                                .font(.system(size: 12))
                                .foregroundStyle(copiedPassword ? MacTheme.signal : MacTheme.accent)
                            }
                            .buttonStyle(.borderless)
                            .help("Copy password")
                        }
                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                    }
                } else {
                    HStack(spacing: 8) {
                        if hosting.phase == .registering {
                            ProgressView().controlSize(.small)
                        }
                        Text(LocalizedStringKey(hosting.phase == .registering ? "Registering session ID…" : "Start sharing to generate an ID."))
                            .font(.system(size: 13))
                            .foregroundStyle(MacTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                }

                // Permissions Section
                permissionRows

                if let error = hosting.errorMessage {
                    errorLabel(error)
                }

                Spacer(minLength: 0)
            }
        } actions: {
            VStack(alignment: .leading, spacing: 8) {
                if hosting.phase == .sharing {
                    HStack(spacing: 10) {
                        SessionToolsButton(tools: hosting.tools, peerName: incomingPeerName, context: "Incoming")
                            .buttonStyle(.bordered)
                        Button("End Session", role: .destructive, action: hosting.endViewer)
                            .buttonStyle(.bordered)
                            .disabled(hosting.isEndingViewer)
                        Spacer(minLength: 0)
                    }
                } else if hosting.isRunning {
                    Button(action: hosting.stop) {
                        Label("Pause Access", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity, minHeight: 34)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(action: hosting.start) {
                        Label(LocalizedStringKey(hosting.phase == .failed ? "Try Sharing Again" : "Start Sharing This Mac"),
                              systemImage: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 34)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MacTheme.accent)
                }

                Text("Anyone with this ID and password can request access to your screen.")
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // Modern 3-Color Card Panel Component
    private func utilityPanel<Content: View, Actions: View>(
        title: String,
        direction: String,
        symbol: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Header
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MacTheme.accent)
                    .frame(width: 32, height: 32)
                    .background(MacTheme.accentSubtle, in: RoundedRectangle(cornerRadius: MacTheme.radiusControl))

                VStack(alignment: .leading, spacing: 2) {
                    Text(direction)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(MacTheme.textSecondary)
                    Text(LocalizedStringKey(title))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MacTheme.textPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().overlay(MacTheme.cardBorder)

            // Card Body
            content()
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Divider().overlay(MacTheme.cardBorder)

            // Card Action Area
            actions()
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
                .background(MacTheme.surfaceSubtle)
        }
        .frame(maxWidth: .infinity, minHeight: 410, maxHeight: .infinity, alignment: .topLeading)
        .background(MacTheme.cardBackground, in: RoundedRectangle(cornerRadius: MacTheme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: MacTheme.radiusCard).strokeBorder(MacTheme.cardBorder))
        .clipShape(RoundedRectangle(cornerRadius: MacTheme.radiusCard))
    }

    private var incomingControlBinding: Binding<Bool> {
        Binding(get: { hosting.allowsControl }, set: { hosting.setControlAllowed($0) })
    }

    private var incomingPeerName: String {
        hosting.viewer?.displayName ?? hosting.viewer?.viewerID ?? "Windows computer"
    }

    private var incomingControlDisabled: Bool {
        hosting.isUpdatingControl || hosting.isEndingViewer || (!hosting.canControl && !hosting.allowsControl)
    }

    // Permission Rows with Sage Emerald
    private var permissionRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            if hosting.canControl {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(MacTheme.signal)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("System Permissions Ready")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(MacTheme.textPrimary)
                        Text("Screen recording and control are active.")
                            .font(.system(size: 11))
                            .foregroundStyle(MacTheme.textSecondary)
                    }
                    Spacer()
                    Button("Manage") {
                        MacPermissionsSetupWindowController.shared.show(hosting: hosting, initialPermission: .screenRecording)
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.accent)
                }
            } else {
                HStack {
                    Text("Required Permissions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MacTheme.textPrimary)
                    Spacer()
                    Button("Set Up…") {
                        MacPermissionsSetupWindowController.shared.show(hosting: hosting,
                            initialPermission: hosting.permissions.screenRecording ? .accessibility : .screenRecording)
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.accent)
                }

                permissionSummary("Screen Recording", allowed: hosting.permissions.screenRecording)
                permissionSummary("Accessibility", allowed: hosting.permissions.accessibility)
            }
        }
        .padding(10)
        .background(MacTheme.surfaceSubtle, in: RoundedRectangle(cornerRadius: MacTheme.radiusControl))
        .overlay(RoundedRectangle(cornerRadius: MacTheme.radiusControl).strokeBorder(MacTheme.cardBorder))
    }

    private func permissionSummary(_ title: String, allowed: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: allowed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundStyle(allowed ? MacTheme.signal : MacTheme.textSecondary)
            Text(LocalizedStringKey(title))
                .font(.system(size: 12))
                .foregroundStyle(MacTheme.textPrimary)
            Spacer()
            Text(LocalizedStringKey(allowed ? "Granted" : "Required"))
                .font(.system(size: 11))
                .foregroundStyle(allowed ? MacTheme.signal : MacTheme.textSecondary)
        }
    }

    // Recent Partners History
    private var recentPartners: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recent Connections")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MacTheme.textPrimary)
                Spacer()
                Button("Clear History", action: model.clearRecentPartners)
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.textSecondary)
            }

            VStack(spacing: 0) {
                ForEach(model.recentPartners, id: \.self) { id in
                    Button {
                        model.selectRecent(id)
                        focusedField = .password
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "pc")
                                .font(.system(size: 14))
                                .foregroundStyle(MacTheme.accent)
                                .frame(width: 30, height: 30)
                                .background(MacTheme.accentSubtle, in: RoundedRectangle(cornerRadius: MacTheme.radiusBadge))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(formattedID(id))
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundStyle(MacTheme.textPrimary)
                                Text("Windows Remote PC")
                                    .font(.system(size: 11))
                                    .foregroundStyle(MacTheme.textSecondary)
                            }
                            Spacer()
                            Text("Connect")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(MacTheme.accent)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundStyle(MacTheme.textSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(model.isSessionActive)

                    if id != model.recentPartners.last {
                        Divider().overlay(MacTheme.cardBorder).padding(.leading, 56)
                    }
                }
            }
            .background(MacTheme.cardBackground, in: RoundedRectangle(cornerRadius: MacTheme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: MacTheme.radiusCard).strokeBorder(MacTheme.cardBorder))
            .clipShape(RoundedRectangle(cornerRadius: MacTheme.radiusCard))
        }
    }

    private var remoteSession: some View {
        VStack(spacing: 0) {
            if showSessionToolbar {
                RemoteSessionToolbar(
                    peerName: model.remoteInfo?.displayName ?? model.partnerID,
                    isConnected: model.phase == .connected,
                    allowsControl: model.remoteInfo?.allowsRemoteInput == true,
                    controlEnabled: Binding(get: { model.controlEnabled }, set: { model.setControlEnabled($0) }),
                    displayScale: $remoteDisplayScale, smoothScaling: $smoothScreen, imageQuality: $remoteImageQuality,
                    tools: model.tools, capture: remoteCapture, image: model.displayedFrame?.image,
                    callbacks: .init(home: { model.releaseRemoteInput(); showSession = false },
                                     disconnect: model.disconnect, releaseInput: model.releaseRemoteInput,
                                     secureAttention: { model.performRemoteAction(.controlAltDelete) },
                                     lockScreen: { model.performRemoteAction(.lockScreen) },
                                     restart: { model.performRemoteAction(.restart) },
                                     setImageQuality: model.setImageQuality,
                                     hideToolbar: { model.releaseRemoteInput(); showSessionToolbar = false },
                                     monitors: model.remoteInfo?.monitors ?? [],
                                     selectedMonitor: model.selectedMonitor,
                                     selectMonitor: model.selectMonitor,
                                     wallpaperVisible: remoteWallpaperVisible,
                                     setWallpaper: { remoteWallpaperVisible = $0; model.setWallpaperVisible($0) },
                                     setCustomImageQuality: model.setCustomImageQuality,
                                     computerAudioEnabled: model.computerAudioEnabled,
                                     isChangingAudio: model.isChangingAudio,
                                     setComputerAudioEnabled: model.setComputerAudioEnabled,
                                     showRemoteCursor: model.showRemoteCursor,
                                     setShowRemoteCursor: model.setShowRemoteCursor))
                Divider().overlay(MacTheme.cardBorder)
            }

            if let error = model.errorMessage {
                errorLabel(error).padding(16)
            }

            if let frame = model.displayedFrame, model.phase == .connected {
                RemoteScreenViewport(image: frame.image, displayScale: remoteDisplayScale, smoothScaling: smoothScreen,
                                     scrollSensitivity: scrollSensitivity, inputEnabled: model.controlEnabled,
                                     onInput: model.send, cursor: model.remoteCursor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    ProgressView().controlSize(.large)
                    Text(L(model.status))
                        .foregroundStyle(MacTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Bottom Status Bar
            HStack(spacing: 12) {
                if !showSessionToolbar {
                    Button { showSessionToolbar = true } label: { Label("Show toolbar", systemImage: "chevron.down") }
                        .buttonStyle(.borderless)
                }
                Circle()
                    .fill(model.phase == .connected ? MacTheme.signal : MacTheme.textSecondary)
                    .frame(width: 7, height: 7)
                Text(L(model.status)).lineLimit(1)
                Spacer()
                if let frame = model.frame {
                    Text("\(frame.image.width) × \(frame.image.height)").monospacedDigit()
                }
                Text(LocalizedStringKey(model.controlEnabled ? "Control Enabled" : "View Only"))
            }
            .font(.system(size: 11))
            .foregroundStyle(MacTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(MacTheme.baseBackground)
        }
    }

    private func formattedID(_ id: String) -> String {
        stride(from: 0, to: id.count, by: 3).map { offset in
            let start = id.index(id.startIndex, offsetBy: offset)
            return String(id[start..<id.index(start, offsetBy: min(3, id.count - offset))])
        }.joined(separator: " ")
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private func errorLabel(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 12))
            Text(L(text))
                .font(.system(size: 12))
        }
        .foregroundStyle(MacTheme.textPrimary)
        .padding(8)
        .background(MacTheme.surfaceSubtle, in: RoundedRectangle(cornerRadius: MacTheme.radiusControl))
    }

    private func requestSideSwitch() {
        guard model.phase == .connected, !isSwitchingSides else { return }
        isSwitchingSides = true
        let peerID = model.remoteInfo?.partnerID
        if !hosting.isRunning { hosting.start() }
        Task { @MainActor in
            defer { isSwitchingSides = false }
            for _ in 0..<120 {
                guard model.phase == .connected, model.remoteInfo?.partnerID == peerID else { return }
                if let id = hosting.identifier, !hosting.password.isEmpty {
                    if let message = try? UltraViewerProtocol.RemoteControlCommands.sideSwitch(ownID: id, password: hosting.password) {
                        model.sendCommands([message], requiresControl: false)
                    }
                    return
                }
                if hosting.phase == .failed { return }
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }
}

private struct IncomingMacConnectionView: View {
    @ObservedObject var hosting: MacHostingModel
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(MacTheme.accent)
            Text("Incoming Connection Request")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MacTheme.textPrimary)

            if let request = hosting.pendingRequest {
                Text("\(request.displayName ?? L("Another computer")) wants to access this Mac.")
                    .font(.system(size: 13))
                Text("Partner ID: \(request.viewerID)")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(MacTheme.textSecondary)
            }
            Text("Allow viewing to share your screen. Allowing control will grant access to your mouse and keyboard.")
                .font(.system(size: 12))
                .foregroundStyle(MacTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !hosting.canView {
                Button("Set up Screen Recording…") {
                    MacPermissionsSetupWindowController.shared.show(hosting: hosting, initialPermission: .screenRecording)
                }
                .buttonStyle(.bordered)
            }
            if !hosting.permissions.accessibility {
                Button("Set up Accessibility…") {
                    MacPermissionsSetupWindowController.shared.show(hosting: hosting, initialPermission: .accessibility)
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Button("Decline", role: .cancel, action: hosting.decline)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                if hosting.isApproving { ProgressView().controlSize(.small) }
                Button("Allow Viewing") { hosting.approve(control: false) }
                    .buttonStyle(.bordered)
                    .disabled(!hosting.canView || hosting.isApproving)
                Button("Allow Control") { hosting.approve(control: true) }
                    .buttonStyle(.borderedProminent)
                    .tint(MacTheme.accent)
                    .disabled(!hosting.canControl || hosting.isApproving)
            }
        }
        .padding(28)
        .frame(width: 480)
        .background(MacTheme.baseBackground)
        .interactiveDismissDisabled(hosting.isApproving)
    }
}
