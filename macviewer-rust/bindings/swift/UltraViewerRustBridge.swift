import Foundation

/// Swift Bridge wrapping the compiled Rust `libultraviewer_ffi` static/dynamic library.
public final class UltraViewerRustAES {
    private var handle: OpaquePointer?

    public init?(password: String) {
        guard let ptr = uv_aes_create(password) else { return nil }
        self.handle = ptr
    }

    deinit {
        if let handle {
            uv_aes_destroy(handle)
        }
    }

    public func encrypt(_ data: Data) -> Data? {
        guard let handle else { return nil }
        var outLength: Int = 0
        return data.withUnsafeBytes { rawBuffer in
            guard let base = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            guard let ptr = uv_aes_encrypt(handle, base, data.count, &outLength) else { return nil }
            let result = Data(bytes: ptr, count: outLength)
            uv_free_bytes(ptr, outLength)
            return result
        }
    }

    public func decrypt(_ data: Data) -> Data? {
        guard let handle else { return nil }
        var outLength: Int = 0
        return data.withUnsafeBytes { rawBuffer in
            guard let base = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            guard let ptr = uv_aes_decrypt(handle, base, data.count, &outLength) else { return nil }
            let result = Data(bytes: ptr, count: outLength)
            uv_free_bytes(ptr, outLength)
            return result
        }
    }
}

// C-ABI function signatures from libultraviewer_ffi
@_silgen_name("uv_aes_create")
private func uv_aes_create(_ password: UnsafePointer<CChar>) -> OpaquePointer?

@_silgen_name("uv_aes_destroy")
private func uv_aes_destroy(_ handle: OpaquePointer)

@_silgen_name("uv_aes_encrypt")
private func uv_aes_encrypt(_ handle: OpaquePointer, _ data: UnsafePointer<UInt8>, _ len: Int, _ outLen: UnsafeMutablePointer<Int>) -> UnsafeMutablePointer<UInt8>?

@_silgen_name("uv_aes_decrypt")
private func uv_aes_decrypt(_ handle: OpaquePointer, _ data: UnsafePointer<UInt8>, _ len: Int, _ outLen: UnsafeMutablePointer<Int>) -> UnsafeMutablePointer<UInt8>?

@_silgen_name("uv_free_bytes")
private func uv_free_bytes(_ ptr: UnsafeMutablePointer<UInt8>, _ len: Int)
