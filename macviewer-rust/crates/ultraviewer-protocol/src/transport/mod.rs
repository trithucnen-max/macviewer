pub mod framed;

pub use framed::{FrameDecoder, FrameError, LengthPrefixedFrame, DEFAULT_MAX_PAYLOAD_LENGTH};
