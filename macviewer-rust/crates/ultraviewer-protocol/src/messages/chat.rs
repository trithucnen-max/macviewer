use super::multipart::{MultipartLimits, MultipartPayload};
use thiserror::Error;

pub const MAXIMUM_CHAT_TEXT_BYTES: usize = 32 * 1024;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ChatEvent {
    Message(String),
    Typing(bool),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ChatOutbound {
    pub payload: Vec<u8>,
    pub format_flag: bool,
}

#[derive(Error, Debug, PartialEq, Eq)]
pub enum ChatError {
    #[error("Chat text is too large")]
    TextTooLarge,
    #[error("Invalid character encoding in chat")]
    InvalidEncoding,
    #[error("Invalid text characters")]
    InvalidText,
    #[error("Unsupported delimiter in chat message")]
    UnsupportedDelimiter,
    #[error("Malformed chat message")]
    MalformedMessage,
    #[error("Multipart error: {0}")]
    Multipart(#[from] super::multipart::MultipartError),
}

pub struct ChatProtocol;

impl ChatProtocol {
    pub fn viewer_to_host(text: &str) -> Result<ChatOutbound, ChatError> {
        Self::validate_text(text)?;
        if text.contains("|||") {
            return Err(ChatError::UnsupportedDelimiter);
        }

        let full_text = format!("12|||{}", text);
        Ok(ChatOutbound {
            payload: Self::to_utf16_le(&full_text),
            format_flag: true,
        })
    }

    pub fn viewer_to_host_typing(is_typing: bool) -> ChatOutbound {
        ChatOutbound {
            payload: Self::to_utf16_le(if is_typing { "29" } else { "30" }),
            format_flag: true,
        }
    }

    pub fn host_to_viewer(text: &str) -> Result<Vec<u8>, ChatError> {
        Self::validate_text(text)?;
        let utf16 = Self::to_utf16_le(text);
        let limits = MultipartLimits {
            maximum_payload_length: MAXIMUM_CHAT_TEXT_BYTES + 9,
            maximum_part_length: MAXIMUM_CHAT_TEXT_BYTES,
            maximum_part_count: 2,
        };
        let encoded = MultipartPayload::encode(&[&[12], &utf16], &limits)?;
        Ok(encoded)
    }

    pub fn host_to_viewer_typing(is_typing: bool) -> Result<Vec<u8>, ChatError> {
        let limits = MultipartLimits {
            maximum_payload_length: MAXIMUM_CHAT_TEXT_BYTES + 9,
            maximum_part_length: MAXIMUM_CHAT_TEXT_BYTES,
            maximum_part_count: 2,
        };
        let cmd = [if is_typing { 29 } else { 30 }];
        let encoded = MultipartPayload::encode(&[&cmd], &limits)?;
        Ok(encoded)
    }

    pub fn decode_host_payload(payload: &[u8]) -> Result<Option<ChatEvent>, ChatError> {
        if payload == b"29" {
            return Ok(Some(ChatEvent::Typing(true)));
        }
        if payload == b"30" {
            return Ok(Some(ChatEvent::Typing(false)));
        }

        let prefix = b"12|||";
        if !payload.starts_with(prefix) {
            return Ok(None);
        }

        let body = &payload[prefix.len()..];
        if body.len() > MAXIMUM_CHAT_TEXT_BYTES {
            return Err(ChatError::TextTooLarge);
        }

        let text = std::str::from_utf8(body).map_err(|_| ChatError::InvalidEncoding)?;
        Self::validate_text(text)?;
        if text.contains("|||") {
            return Err(ChatError::UnsupportedDelimiter);
        }

        Ok(Some(ChatEvent::Message(text.to_string())))
    }

    pub fn decode_viewer_parts(parts: &[Vec<u8>]) -> Result<Option<ChatEvent>, ChatError> {
        if parts.is_empty() {
            return Ok(None);
        }
        let first = parts[0].as_slice();
        if first.is_empty() {
            return Ok(None);
        }

        let cmd = first[0];
        if ![12, 29, 30].contains(&cmd) {
            return Ok(None);
        }
        if first.len() != 1 {
            return Err(ChatError::MalformedMessage);
        }

        if cmd != 12 {
            if parts.len() != 1 {
                return Err(ChatError::MalformedMessage);
            }
            return Ok(Some(ChatEvent::Typing(cmd == 29)));
        }

        if parts.len() != 2 {
            return Err(ChatError::MalformedMessage);
        }

        let bytes = &parts[1];
        if bytes.len() > MAXIMUM_CHAT_TEXT_BYTES {
            return Err(ChatError::TextTooLarge);
        }

        let text = Self::from_utf16_le(bytes)?;
        Self::validate_text(&text)?;
        Ok(Some(ChatEvent::Message(text)))
    }

    fn validate_text(text: &str) -> Result<(), ChatError> {
        if text.len() > MAXIMUM_CHAT_TEXT_BYTES {
            return Err(ChatError::TextTooLarge);
        }
        if !text.chars().all(|c| {
            let val = c as u32;
            val >= 32 || val == 9 || val == 10 || val == 13
        }) {
            return Err(ChatError::InvalidText);
        }
        Ok(())
    }

    fn to_utf16_le(text: &str) -> Vec<u8> {
        let mut bytes = Vec::with_capacity(text.encode_utf16().count() * 2);
        for unit in text.encode_utf16() {
            bytes.push(unit as u8);
            bytes.push((unit >> 8) as u8);
        }
        bytes
    }

    fn from_utf16_le(bytes: &[u8]) -> Result<String, ChatError> {
        if bytes.len() % 2 != 0 {
            return Err(ChatError::InvalidEncoding);
        }
        let units: Vec<u16> = bytes
            .chunks_exact(2)
            .map(|chunk| u16::from_le_bytes([chunk[0], chunk[1]]))
            .collect();

        String::from_utf16(&units).map_err(|_| ChatError::InvalidEncoding)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_chat_roundtrip() {
        let outbound = ChatProtocol::viewer_to_host("Xin chào từ UltraViewer Rust").unwrap();
        assert!(outbound.format_flag);

        // Host side receives UTF-8 normalized
        let host_payload = b"12|||Xin ch\xc3\xa0o t\xe1\xbb\xab UltraViewer Rust";
        let event = ChatProtocol::decode_host_payload(host_payload).unwrap().unwrap();
        assert_eq!(event, ChatEvent::Message("Xin chào từ UltraViewer Rust".to_string()));
    }
}
