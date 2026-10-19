import Foundation
import CryptoKit
import Darwin
import UltraViewerProtocol

enum MobileRegistrationProfile {
    struct NetworkIdentity {
        let address: RelayIPv4Address
        let macAddress: String
    }

    private static let storageLock = NSLock()

    static func loadOrCreate() throws -> ClientRegistration.Request {
        storageLock.lock()
        defer { storageLock.unlock() }

        let defaults = UserDefaults.standard
        let deviceId: String
        let password: String

        if let storedId = defaults.string(forKey: "UtralviewMobile.DeviceId"),
           storedId.count == 32,
           let storedPwd = defaults.string(forKey: "UtralviewMobile.Password"),
           storedPwd.count == 8 {
            deviceId = storedId
            password = storedPwd
        } else {
            let uuid = UUID()
            var bytes = uuid.uuid
            let digest = withUnsafeBytes(of: &bytes) { Insecure.MD5.hash(data: Data($0)) }
            deviceId = digest.map { String(format: "%02X", $0) }.joined()
            password = (0..<8).map { _ in String(Int.random(in: 0...9)) }.joined()
            defaults.set(deviceId, forKey: "UtralviewMobile.DeviceId")
            defaults.set(password, forKey: "UtralviewMobile.Password")
        }

        let network = discoverNetwork()
        let process = ProcessInfo.processInfo
        let osVersion = "\(process.operatingSystemVersion.patchVersion)|\(process.operatingSystemVersion.majorVersion)|0|\(process.operatingSystemVersion.minorVersion)|0|0"
        let hostName = process.hostName.isEmpty ? "iPhone" : process.hostName
        let computerNameB64 = Data(hostName.utf8).base64EncodedString()

        return ClientRegistration.Request(
            deviceIdentity: deviceId,
            password: password,
            localAddress: network.address,
            computerNameUTF8Base64: computerNameB64,
            clientVersion: "6.6.133",
            macAddress: network.macAddress,
            diskIdentity: "",
            operatingSystem: osVersion,
            installerReferral: 0,
            customPassword: "",
            usesProxy: false,
            quickSupportMetadata: "",
            userNameWireValue: "iPhone",
            activeSessionID: 0,
            processSessionID: 0,
            preferredIDText: "0",
            referralIDText: "0",
            automaticUpdate: 0,
            systemFolderCreationTicks: "0",
            programFilesCreationTicks: "0",
            systemVolumeInformationCreationTicks: "0",
            licenseContext1: "",
            licenseContext2: "",
            captchaToken: ""
        )
    }

    private static func discoverNetwork() -> NetworkIdentity {
        var head: UnsafeMutablePointer<ifaddrs>?
        let fallbackAddr = (try? RelayIPv4Address("192.168.1.50")) ?? (try! RelayIPv4Address("127.0.0.1"))
        guard getifaddrs(&head) == 0, let firstNode = head else {
            return NetworkIdentity(address: fallbackAddr, macAddress: "020000000000")
        }
        defer { freeifaddrs(firstNode) }

        var foundAddress: RelayIPv4Address?
        var foundMac: String?

        var cursor: UnsafeMutablePointer<ifaddrs>? = firstNode
        while let node = cursor {
            defer { cursor = node.pointee.ifa_next }
            let entry = node.pointee
            guard entry.ifa_flags & UInt32(IFF_UP) != 0,
                  entry.ifa_flags & UInt32(IFF_RUNNING) != 0,
                  entry.ifa_flags & UInt32(IFF_LOOPBACK) == 0,
                  let address = entry.ifa_addr else { continue }

            let name = String(cString: entry.ifa_name)
            let isPreferred = name == "en0" || name.starts(with: "pdp_ip")

            switch Int32(address.pointee.sa_family) {
            case AF_INET:
                var ipv4 = UnsafeRawPointer(address).assumingMemoryBound(to: sockaddr_in.self).pointee.sin_addr
                var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                if inet_ntop(AF_INET, &ipv4, &buffer, socklen_t(buffer.count)) != nil,
                   let parsed = try? RelayIPv4Address(String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)) {
                    if foundAddress == nil || isPreferred {
                        foundAddress = parsed
                    }
                }
            case AF_LINK:
                let raw = UnsafeRawPointer(address)
                let link = raw.assumingMemoryBound(to: sockaddr_dl.self).pointee
                if let dataOffset = MemoryLayout<sockaddr_dl>.offset(of: \.sdl_data), link.sdl_alen == 6 {
                    let start = dataOffset + Int(link.sdl_nlen)
                    if start + 6 <= Int(address.pointee.sa_len) {
                        let bytes = UnsafeBufferPointer(start: raw.advanced(by: start).assumingMemoryBound(to: UInt8.self), count: 6)
                        if bytes.contains(where: { $0 != 0 }), bytes[0] & 1 == 0 {
                            let macStr = bytes.map { String(format: "%02X", $0) }.joined()
                            if foundMac == nil || isPreferred {
                                foundMac = macStr
                            }
                        }
                    }
                }
            default:
                break
            }
        }

        return NetworkIdentity(
            address: foundAddress ?? fallbackAddr,
            macAddress: foundMac ?? "020000000000"
        )
    }
}
