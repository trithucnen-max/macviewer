use aes::cipher::{block_padding::Pkcs7, BlockDecryptMut, BlockEncryptMut, KeyIvInit};
use md5::{Digest, Md5};
use rand::RngCore;
use thiserror::Error;

type Aes256CbcEnc = cbc::Encryptor<aes::Aes256>;
type Aes256CbcDec = cbc::Decryptor<aes::Aes256>;

const BLOCK_SIZE: usize = 16;
const KEY_SIZE: usize = 32;

#[derive(Error, Debug, PartialEq, Eq)]
pub enum LegacyAesError {
    #[error("Unsupported password encoding: password must only contain ASCII characters")]
    UnsupportedPasswordEncoding,
    #[error("Invalid IV length: expected 16 bytes")]
    InvalidIV,
    #[error("Malformed ciphertext: invalid length or padding")]
    MalformedCiphertext,
    #[error("Decryption failed")]
    DecryptionFailed,
}

#[derive(Clone, Debug)]
pub struct LegacyAes {
    key: [u8; KEY_SIZE],
}

impl LegacyAes {
    pub fn new(password: &str) -> Result<Self, LegacyAesError> {
        if !password.bytes().all(|b| b < 128) {
            return Err(LegacyAesError::UnsupportedPasswordEncoding);
        }
        let key = Self::derive_key(password.as_bytes());
        Ok(Self { key })
    }

    pub fn derive_key(ascii_password: &[u8]) -> [u8; KEY_SIZE] {
        let mut hasher = Md5::new();
        hasher.update(ascii_password);
        let digest = hasher.finalize();

        // Original UltraViewer Init copies the second digest at offset 15, overlapping byte 15.
        let mut key = [0u8; KEY_SIZE];
        key[0..16].copy_from_slice(&digest);
        key[15..31].copy_from_slice(&digest);
        key
    }

    pub fn encrypt(&self, plaintext: &[u8]) -> Result<Vec<u8>, LegacyAesError> {
        let mut iv = [0u8; BLOCK_SIZE];
        rand::thread_rng().fill_bytes(&mut iv);
        self.encrypt_with_iv(plaintext, &iv)
    }

    pub fn encrypt_with_iv(&self, plaintext: &[u8], iv: &[u8; BLOCK_SIZE]) -> Result<Vec<u8>, LegacyAesError> {
        let cipher = Aes256CbcEnc::new(&self.key.into(), iv.into());
        let ciphertext = cipher.encrypt_padded_vec_mut::<Pkcs7>(plaintext);

        let mut output = Vec::with_capacity(BLOCK_SIZE + ciphertext.len());
        output.extend_from_slice(iv);
        output.extend_from_slice(&ciphertext);
        Ok(output)
    }

    pub fn decrypt(&self, payload: &[u8]) -> Result<Vec<u8>, LegacyAesError> {
        if payload.len() < 2 * BLOCK_SIZE || (payload.len() - BLOCK_SIZE) % BLOCK_SIZE != 0 {
            return Err(LegacyAesError::MalformedCiphertext);
        }

        let (iv, ciphertext) = payload.split_at(BLOCK_SIZE);
        let cipher = Aes256CbcDec::new(&self.key.into(), iv.into());
        
        cipher
            .decrypt_padded_vec_mut::<Pkcs7>(ciphertext)
            .map_err(|_| LegacyAesError::MalformedCiphertext)
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
    fn test_key_copy_overlap_matches_original_il() {
        let key = LegacyAes::derive_key(b"password");
        assert_eq!(
            key,
            hex("5f4dcc3b5aa765d61d8327deb882cf5f4dcc3b5aa765d61d8327deb882cf9900").as_slice()
        );
    }

    #[test]
    fn test_independent_openssl_vector() {
        let cipher = LegacyAes::new("password").unwrap();
        let plaintext = b"MacViewer protocol fixture";
        let mut iv = [0u8; 16];
        for i in 0..16 {
            iv[i] = i as u8;
        }

        let expected = hex("000102030405060708090a0b0c0d0e0f714d2fe102258f61487d3b4c2497b3400c219660f0ef67fecff4f5405ae21add");
        let encrypted = cipher.encrypt_with_iv(plaintext, &iv).unwrap();
        assert_eq!(encrypted, expected);

        let decrypted = cipher.decrypt(&expected).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_windows_library_generated_aes_fixture() {
        let cipher = LegacyAes::new("password").unwrap();
        let expected = hex("faa12d4ee98a5c7551b89ffc17b9b9bb68f46bb27a7a506df7533f7a06909bcd3eca1d95daf4532980a587df2543e244");
        let plaintext = b"MacViewer protocol fixture";

        let decrypted = cipher.decrypt(&expected).unwrap();
        assert_eq!(decrypted, plaintext);

        let mut iv = [0u8; 16];
        iv.copy_from_slice(&expected[..16]);
        let encrypted = cipher.encrypt_with_iv(plaintext, &iv).unwrap();
        assert_eq!(encrypted, expected);
    }

    #[test]
    fn test_fresh_iv_for_every_message() {
        let cipher = LegacyAes::new("fixture-only").unwrap();
        let plaintext = b"same plaintext";
        let first = cipher.encrypt(plaintext).unwrap();
        let second = cipher.encrypt(plaintext).unwrap();
        assert_ne!(&first[..16], &second[..16]);
        assert_eq!(cipher.decrypt(&first).unwrap(), plaintext);
        assert_eq!(cipher.decrypt(&second).unwrap(), plaintext);
    }

    #[test]
    fn test_rejects_unverified_encoding_and_malformed_ciphertext() {
        assert_eq!(
            LegacyAes::new("mật-khẩu").unwrap_err(),
            LegacyAesError::UnsupportedPasswordEncoding
        );

        let cipher = LegacyAes::new("fixture-only").unwrap();
        for length in [0, 1, 15, 16, 17, 31, 33] {
            let data = vec![0u8; length];
            assert_eq!(cipher.decrypt(&data).unwrap_err(), LegacyAesError::MalformedCiphertext);
        }

        let mut iv = [0u8; 16];
        for i in 0..16 {
            iv[i] = i as u8;
        }
        let mut corrupt = cipher.encrypt_with_iv(b"fixture", &iv).unwrap();
        corrupt[15] ^= 1;
        assert!(cipher.decrypt(&corrupt).is_err());
    }
}
