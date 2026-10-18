use thiserror::Error;

#[derive(Clone, Debug)]
pub struct MultipartLimits {
    pub maximum_payload_length: usize,
    pub maximum_part_length: usize,
    pub maximum_part_count: usize,
}

impl Default for MultipartLimits {
    fn default() -> Self {
        Self {
            maximum_payload_length: 16 * 1024 * 1024,
            maximum_part_length: 16 * 1024 * 1024,
            maximum_part_count: 4096,
        }
    }
}

#[derive(Error, Debug, PartialEq, Eq)]
pub enum MultipartError {
    #[error("Empty payload")]
    EmptyPayload,
    #[error("Payload exceeds maximum permitted size")]
    PayloadTooLarge,
    #[error("Part exceeds maximum permitted size")]
    PartTooLarge,
    #[error("Too many parts in payload")]
    TooManyParts,
    #[error("Invalid part length")]
    InvalidLength,
    #[error("Truncated part length")]
    TruncatedLength,
    #[error("Truncated part data")]
    TruncatedPart,
}

pub struct MultipartPayload;

impl MultipartPayload {
    pub fn encode(parts: &[&[u8]], limits: &MultipartLimits) -> Result<Vec<u8>, MultipartError> {
        if parts.is_empty() {
            return Err(MultipartError::EmptyPayload);
        }
        if parts.len() > limits.maximum_part_count {
            return Err(MultipartError::TooManyParts);
        }

        let mut total_length: usize = 0;
        for part in parts {
            if part.len() > limits.maximum_part_length {
                return Err(MultipartError::PartTooLarge);
            }
            total_length = total_length
                .checked_add(4)
                .and_then(|l| l.checked_add(part.len()))
                .ok_or(MultipartError::PayloadTooLarge)?;

            if total_length > limits.maximum_payload_length {
                return Err(MultipartError::PayloadTooLarge);
            }
        }

        let mut result = Vec::with_capacity(total_length);
        for part in parts {
            let len = part.len() as u32;
            result.extend_from_slice(&len.to_le_bytes());
            result.extend_from_slice(part);
        }

        Ok(result)
    }

    pub fn decode(payload: &[u8], limits: &MultipartLimits) -> Result<Vec<Vec<u8>>, MultipartError> {
        if payload.is_empty() {
            return Err(MultipartError::EmptyPayload);
        }
        if payload.len() > limits.maximum_payload_length {
            return Err(MultipartError::PayloadTooLarge);
        }

        let mut parts = Vec::new();
        let mut cursor = 0;

        while cursor < payload.len() {
            if parts.len() >= limits.maximum_part_count {
                return Err(MultipartError::TooManyParts);
            }
            if payload.len() - cursor < 4 {
                return Err(MultipartError::TruncatedLength);
            }

            let length = u32::from_le_bytes([
                payload[cursor],
                payload[cursor + 1],
                payload[cursor + 2],
                payload[cursor + 3],
            ]);
            cursor += 4;

            if length > i32::MAX as u32 {
                return Err(MultipartError::InvalidLength);
            }

            let part_len = length as usize;
            if part_len > limits.maximum_part_length {
                return Err(MultipartError::PartTooLarge);
            }
            if part_len > payload.len() - cursor {
                return Err(MultipartError::TruncatedPart);
            }

            parts.push(payload[cursor..cursor + part_len].to_vec());
            cursor += part_len;
        }

        Ok(parts)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encode_and_decode_parts() {
        let limits = MultipartLimits::default();
        let part1 = b"Part 1 Data";
        let part2 = b"";
        let part3 = b"Part 3 with more data";

        let encoded = MultipartPayload::encode(&[part1, part2, part3], &limits).unwrap();
        let decoded = MultipartPayload::decode(&encoded, &limits).unwrap();

        assert_eq!(decoded.len(), 3);
        assert_eq!(decoded[0], part1);
        assert_eq!(decoded[1], part2);
        assert_eq!(decoded[2], part3);
    }
}
