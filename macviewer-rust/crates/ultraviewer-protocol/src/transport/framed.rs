use thiserror::Error;

pub const DEFAULT_MAX_PAYLOAD_LENGTH: usize = 16 * 1024 * 1024; // 16MB

#[derive(Error, Debug, PartialEq, Eq)]
pub enum FrameError {
    #[error("Frame length exceeds maximum allowed payload")]
    FrameTooLarge,
    #[error("Invalid frame length in stream")]
    InvalidLength,
}

pub struct LengthPrefixedFrame;

impl LengthPrefixedFrame {
    pub fn encode(payload: &[u8]) -> Result<Vec<u8>, FrameError> {
        if payload.len() > i32::MAX as usize {
            return Err(FrameError::FrameTooLarge);
        }
        let length = payload.len() as u32;
        let mut frame = Vec::with_capacity(4 + payload.len());
        frame.extend_from_slice(&length.to_le_bytes());
        frame.extend_from_slice(payload);
        Ok(frame)
    }
}

pub struct FrameDecoder {
    maximum_payload_length: usize,
    buffer: Vec<u8>,
}

impl Default for FrameDecoder {
    fn default() -> Self {
        Self::new(DEFAULT_MAX_PAYLOAD_LENGTH)
    }
}

impl FrameDecoder {
    pub fn new(maximum_payload_length: usize) -> Self {
        assert!(maximum_payload_length <= i32::MAX as usize);
        Self {
            maximum_payload_length,
            buffer: Vec::new(),
        }
    }

    pub fn append(&mut self, bytes: &[u8]) -> Result<Vec<Vec<u8>>, FrameError> {
        let mut frames = Vec::new();
        let mut cursor = 0;

        while cursor < bytes.len() {
            if self.buffer.len() < 4 {
                let count = (4 - self.buffer.len()).min(bytes.len() - cursor);
                self.buffer.extend_from_slice(&bytes[cursor..cursor + count]);
                cursor += count;
                if self.buffer.len() < 4 {
                    break;
                }
            }

            let length = u32::from_le_bytes([
                self.buffer[0],
                self.buffer[1],
                self.buffer[2],
                self.buffer[3],
            ]);

            if length > i32::MAX as u32 {
                self.buffer.clear();
                return Err(FrameError::InvalidLength);
            }

            let len = length as usize;
            if len > self.maximum_payload_length {
                self.buffer.clear();
                return Err(FrameError::FrameTooLarge);
            }

            let total_length = 4 + len;
            let count = (total_length - self.buffer.len()).min(bytes.len() - cursor);
            if count > 0 {
                self.buffer.extend_from_slice(&bytes[cursor..cursor + count]);
                cursor += count;
            }

            if self.buffer.len() < total_length {
                break;
            }

            frames.push(self.buffer[4..total_length].to_vec());
            self.buffer.clear();
        }

        Ok(frames)
    }

    pub fn has_incomplete_frame(&self) -> bool {
        !self.buffer.is_empty()
    }

    pub fn reset(&mut self) {
        self.buffer.clear();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encode_and_decode_roundtrip() {
        let payload = b"Hello, UltraViewer!";
        let encoded = LengthPrefixedFrame::encode(payload).unwrap();
        assert_eq!(&encoded[..4], &(payload.len() as u32).to_le_bytes());
        assert_eq!(&encoded[4..], payload);

        let mut decoder = FrameDecoder::default();
        let frames = decoder.append(&encoded).unwrap();
        assert_eq!(frames.len(), 1);
        assert_eq!(frames[0], payload);
        assert!(!decoder.has_incomplete_frame());
    }

    #[test]
    fn test_fragmented_frame_reconstruction() {
        let payload = b"Fragmented testing message stream";
        let encoded = LengthPrefixedFrame::encode(payload).unwrap();
        let mut decoder = FrameDecoder::default();

        let mut all_frames = Vec::new();
        for chunk in encoded.chunks(3) {
            let frames = decoder.append(chunk).unwrap();
            all_frames.extend(frames);
        }

        assert_eq!(all_frames.len(), 1);
        assert_eq!(all_frames[0], payload);
        assert!(!decoder.has_incomplete_frame());
    }

    #[test]
    fn test_coalesced_frames() {
        let p1 = b"Frame One";
        let p2 = b"Frame Two";
        let mut coalesced = LengthPrefixedFrame::encode(p1).unwrap();
        coalesced.extend(LengthPrefixedFrame::encode(p2).unwrap());

        let mut decoder = FrameDecoder::default();
        let frames = decoder.append(&coalesced).unwrap();
        assert_eq!(frames.len(), 2);
        assert_eq!(frames[0], p1);
        assert_eq!(frames[1], p2);
    }
}
