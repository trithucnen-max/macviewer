use aes::cipher::{block_padding::Pkcs7, BlockDecryptMut, BlockEncryptMut, KeyIvInit};
use sha1::{Digest, Sha1};
use thiserror::Error;

type TdesCbcEnc = cbc::Encryptor<des::TdesEde3>;
type TdesCbcDec = cbc::Decryptor<des::TdesEde3>;

const BLOCK_SIZE: usize = 8;
const KEY_SIZE: usize = 24;

#[derive(Error, Debug, PartialEq, Eq)]
pub enum LegacyCommandCipherError {
    #[error("Malformed ciphertext: invalid length")]
    MalformedCiphertext,
    #[error("Invalid padding")]
    InvalidPadding,
    #[error("Decryption failed")]
    DecryptionFailed,
}

#[derive(Clone)]
pub struct LegacyCommandCipher {
    key: [u8; KEY_SIZE],
    iv: [u8; BLOCK_SIZE],
}

impl LegacyCommandCipher {
    /// Static command-cipher configuration observed at desktop VA 0x635a8c.
    /// Password: ASCII characters [5, 10, 15, 20, 25].
    pub fn desktop_server_commands() -> Self {
        let password: String = [5u8, 10, 15, 20, 25].iter().map(|&c| c as char).collect();
        Self::new(&password)
    }

    pub fn new(password: &str) -> Self {
        // UTF-16LE bytes
        let mut utf16_bytes = Vec::with_capacity(password.encode_utf16().count() * 2);
        for unit in password.encode_utf16() {
            utf16_bytes.push(unit as u8);
            utf16_bytes.push((unit >> 8) as u8);
        }

        // SHA-1 of UTF-16LE password + 4 zero bytes
        let mut sha1_pass = Sha1::new();
        sha1_pass.update(&utf16_bytes);
        let digest = sha1_pass.finalize();

        let mut key = [0u8; KEY_SIZE];
        key[..20].copy_from_slice(&digest);

        // IV = SHA1(empty_data)[0..8]
        let mut sha1_empty = Sha1::new();
        sha1_empty.update(b"");
        let empty_digest = sha1_empty.finalize();
        let mut iv = [0u8; BLOCK_SIZE];
        iv.copy_from_slice(&empty_digest[..8]);

        Self { key, iv }
    }

    pub fn encrypt(&self, plaintext: &[u8]) -> Vec<u8> {
        let cipher = TdesCbcEnc::new(&self.key.into(), &self.iv.into());
        cipher.encrypt_padded_vec_mut::<Pkcs7>(plaintext)
    }

    pub fn decrypt(&self, ciphertext: &[u8]) -> Result<Vec<u8>, LegacyCommandCipherError> {
        if ciphertext.is_empty() || ciphertext.len() % BLOCK_SIZE != 0 {
            return Err(LegacyCommandCipherError::MalformedCiphertext);
        }

        let cipher = TdesCbcDec::new(&self.key.into(), &self.iv.into());
        cipher
            .decrypt_padded_vec_mut::<Pkcs7>(ciphertext)
            .map_err(|_| LegacyCommandCipherError::InvalidPadding)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn hex(val: &str) -> Vec<u8> {
        (0..val.len())
            .step_by(2)
            .map(|i| u8::from_str_radix(&val[i..i + 2], 16).unwrap())
            .collect()
    }

    #[test]
    fn test_command_cipher_matches_independent_openssl_vector() {
        let cipher = LegacyCommandCipher::new("fixture-⌘");
        let plaintext = b"8:123456789:synthetic-proof";
        let expected = hex("b63b9797064974fa31181fef729c755558492379dcb44c69e3fe4c6d0e29836c");

        let encrypted = cipher.encrypt(plaintext);
        assert_eq!(encrypted, expected);

        let decrypted = cipher.decrypt(&expected).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_configured_desktop_server_cipher_matches_static_key_fixture() {
        let cipher = LegacyCommandCipher::desktop_server_commands();
        let expected = hex("c842551785856d0b8f866afed8dcd8b1");
        let plaintext = b"8:fixture";

        let encrypted = cipher.encrypt(plaintext);
        assert_eq!(encrypted, expected);

        let decrypted = cipher.decrypt(&expected).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_command_cipher_roundtrips_block_boundaries_and_unicode_passwords() {
        for password in ["", "compatibility-test", "🔑é⌘"] {
            let cipher = LegacyCommandCipher::new(password);
            for length in [0, 1, 7, 8, 9, 15, 16, 17, 1024] {
                let plaintext: Vec<u8> = (0..length).map(|i| i as u8).collect();
                let encrypted = cipher.encrypt(&plaintext);
                assert!(!encrypted.is_empty());
                assert_eq!(encrypted.len(), (length / 8 + 1) * 8);

                let decrypted = cipher.decrypt(&encrypted).unwrap();
                assert_eq!(decrypted, plaintext);
            }
        }
    }

    #[test]
    fn test_command_cipher_rejects_malformed_and_invalid_padding() {
        let cipher = LegacyCommandCipher::new("fixture-⌘");
        for invalid in [vec![], vec![1], vec![0; 7], vec![0; 9]] {
            assert_eq!(
                cipher.decrypt(&invalid).unwrap_err(),
                LegacyCommandCipherError::MalformedCiphertext
            );
        }

        for invalid in ["e074f13ae60ec9e4", "22959c7b190b62a7", "da71e6936b3c4dba"] {
            assert_eq!(
                cipher.decrypt(&hex(invalid)).unwrap_err(),
                LegacyCommandCipherError::InvalidPadding
            );
        }
    }
}
