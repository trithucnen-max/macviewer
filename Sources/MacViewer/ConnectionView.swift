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
            Text("Utralview will share this Mac’s connection ID and password with the connected Windows computer. You will approve its incoming request here.")
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
        .help("Install the new version and restart Utralview for Mac")
    }

    private var updateAlertTitle: LocalizedStringKey {
        if case .failed = updater.state { "Update failed" } else { "Utralview for Mac is up to date" }
    }

    private var appHeader: some View {
        HStack(spacing: 12) {
            // App Icon with Electric Cobalt background
            Image(systemName: "display.2")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(MacTheme.accent, in: RoundedRectangle(cornerRadius: MacTheme.radiusControl))

            VStack(alignment: .leading, spacing: 1) {
                Text("Utralview for Mac")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MacTheme.textPrimary)
                Text("Bảo mật & Tốc độ cao • Tương thích UltraViewer")
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
                    Text(LocalizedStringKey(hosting.isRunning ? "Sẵn sàng nhận kết nối" : "Đã tạm dừng truy cập"))
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
            .help("Cài đặt")
            .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(MacTheme.baseBackground)
    }

    private var dashboard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Left Panel: Máy của bạn (Allow Remote Access)
                hostingSidebar
                    .frame(width: 320)

                Divider().overlay(MacTheme.cardBorder)

                // Right Panel: Điều khiển máy từ xa (Control Remote Computer) + Gần đây
                partnerWorkspace
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider().overlay(MacTheme.cardBorder)

            // Bottom Native Status Bar
            statusBar
        }
    }

    // Left Column: Native macOS Sidebar
    private var hostingSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Machine Profile Header
                HStack(spacing: 10) {
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(MacTheme.accent)
                        .frame(width: 32, height: 32)
                        .background(MacTheme.accentSubtle, in: Circle())

                    VStack(alignment: .leading, spacing: 1) {
                        Text(Host.current().localizedName ?? "Máy Mac của bạn")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(MacTheme.textPrimary)
                            .lineLimit(1)
                        HStack(spacing: 5) {
                            Circle().fill(hosting.isRunning ? MacTheme.signal : MacTheme.textSecondary).frame(width: 6, height: 6)
                            Text(LocalizedStringKey(hosting.isRunning ? "Sẵn sàng nhận kết nối" : "Đã tạm dừng chia sẻ"))
                                .font(.system(size: 11))
                                .foregroundStyle(MacTheme.textSecondary)
                        }
                    }
                }
                .padding(.bottom, 2)

                // Your Credentials Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHO PHÉP TRUY CẬP MÁY MAC")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(MacTheme.textSecondary)

                    VStack(spacing: 0) {
                        // Your Connection ID
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ID của bạn")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(MacTheme.textSecondary)

                            HStack(spacing: 8) {
                                if let id = hosting.identifier {
                                    Text(formattedID(id))
                                        .font(.system(size: 20, weight: .bold, design: .monospaced))
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
                                            Text(copiedID ? "Đã chép" : "Sao chép")
                                                .font(.system(size: 11, weight: .medium))
                                        }
                                        .font(.system(size: 11))
                                        .foregroundStyle(copiedID ? MacTheme.signal : MacTheme.accent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(MacTheme.accentSubtle, in: RoundedRectangle(cornerRadius: MacTheme.radiusControl))
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    HStack(spacing: 6) {
                                        if hosting.phase == .registering {
                                            ProgressView().controlSize(.small)
                                        }
                                        Text(LocalizedStringKey(hosting.phase == .registering ? "Đang tạo mã kết nối…" : "Bấm nút dưới để tạo ID"))
                                            .font(.system(size: 12))
                                            .foregroundStyle(MacTheme.textSecondary)
                                    }
                                    .frame(minHeight: 28)
                                }
                            }
                        }
                        .padding(12)

                        Divider().overlay(MacTheme.cardBorder)

                        // Your Password
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mật khẩu")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(MacTheme.textSecondary)

                            HStack(spacing: 8) {
                                if hosting.identifier != nil {
                                    Text(revealPassword ? hosting.password : "••••••••")
                                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(MacTheme.textPrimary)

                                    Spacer()

                                    Button { revealPassword.toggle() } label: {
                                        Image(systemName: revealPassword ? "eye.slash" : "eye")
                                            .font(.system(size: 12))
                                            .foregroundStyle(MacTheme.textSecondary)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        copy(hosting.password)
                                        copiedPassword = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedPassword = false }
                                    } label: {
                                        Image(systemName: copiedPassword ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 12))
                                            .foregroundStyle(copiedPassword ? MacTheme.signal : MacTheme.accent)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Text("••••••••")
                                        .font(.system(size: 15, design: .monospaced))
                                        .foregroundStyle(MacTheme.textSecondary.opacity(0.5))
                                }
                            }
                        }
                        .padding(12)
                    }
                    .background(MacTheme.cardBackground, in: RoundedRectangle(cornerRadius: MacTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: MacTheme.radiusCard).strokeBorder(MacTheme.cardBorder))
                }

                // System Permissions Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("QUYỀN TRUY CẬP HỆ THỐNG")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(MacTheme.textSecondary)

                    permissionRows
                }

                // Sharing Action Button
                VStack(spacing: 6) {
                    if hosting.phase == .sharing {
                        HStack(spacing: 8) {
                            SessionToolsButton(tools: hosting.tools, peerName: incomingPeerName, context: "Incoming")
                                .buttonStyle(.bordered)
                            Button("Kết thúc", role: .destructive, action: hosting.endViewer)
                                .buttonStyle(.bordered)
                                .disabled(hosting.isEndingViewer)
                        }
                    } else if hosting.isRunning {
                        Button(action: hosting.stop) {
                            Label("Tạm dừng chia sẻ", systemImage: "pause.fill")
                                .font(.system(size: 12, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 30)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button(action: hosting.start) {
                            Label(LocalizedStringKey(hosting.phase == .failed ? "Thử chia sẻ lại" : "Bắt đầu chia sẻ máy Mac"),
                                  systemImage: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(MacTheme.accent)
                    }

                    Text("Người có ID và mật khẩu này có thể yêu cầu xem hoặc điều khiển máy Mac.")
                        .font(.system(size: 10))
                        .foregroundStyle(MacTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .background(MacTheme.surfaceSubtle)
    }

    // Right Column: Partner Workspace
    private var partnerWorkspace: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Control Remote Computer Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "display")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MacTheme.accent)
                        Text("ĐIỀU KHIỂN MÁY TÍNH TỪ XA")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(MacTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        // Partner ID Row
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ID đối tác (Partner ID)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(MacTheme.textPrimary)

                            if model.isSessionActive {
                                Text(formattedID(model.remoteInfo?.partnerID ?? model.partnerID.filter { $0.isNumber }))
                                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                            } else {
                                TextField("Ví dụ: 12 345 678", text: $model.partnerID)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .textFieldStyle(.roundedBorder)
                                    .controlSize(.regular)
                                    .focused($focusedField, equals: .partner)
                                    .onSubmit { focusedField = .password }
                            }
                        }

                        // Partner Password Row
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mật khẩu đối tác")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(MacTheme.textPrimary)

                            if model.isSessionActive {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(MacTheme.signal)
                                    Text("Phiên làm việc đã xác thực")
                                        .font(.system(size: 12))
                                        .foregroundStyle(MacTheme.textSecondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                            } else {
                                SecureField("Nhập mật khẩu máy từ xa", text: $model.password)
                                    .font(.system(size: 13))
                                    .textFieldStyle(.roundedBorder)
                                    .controlSize(.regular)
                                    .focused($focusedField, equals: .password)
                                    .onSubmit { if model.canConnect { model.connect() } }
                            }
                        }

                        if !model.isSessionActive {
                            Toggle("Lưu mật khẩu an toàn vào Keychain của macOS", isOn: Binding(
                                get: { model.rememberPassword }, set: { model.setRememberPassword($0) }))
                                .toggleStyle(.checkbox)
                                .font(.system(size: 11))
                                .foregroundStyle(MacTheme.textSecondary)
                        }

                        if let error = model.errorMessage {
                            errorLabel(error)
                        }

                        // Action Button
                        if model.isSessionActive {
                            HStack(spacing: 10) {
                                Button { showSession = true } label: {
                                    Label("Mở cửa sổ màn hình", systemImage: "arrow.up.right.square")
                                        .font(.system(size: 12, weight: .semibold))
                                        .frame(maxWidth: .infinity, minHeight: 32)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(MacTheme.accent)

                                Button("Ngắt kết nối", role: .destructive, action: model.disconnect)
                                    .buttonStyle(.bordered)
                                    .controlSize(.regular)
                            }
                        } else {
                            Button(action: model.connect) {
                                Label("Kết nối đến đối tác", systemImage: "arrow.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity, minHeight: 34)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(MacTheme.accent)
                            .disabled(!model.canConnect)
                        }
                    }
                    .padding(14)
                    .background(MacTheme.cardBackground, in: RoundedRectangle(cornerRadius: MacTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: MacTheme.radiusCard).strokeBorder(MacTheme.cardBorder))
                }

                // Section 2: Recent Connections
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12))
                            .foregroundStyle(MacTheme.accent)
                        Text("THIẾT BỊ ĐÃ KẾT NỐI GẦN ĐÂY")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(MacTheme.textSecondary)
                        Spacer()
                        if !model.recentPartners.isEmpty {
                            Button("Xoá lịch sử", action: model.clearRecentPartners)
                                .buttonStyle(.plain)
                                .font(.system(size: 11))
                                .foregroundStyle(MacTheme.textSecondary)
                        }
                    }

                    if !model.recentPartners.isEmpty {
                        recentPartnersList
                    } else {
                        recentEmptyState
                    }
                }
            }
            .padding(16)
        }
    }

    // Recent Empty State
    private var recentEmptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 22))
                .foregroundStyle(MacTheme.textSecondary.opacity(0.4))
                .frame(width: 36, height: 36)
                .background(MacTheme.surfaceSubtle, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Chưa có thiết bị lưu gần đây")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MacTheme.textPrimary)
                Text("Các máy tính sau khi kết nối sẽ tự động lưu lại tại đây để bạn truy cập nhanh lần sau.")
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(MacTheme.cardBackground, in: RoundedRectangle(cornerRadius: MacTheme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: MacTheme.radiusCard).strokeBorder(MacTheme.cardBorder))
    }

    // Recent Partners List
    private var recentPartnersList: some View {
        VStack(spacing: 0) {
            ForEach(model.recentPartners, id: \.self) { id in
                Button {
                    model.selectRecent(id)
                    focusedField = .password
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "pc")
                            .font(.system(size: 13))
                            .foregroundStyle(MacTheme.accent)
                            .frame(width: 26, height: 26)
                            .background(MacTheme.accentSubtle, in: RoundedRectangle(cornerRadius: MacTheme.radiusBadge))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(formattedID(id))
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(MacTheme.textPrimary)
                            Text("Windows Remote PC")
                                .font(.system(size: 10))
                                .foregroundStyle(MacTheme.textSecondary)
                        }
                        Spacer()
                        Text("Kết nối")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(MacTheme.accent)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundStyle(MacTheme.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(model.isSessionActive)

                if id != model.recentPartners.last {
                    Divider().overlay(MacTheme.cardBorder).padding(.leading, 46)
                }
            }
        }
        .background(MacTheme.cardBackground, in: RoundedRectangle(cornerRadius: MacTheme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: MacTheme.radiusCard).strokeBorder(MacTheme.cardBorder))
        .clipShape(RoundedRectangle(cornerRadius: MacTheme.radiusCard))
    }

    // Bottom Status Bar
    private var statusBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 5) {
                Circle().fill(MacTheme.signal).frame(width: 6, height: 6)
                Text("Máy chủ UltraViewer: Trực tuyến")
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.textSecondary)
            }

            HStack(spacing: 4) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.signal)
                Text("Mã hoá AES-128 & 3DES")
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.textSecondary)
            }

            Spacer()

            Text("Utralview for Mac v2.1.1 • BasanCorp")
                .font(.system(size: 11))
                .foregroundStyle(MacTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(MacTheme.surfaceSubtle)
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

    // Permission Rows
    private var permissionRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            if hosting.canControl {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(MacTheme.signal)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Quyền hệ thống đã đầy đủ")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(MacTheme.textPrimary)
                        Text("Đã cấp quyền ghi màn hình và điều khiển.")
                            .font(.system(size: 10))
                            .foregroundStyle(MacTheme.textSecondary)
                    }
                    Spacer()
                    Button("Cài đặt") {
                        MacPermissionsSetupWindowController.shared.show(hosting: hosting, initialPermission: .screenRecording)
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.accent)
                }
            } else {
                HStack {
                    Text("Yêu cầu quyền truy cập")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MacTheme.textPrimary)
                    Spacer()
                    Button("Thiết lập…") {
                        MacPermissionsSetupWindowController.shared.show(hosting: hosting,
                            initialPermission: hosting.permissions.screenRecording ? .accessibility : .screenRecording)
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.accent)
                }

                permissionSummary("Ghi màn hình", allowed: hosting.permissions.screenRecording)
                permissionSummary("Trợ năng (Chuột/Phím)", allowed: hosting.permissions.accessibility)
            }
        }
        .padding(10)
        .background(MacTheme.cardBackground, in: RoundedRectangle(cornerRadius: MacTheme.radiusControl))
        .overlay(RoundedRectangle(cornerRadius: MacTheme.radiusControl).strokeBorder(MacTheme.cardBorder))
    }

    private func permissionSummary(_ title: String, allowed: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: allowed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 11))
                .foregroundStyle(allowed ? MacTheme.signal : MacTheme.textSecondary)
            Text(LocalizedStringKey(title))
                .font(.system(size: 11))
                .foregroundStyle(MacTheme.textPrimary)
            Spacer()
            Text(LocalizedStringKey(allowed ? "Đã cấp" : "Cần cấp"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(allowed ? MacTheme.signal : MacTheme.textSecondary)
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
