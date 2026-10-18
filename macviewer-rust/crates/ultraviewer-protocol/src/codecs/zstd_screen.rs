use std::ffi::{c_char, c_int, c_uint, c_void, CStr};
use thiserror::Error;

#[repr(C)]
struct ZstdInBuffer {
    src: *const c_void,
    size: usize,
    pos: usize,
}

#[repr(C)]
struct ZstdOutBuffer {
    dst: *mut c_void,
    size: usize,
    pos: usize,
}

enum ZstdDStream {}

const ZSTD_D_WINDOW_LOG_MAX: c_int = 100;
const ZSTD_RESET_SESSION_ONLY: c_int = 1;

extern "C" {
    fn ZSTD_createDStream() -> *mut ZstdDStream;
    fn ZSTD_freeDStream(zds: *mut ZstdDStream) -> usize;
    fn ZSTD_initDStream(zds: *mut ZstdDStream) -> usize;
    fn ZSTD_DCtx_loadDictionary(zds: *mut ZstdDStream, dict: *const c_void, dictSize: usize) -> usize;
    fn ZSTD_DCtx_setParameter(zds: *mut ZstdDStream, param: c_int, value: c_int) -> usize;
    fn ZSTD_DCtx_reset(zds: *mut ZstdDStream, reset: c_int) -> usize;
    fn ZSTD_decompressStream(
        zds: *mut ZstdDStream,
        output: *mut ZstdOutBuffer,
        input: *mut ZstdInBuffer,
    ) -> usize;
    fn ZSTD_compress(
        dst: *mut c_void,
        dstCapacity: usize,
        src: *const c_void,
        srcSize: usize,
        compressionLevel: c_int,
    ) -> usize;
    fn ZSTD_isError(code: usize) -> c_uint;
    fn ZSTD_getErrorName(code: usize) -> *const c_char;
}

#[derive(Error, Debug, PartialEq, Eq)]
pub enum ZstdError {
    #[error("Failed to allocate ZSTD decompression context")]
    AllocationFailed,
    #[error("Invalid ZSTD data: {0}")]
    InvalidData(String),
    #[error("Decompressed output limit exceeded")]
    OutputLimitExceeded,
    #[error("Incomplete ZSTD frame")]
    IncompleteFrame,
    #[error("Reset required after failure")]
    ResetRequired,
    #[error("Compression failed")]
    CompressionFailed,
}

fn check_zstd(code: usize) -> Result<(), ZstdError> {
    unsafe {
        if ZSTD_isError(code) != 0 {
            let msg_ptr = ZSTD_getErrorName(code);
            let msg = if msg_ptr.is_null() {
                "Unknown ZSTD error".to_string()
            } else {
                CStr::from_ptr(msg_ptr).to_string_lossy().into_owned()
            };
            return Err(ZstdError::InvalidData(msg));
        }
    }
    Ok(())
}

pub struct ZstdScreenDecoder {
    context: *mut ZstdDStream,
    maximum_output_bytes: usize,
    frame_output_count: usize,
    last_hint: usize,
    started: bool,
    failed: bool,
}

impl ZstdScreenDecoder {
    pub fn new(maximum_output_bytes: usize, dictionary: Option<&[u8]>) -> Result<Self, ZstdError> {
        assert!(maximum_output_bytes > 0);
        let context = unsafe { ZSTD_createDStream() };
        if context.is_null() {
            return Err(ZstdError::AllocationFailed);
        }

        unsafe {
            if let Err(e) = check_zstd(ZSTD_initDStream(context)) {
                ZSTD_freeDStream(context);
                return Err(e);
            }
            if let Some(dict) = dictionary {
                if let Err(e) = check_zstd(ZSTD_DCtx_loadDictionary(
                    context,
                    dict.as_ptr() as *const c_void,
                    dict.len(),
                )) {
                    ZSTD_freeDStream(context);
                    return Err(e);
                }
            }
            // Window log max 27 (128MB)
            if let Err(e) = check_zstd(ZSTD_DCtx_setParameter(context, ZSTD_D_WINDOW_LOG_MAX, 27)) {
                ZSTD_freeDStream(context);
                return Err(e);
            }
        }

        Ok(Self {
            context,
            maximum_output_bytes,
            frame_output_count: 0,
            last_hint: 0,
            started: false,
            failed: false,
        })
    }

    pub fn reset(&mut self) -> Result<(), ZstdError> {
        unsafe {
            check_zstd(ZSTD_DCtx_reset(self.context, ZSTD_RESET_SESSION_ONLY))?;
        }
        self.frame_output_count = 0;
        self.last_hint = 0;
        self.started = false;
        self.failed = false;
        Ok(())
    }

    pub fn append(&mut self, compressed: &[u8]) -> Result<Vec<u8>, ZstdError> {
        if self.failed {
            return Err(ZstdError::ResetRequired);
        }
        if compressed.is_empty() {
            return Ok(Vec::new());
        }

        let mut input = ZstdInBuffer {
            src: compressed.as_ptr() as *const c_void,
            size: compressed.len(),
            pos: 0,
        };

        let mut result = Vec::new();
        let chunk_size = 128 * 1024.min(self.maximum_output_bytes);
        let mut buffer = vec![0u8; chunk_size];

        while input.pos < input.size {
            let mut output = ZstdOutBuffer {
                dst: buffer.as_mut_ptr() as *mut c_void,
                size: buffer.len(),
                pos: 0,
            };

            let hint = unsafe { ZSTD_decompressStream(self.context, &mut output, &mut input) };
            if let Err(e) = check_zstd(hint) {
                self.failed = true;
                return Err(e);
            }

            self.started = true;
            self.last_hint = hint;
            let produced = output.pos;

            if produced > self.maximum_output_bytes - self.frame_output_count
                || produced > self.maximum_output_bytes - result.len()
            {
                self.failed = true;
                return Err(ZstdError::OutputLimitExceeded);
            }

            result.extend_from_slice(&buffer[..produced]);
            self.frame_output_count += produced;

            if hint == 0 {
                self.frame_output_count = 0;
            }

            if produced == 0 && input.pos == input.size {
                break;
            }
        }

        Ok(result)
    }

    pub fn finish(&self) -> Result<(), ZstdError> {
        if self.failed {
            return Err(ZstdError::ResetRequired);
        }
        if self.started && self.last_hint != 0 {
            return Err(ZstdError::IncompleteFrame);
        }
        Ok(())
    }
}

impl Drop for ZstdScreenDecoder {
    fn drop(&mut self) {
        unsafe {
            if !self.context.is_null() {
                ZSTD_freeDStream(self.context);
            }
        }
    }
}

pub struct ZstdScreenEncoder;

impl ZstdScreenEncoder {
    pub fn encode(data: &[u8], maximum_output_bytes: usize) -> Result<Vec<u8>, ZstdError> {
        let max_compressed = data.len() + 1024;
        let capacity = max_compressed.min(maximum_output_bytes);
        let mut output = vec![0u8; capacity];

        let compressed_size = unsafe {
            ZSTD_compress(
                output.as_mut_ptr() as *mut c_void,
                output.len(),
                data.as_ptr() as *const c_void,
                data.len(),
                1, // level 1 fast compression for remote desktop
            )
        };

        check_zstd(compressed_size)?;
        output.truncate(compressed_size);
        Ok(output)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_zstd_compression_and_decompression_roundtrip() {
        let original = b"UltraViewer Screen Frame Test Stream Data that compresses very well repeated repeated repeated";
        let compressed = ZstdScreenEncoder::encode(original, 1024 * 1024).unwrap();
        assert!(compressed.len() < original.len());

        let mut decoder = ZstdScreenDecoder::new(1024 * 1024, None).unwrap();
        let decompressed = decoder.append(&compressed).unwrap();
        decoder.finish().unwrap();

        assert_eq!(decompressed, original);
    }
}
