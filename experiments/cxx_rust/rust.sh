#!/bin/zsh
# rust.sh <x.rs> <out.ll>: rustc 1.86.0 (the release line on LLVM 19.1.7, the pass's LLVM), opt-level 1, fat LTO: the parts of
# core/alloc/std a program uses are in its one module. CQ_RUST is build_std.sh's directory. STOCK=1: the shipped std (panics
# unwind and print) instead of the immediate-abort one. OVF=on: overflow checks.
set -e
L=/usr/local/opt/llvm@19/bin; D=$CQ_RUST/deps; R=$CQ_RUST/rustup/toolchains/1.86.0-x86_64-apple-darwin/bin/rustc
export RUSTC_BOOTSTRAP=1
if [ -z "$STOCK" ]; then
  x=(-C panic=abort -Z unstable-options -L dependency=$D)
  for l in core alloc std compiler_builtins panic_abort; do x+=(--extern noprelude:$l=$(ls $D/lib$l-*.rlib)); done
else x=(-C panic=unwind); fi
$R --edition 2021 --crate-type=staticlib --target x86_64-apple-darwin -C opt-level=1 -C lto=fat -C codegen-units=1 \
  -C overflow-checks=${OVF:-off} $x --emit=llvm-bc $1 -o $2.bc
# std's exported symbols go; value names go (the checker's IR rewriting wants clang's numbering); rustc has no spelling for CQ.h's nomerge / noduplicate; the checker wants the corpus triple.
$L/opt -S --discard-value-names -passes=internalize,globaldce -internalize-public-api-list=f $2.bc -o $2; rm $2.bc
sed -i '' -E 's/^target triple = .*/target triple = "x86_64-apple-macosx10.15.0"/; s/^(declare .*@cq_theta_[a-z0-9]+\([^)]*\)[^#]*)/\1 nomerge /; s/^(declare .*@__cq_invert_(begin|end)\(\)[^#]*)/\1 noduplicate /' $2
