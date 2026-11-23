#!/bin/zsh
# build_std.sh <dir>: Rust 1.86.0 into <dir>/rustup (nothing of the user's own toolchains is touched) and its std built from source
# with panic=abort and every panic an immediate abort (the analogue of the musl bundle), as bitcode rlibs in <dir>/deps.
set -e
S=${1:a}; export RUSTUP_HOME=$S/rustup CARGO_HOME=$S/cargo RUSTC_BOOTSTRAP=1
mkdir -p $CARGO_HOME $S/cqstd/src
rustup toolchain install 1.86.0 --profile minimal -c rust-src --no-self-update
B=$S/rustup/toolchains/1.86.0-x86_64-apple-darwin/bin
cat > $S/cqstd/Cargo.toml <<'T'
[package]
name = "cqstd"
version = "0.1.0"
edition = "2021"
[lib]
crate-type = ["staticlib"]
[profile.release]
opt-level = 1
panic = "abort"
codegen-units = 1
[workspace]
T
echo > $S/cqstd/src/lib.rs; cd $S/cqstd
PATH=$B:$PATH cargo build --release -Zbuild-std=std,panic_abort -Zbuild-std-features=panic_immediate_abort --target x86_64-apple-darwin
ln -sfn $S/cqstd/target/x86_64-apple-darwin/release/deps $S/deps
