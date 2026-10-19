import SwiftUI

#if canImport(UIKit)
import UIKit

public struct MobileConnectView: View {
    @ObservedObject public var sessionManager: MobileSessionManager
    @Binding public var activePartnerId: String
    @State private var partnerId = ""
    @State private var password = ""

    public init(sessionManager: MobileSessionManager, activePartnerId: Binding<String>) {
        self.sessionManager = sessionManager
        self._activePartnerId = activePartnerId
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.09)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // Logo & Header
                    VStack(spacing: 8) {
                        Image(systemName: "display.2")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(red: 0.15, green: 0.39, blue: 0.92))

                        Text("Utralview")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color(red: 0.94, green: 0.96, blue: 0.99))

                        Text("Điều khiển máy tính từ xa • BasanCorp")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(red: 0.55, green: 0.58, blue: 0.62))
                    }

                    // Card Form
                    VStack(alignment: .leading, spacing: 16) {
                        Text("KẾT NỐI ĐẾN ĐỐI TÁC")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.15, green: 0.39, blue: 0.92))

                        VStack(spacing: 12) {
                            TextField("ID đối tác (Ví dụ: 12 345 678)", text: $partnerId)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(red: 0.09, green: 0.11, blue: 0.13))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)

                            SecureField("Mật khẩu", text: $password)
                                .padding()
                                .background(Color(red: 0.09, green: 0.11, blue: 0.13))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)
                        }

                        if case let .failed(error) = sessionManager.state {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red)
                            }
                            .padding(.top, 4)
                        }

                        if case let .connecting(msg) = sessionManager.state {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(Color(red: 0.15, green: 0.39, blue: 0.92))
                                Text(msg)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 4)
                        }

                        Button(action: {
                            activePartnerId = partnerId
                            sessionManager.connect(partnerId: partnerId, password: password)
                        }) {
                            HStack {
                                if case .connecting = sessionManager.state {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Kết nối ngay")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(red: 0.15, green: 0.39, blue: 0.92))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(partnerId.isEmpty || password.isEmpty || isConnecting)
                    }
                    .padding(20)
                    .background(Color(red: 0.09, green: 0.11, blue: 0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    Spacer()

                    Text("Utralview for iPhone v2.2.2 • itngon.com")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.55, green: 0.58, blue: 0.62))
                        .padding(.bottom, 12)
                }
            }
        }
    }

    private var isConnecting: Bool {
        if case .connecting = sessionManager.state { return true }
        return false
    }
}
#endif
