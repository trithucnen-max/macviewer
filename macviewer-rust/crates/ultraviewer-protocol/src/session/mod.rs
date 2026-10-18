use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SessionState {
    Disconnected,
    Connecting,
    Authenticating,
    Connected,
    Streaming,
    Terminated,
}

#[derive(Error, Debug, PartialEq, Eq)]
pub enum SessionError {
    #[error("Authentication failed: invalid ID or password")]
    AuthenticationFailed,
    #[error("Connection lost")]
    ConnectionLost,
    #[error("Protocol error: {0}")]
    Protocol(String),
}

pub struct UltraViewerSession {
    pub partner_id: String,
    pub state: SessionState,
}

impl UltraViewerSession {
    pub fn new(partner_id: &str) -> Self {
        Self {
            partner_id: partner_id.to_string(),
            state: SessionState::Disconnected,
        }
    }

    pub fn set_state(&mut self, new_state: SessionState) {
        log::info!("UltraViewer session state changed: {:?} -> {:?}", self.state, new_state);
        self.state = new_state;
    }
}
