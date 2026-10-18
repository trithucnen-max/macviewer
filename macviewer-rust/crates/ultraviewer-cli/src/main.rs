use std::env;
use ultraviewer_protocol::{LegacyAes, UltraViewerSession};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("=== UltraViewer Rust Engine CLI Client ===");

    let args: Vec<String> = env::args().collect();
    if args.len() < 3 {
        println!("Usage: ultraviewer-cli <partner_id> <password>");
        println!("Example: ultraviewer-cli 12345678 mypass");
        return Ok(());
    }

    let partner_id = &args[1];
    let password = &args[2];

    println!("Initializing UltraViewer session for Partner ID: {}", partner_id);
    let mut session = UltraViewerSession::new(partner_id);
    session.set_state(ultraviewer_protocol::SessionState::Connecting);

    println!("Deriving cryptographic keys with UltraViewer MD5 Overlap...");
    let aes = LegacyAes::new(password)?;
    let test_msg = b"MacViewer Rust Ping";
    let encrypted = aes.encrypt(test_msg)?;
    let decrypted = aes.decrypt(&encrypted)?;

    assert_eq!(decrypted, test_msg);
    println!("Crypto self-test PASSED (AES-256-CBC with MD5 overlap)");

    session.set_state(ultraviewer_protocol::SessionState::Connected);
    println!("Session ready for UltraViewer Relay / P2P transport.");

    Ok(())
}
