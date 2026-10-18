use std::path::PathBuf;

fn main() {
    let manifest_dir = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());

    // Build G.722
    let g722_dir = manifest_dir.join("c_src/g722");
    cc::Build::new()
        .include(g722_dir.join("include"))
        .file(g722_dir.join("g722_decode.c"))
        .file(g722_dir.join("MacViewerG722.c"))
        .compile("g722");

    // Build Zstandard with legacy v0.4-v0.7 support
    let zstd_dir = manifest_dir.join("c_src/zstd");
    let zstd_sources = [
        "lib/common/debug.c", "lib/common/entropy_common.c",
        "lib/common/error_private.c", "lib/common/fse_decompress.c",
        "lib/common/pool.c", "lib/common/threading.c",
        "lib/common/xxhash.c", "lib/common/zstd_common.c",
        "lib/compress/fse_compress.c", "lib/compress/hist.c",
        "lib/compress/huf_compress.c", "lib/compress/zstd_compress.c",
        "lib/compress/zstd_compress_literals.c", "lib/compress/zstd_compress_sequences.c",
        "lib/compress/zstd_compress_superblock.c", "lib/compress/zstd_double_fast.c",
        "lib/compress/zstd_fast.c", "lib/compress/zstd_lazy.c",
        "lib/compress/zstd_ldm.c", "lib/compress/zstd_opt.c",
        "lib/compress/zstd_preSplit.c", "lib/compress/zstdmt_compress.c",
        "lib/decompress/huf_decompress.c", "lib/decompress/zstd_ddict.c",
        "lib/decompress/zstd_decompress.c", "lib/decompress/zstd_decompress_block.c",
        "lib/legacy/zstd_v04.c", "lib/legacy/zstd_v05.c",
        "lib/legacy/zstd_v06.c", "lib/legacy/zstd_v07.c",
    ];

    let mut zstd_build = cc::Build::new();
    zstd_build
        .include(zstd_dir.join("include"))
        .include(zstd_dir.join("lib/common"))
        .define("ZSTD_LEGACY_SUPPORT", "4")
        .define("ZSTD_DISABLE_ASM", "1");

    for src in zstd_sources {
        zstd_build.file(zstd_dir.join(src));
    }
    zstd_build.compile("zstd");

    println!("cargo:rerun-if-changed=c_src/g722");
    println!("cargo:rerun-if-changed=c_src/zstd");
}
