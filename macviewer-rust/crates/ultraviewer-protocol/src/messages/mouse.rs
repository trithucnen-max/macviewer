#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(i32)]
pub enum MouseButton {
    LeftDown = 0x201,
    LeftUp = 0x202,
    LeftDoubleClick = 0x203,
    RightDown = 0x204,
    RightUp = 0x205,
    RightDoubleClick = 0x206,
    MiddleDown = 0x207,
    MiddleUp = 0x208,
    MiddleDoubleClick = 0x209,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MouseMessage {
    Move { w_param: i32, x: i32, y: i32 },
    Button { button: MouseButton, w_param: i32, l_param: i32 },
    VerticalWheel { w_param: i32, l_param: i32 },
}

impl MouseMessage {
    pub fn windows_message(&self) -> i32 {
        match self {
            MouseMessage::Move { .. } => 0x200,
            MouseMessage::Button { button, .. } => *button as i32,
            MouseMessage::VerticalWheel { .. } => 0x20a,
        }
    }

    pub fn text(&self) -> String {
        match self {
            MouseMessage::Move { w_param, x, y } => {
                format!("8|||{}|||{}|||{}|||{}", self.windows_message(), w_param, x, y)
            }
            MouseMessage::Button { w_param, l_param, .. }
            | MouseMessage::VerticalWheel { w_param, l_param } => {
                format!("8|||{}|||{}|||{}", self.windows_message(), w_param, l_param)
            }
        }
    }

    pub fn encode(&self) -> Vec<u8> {
        self.text().into_bytes()
    }

    pub fn packed_position(x: i16, y: i16) -> i32 {
        let bits = (x as u16 as u32) | ((y as u16 as u32) << 16);
        bits as i32
    }

    pub fn wheel_w_param(delta: i16, key_flags: u16) -> i32 {
        let bits = (key_flags as u32) | ((delta as u16 as u32) << 16);
        bits as i32
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mouse_move_format() {
        let msg = MouseMessage::Move { w_param: 0, x: 100, y: 200 };
        assert_eq!(msg.text(), "8|||512|||0|||100|||200");
    }

    #[test]
    fn test_mouse_click_format() {
        let msg = MouseMessage::Button {
            button: MouseButton::LeftDown,
            w_param: 1,
            l_param: MouseMessage::packed_position(50, 60),
        };
        assert_eq!(msg.text(), format!("8|||513|||1|||{}", MouseMessage::packed_position(50, 60)));
    }
}
