pub struct ModernScreenBitmap {
    pub width: usize,
    pub height: usize,
    pub pixels: Vec<u8>, // BGRA 32-bit (width * height * 4)
}

impl ModernScreenBitmap {
    pub fn new(width: usize, height: usize) -> Self {
        let size = width * height * 4;
        let mut pixels = vec![0u8; size];
        // Set alpha channel to 255 for opaque black
        for chunk in pixels.chunks_exact_mut(4) {
            chunk[3] = 255;
        }
        Self { width, height, pixels }
    }

    /// Blits a rectangular chunk (BGRA) onto the screen at (x, y)
    pub fn blit_rect(
        &mut self,
        rect_x: usize,
        rect_y: usize,
        rect_width: usize,
        rect_height: usize,
        rect_pixels: &[u8],
    ) {
        if rect_x + rect_width > self.width || rect_y + rect_height > self.height {
            return;
        }

        let stride = self.width * 4;
        let rect_stride = rect_width * 4;

        for row in 0..rect_height {
            let dest_offset = (rect_y + row) * stride + (rect_x * 4);
            let src_offset = row * rect_stride;

            let dest_slice = &mut self.pixels[dest_offset..dest_offset + rect_stride];
            let src_slice = &rect_pixels[src_offset..src_offset + rect_stride];
            dest_slice.copy_from_slice(src_slice);
        }
    }
}

pub struct ScreenPixelConverter {
    rgb555_to_bgra_table: Box<[u32; 32768]>,
}

impl Default for ScreenPixelConverter {
    fn default() -> Self {
        Self::new()
    }
}

impl ScreenPixelConverter {
    pub fn new() -> Self {
        let mut table = Box::new([0u32; 32768]);
        for value in 0..32768 {
            let blue = ((value & 31) << 3 | (value & 31) >> 2) as u32;
            let green5 = (value >> 5) & 31;
            let red5 = (value >> 10) & 31;
            let green = ((green5 << 3 | green5 >> 2) as u32) << 8;
            let red = ((red5 << 3 | red5 >> 2) as u32) << 16;
            table[value] = blue | green | red | 0xff00_0000;
        }
        Self { rgb555_to_bgra_table: table }
    }

    pub fn expand_rgb555_to_bgra(&self, source: &[u8], width: usize, height: usize) -> Vec<u8> {
        let pixel_count = width * height;
        let mut bgra = Vec::with_capacity(pixel_count * 4);

        for chunk in source.chunks_exact(2).take(pixel_count) {
            let val = u16::from_le_bytes([chunk[0], chunk[1]]) & 0x7fff;
            let bgra_pixel = self.rgb555_to_bgra_table[val as usize];
            bgra.extend_from_slice(&bgra_pixel.to_le_bytes());
        }

        bgra
    }

    pub fn bgr24_to_bgra32(source: &[u8], width: usize, height: usize) -> Vec<u8> {
        let pixel_count = width * height;
        let mut bgra = Vec::with_capacity(pixel_count * 4);

        for chunk in source.chunks_exact(3).take(pixel_count) {
            bgra.push(chunk[0]); // B
            bgra.push(chunk[1]); // G
            bgra.push(chunk[2]); // R
            bgra.push(255);      // A
        }

        bgra
    }

    pub fn bgra32_to_bgr24(source: &[u8], width: usize, height: usize) -> Vec<u8> {
        let pixel_count = width * height;
        let mut bgr = Vec::with_capacity(pixel_count * 3);

        for chunk in source.chunks_exact(4).take(pixel_count) {
            bgr.push(chunk[0]); // B
            bgr.push(chunk[1]); // G
            bgr.push(chunk[2]); // R
        }

        bgr
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pixel_conversions() {
        let converter = ScreenPixelConverter::new();
        // White RGB555: 0x7fff
        let white_555 = 0x7fffu16.to_le_bytes();
        let bgra = converter.expand_rgb555_to_bgra(&white_555, 1, 1);
        assert_eq!(bgra, vec![255, 255, 255, 255]);

        // Black RGB555: 0x0000
        let black_555 = 0x0000u16.to_le_bytes();
        let black_bgra = converter.expand_rgb555_to_bgra(&black_555, 1, 1);
        assert_eq!(black_bgra, vec![0, 0, 0, 255]);
    }

    #[test]
    fn test_bitmap_blitting() {
        let mut screen = ModernScreenBitmap::new(10, 10);
        let red_pixel = [0, 0, 255, 255]; // BGRA red
        let rect = red_pixel.repeat(4); // 2x2 red rect
        screen.blit_rect(1, 1, 2, 2, &rect);

        // Pixel at (1, 1) should be red
        let offset = (1 * 10 + 1) * 4;
        assert_eq!(&screen.pixels[offset..offset + 4], &[0, 0, 255, 255]);
    }
}
