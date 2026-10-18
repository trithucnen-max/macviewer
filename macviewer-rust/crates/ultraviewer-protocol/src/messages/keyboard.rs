use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum KeyboardKind {
    KeyDown = 1,
    KeyUp = 2,
    SystemKeyDown = 3,
    SystemKeyUp = 4,
}

#[derive(Error, Debug, PartialEq, Eq)]
pub enum KeyboardError {
    #[error("Unsupported Windows window message: {0:#x}")]
    UnsupportedWindowsMessage(u32),
}

impl KeyboardKind {
    pub fn from_windows_message(msg: u32) -> Result<Self, KeyboardError> {
        match msg {
            0x100 => Ok(KeyboardKind::KeyDown),
            0x101 => Ok(KeyboardKind::KeyUp),
            0x104 => Ok(KeyboardKind::SystemKeyDown),
            0x105 => Ok(KeyboardKind::SystemKeyUp),
            _ => Err(KeyboardError::UnsupportedWindowsMessage(msg)),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct KeyboardMessage {
    pub kind: KeyboardKind,
    pub virtual_key: u8,
    pub scan_code: u16,
    pub character: u16,
    pub caps_lock_on: bool,
}

impl KeyboardMessage {
    pub fn encode(&self) -> Vec<u8> {
        vec![
            30,
            0x7c,
            0x7c,
            0x7c,
            self.kind as u8,
            self.virtual_key,
            (self.scan_code & 0xff) as u8,
            ((self.scan_code >> 8) & 0xff) as u8,
            (self.character & 0xff) as u8,
            ((self.character >> 8) & 0xff) as u8,
            if self.caps_lock_on { 1 } else { 0 },
        ]
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_keyboard_encode() {
        let msg = KeyboardMessage {
            kind: KeyboardKind::KeyDown,
            virtual_key: 0x41, // 'A'
            scan_code: 0x1e,
            character: 0x61, // 'a'
            caps_lock_on: false,
        };
        let encoded = msg.encode();
        assert_eq!(encoded.len(), 11);
        assert_eq!(&encoded[..4], &[30, 0x7c, 0x7c, 0x7c]);
        assert_eq!(encoded[4], 1);
        assert_eq!(encoded[5], 0x41);
        assert_eq!(encoded[6], 0x1e);
        assert_eq!(encoded[7], 0);
        assert_eq!(encoded[8], 0x61);
        assert_eq!(encoded[9], 0);
        assert_eq!(encoded[10], 0);
    }
}
