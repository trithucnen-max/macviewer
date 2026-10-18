use std::ffi::{c_char, CStr};
use ultraviewer_protocol::{G722Decoder, LegacyAes, ZstdScreenDecoder};

#[no_mangle]
pub unsafe extern "C" fn uv_aes_create(password: *const c_char) -> *mut LegacyAes {
    if password.is_null() {
        return std::ptr::null_mut();
    }
    let c_str = CStr::from_ptr(password);
    if let Ok(pwd) = c_str.to_str() {
        if let Ok(aes) = LegacyAes::new(pwd) {
            return Box::into_raw(Box::new(aes));
        }
    }
    std::ptr::null_mut()
}

#[no_mangle]
pub unsafe extern "C" fn uv_aes_destroy(aes: *mut LegacyAes) {
    if !aes.is_null() {
        drop(Box::from_raw(aes));
    }
}

#[no_mangle]
pub unsafe extern "C" fn uv_aes_encrypt(
    aes: *mut LegacyAes,
    data: *const u8,
    len: usize,
    out_len: *mut usize,
) -> *mut u8 {
    if aes.is_null() || data.is_null() || out_len.is_null() {
        return std::ptr::null_mut();
    }
    let slice = std::slice::from_raw_parts(data, len);
    if let Ok(encrypted) = (*aes).encrypt(slice) {
        *out_len = encrypted.len();
        let mut boxed = encrypted.into_boxed_slice();
        let ptr = boxed.as_mut_ptr();
        std::mem::forget(boxed);
        return ptr;
    }
    std::ptr::null_mut()
}

#[no_mangle]
pub unsafe extern "C" fn uv_aes_decrypt(
    aes: *mut LegacyAes,
    data: *const u8,
    len: usize,
    out_len: *mut usize,
) -> *mut u8 {
    if aes.is_null() || data.is_null() || out_len.is_null() {
        return std::ptr::null_mut();
    }
    let slice = std::slice::from_raw_parts(data, len);
    if let Ok(decrypted) = (*aes).decrypt(slice) {
        *out_len = decrypted.len();
        let mut boxed = decrypted.into_boxed_slice();
        let ptr = boxed.as_mut_ptr();
        std::mem::forget(boxed);
        return ptr;
    }
    std::ptr::null_mut()
}

#[no_mangle]
pub unsafe extern "C" fn uv_g722_create() -> *mut G722Decoder {
    if let Ok(decoder) = G722Decoder::new() {
        return Box::into_raw(Box::new(decoder));
    }
    std::ptr::null_mut()
}

#[no_mangle]
pub unsafe extern "C" fn uv_g722_destroy(decoder: *mut G722Decoder) {
    if !decoder.is_null() {
        drop(Box::from_raw(decoder));
    }
}

#[no_mangle]
pub unsafe extern "C" fn uv_g722_decode(
    decoder: *mut G722Decoder,
    encoded: *const u8,
    len: usize,
    out_samples: *mut usize,
) -> *mut i16 {
    if decoder.is_null() || encoded.is_null() || out_samples.is_null() {
        return std::ptr::null_mut();
    }
    let slice = std::slice::from_raw_parts(encoded, len);
    if let Ok(pcm) = (*decoder).decode(slice) {
        *out_samples = pcm.len();
        let mut boxed = pcm.into_boxed_slice();
        let ptr = boxed.as_mut_ptr();
        std::mem::forget(boxed);
        return ptr;
    }
    std::ptr::null_mut()
}

#[no_mangle]
pub unsafe extern "C" fn uv_zstd_decoder_create(max_bytes: usize) -> *mut ZstdScreenDecoder {
    if let Ok(decoder) = ZstdScreenDecoder::new(max_bytes, None) {
        return Box::into_raw(Box::new(decoder));
    }
    std::ptr::null_mut()
}

#[no_mangle]
pub unsafe extern "C" fn uv_zstd_decoder_destroy(decoder: *mut ZstdScreenDecoder) {
    if !decoder.is_null() {
        drop(Box::from_raw(decoder));
    }
}

#[no_mangle]
pub unsafe extern "C" fn uv_free_bytes(ptr: *mut u8, len: usize) {
    if !ptr.is_null() {
        drop(Vec::from_raw_parts(ptr, len, len));
    }
}

#[no_mangle]
pub unsafe extern "C" fn uv_free_pcm(ptr: *mut i16, len: usize) {
    if !ptr.is_null() {
        drop(Vec::from_raw_parts(ptr, len, len));
    }
}
