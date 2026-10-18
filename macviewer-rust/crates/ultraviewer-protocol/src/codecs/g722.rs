use thiserror::Error;

enum MacViewerG722DecoderOpaque {}

extern "C" {
    fn MacViewerG722Create() -> *mut MacViewerG722DecoderOpaque;
    fn MacViewerG722Destroy(decoder: *mut MacViewerG722DecoderOpaque);
    fn MacViewerG722Decode(
        decoder: *mut MacViewerG722DecoderOpaque,
        encoded: *const u8,
        encoded_length: usize,
        pcm: *mut i16,
        pcm_capacity: usize,
    ) -> usize;
}

#[derive(Error, Debug, PartialEq, Eq)]
pub enum G722Error {
    #[error("Failed to create G.722 decoder")]
    CreationFailed,
    #[error("PCM output buffer overflow")]
    BufferOverflow,
}

pub struct G722Decoder {
    handle: *mut MacViewerG722DecoderOpaque,
}

impl G722Decoder {
    pub fn new() -> Result<Self, G722Error> {
        let handle = unsafe { MacViewerG722Create() };
        if handle.is_null() {
            return Err(G722Error::CreationFailed);
        }
        Ok(Self { handle })
    }

    /// Decodes G.722 audio bytes into 16kHz 16-bit PCM samples.
    /// Each G.722 byte expands into two 16-bit PCM samples.
    pub fn decode(&mut self, encoded: &[u8]) -> Result<Vec<i16>, G722Error> {
        if encoded.is_empty() {
            return Ok(Vec::new());
        }

        let capacity = encoded.len() * 2;
        let mut pcm = vec![0i16; capacity];

        let samples_decoded = unsafe {
            MacViewerG722Decode(
                self.handle,
                encoded.as_ptr(),
                encoded.len(),
                pcm.as_mut_ptr(),
                pcm.len(),
            )
        };

        pcm.truncate(samples_decoded);
        Ok(pcm)
    }
}

impl Drop for G722Decoder {
    fn drop(&mut self) {
        unsafe {
            if !self.handle.is_null() {
                MacViewerG722Destroy(self.handle);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_g722_create_and_decode() {
        let mut decoder = G722Decoder::new().unwrap();
        let silence = vec![0u8; 160]; // 20ms of audio
        let pcm = decoder.decode(&silence).unwrap();
        assert_eq!(pcm.len(), 320);
    }
}
