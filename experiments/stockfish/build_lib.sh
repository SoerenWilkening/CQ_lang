#!/bin/sh
# build_lib.sh: Stockfish lowered as one library, build/libqsf.a: its externally visible functions (build/sf.roots) are the
# roots; the inline and template functions are lowered where a root reaches them. Input: build.sh's build/linked.ll.
# Calls into libc stay calls of the lowered C library's clones (--cq-ext-roots). Also builds the native archive
# build/libsf.a, linked after the lowered one (rule 27), with Stockfish's main renamed sf_main.
set -eu
cd "$(dirname "$0")"
L=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
grep -E '^define ' build/linked.ll | grep -v -E '^define (internal|private|linkonce|weak)' |
    sed -E 's/^define [^@]*@"?([A-Za-z0-9_.$]+)"?\(.*/\1/' | grep -v '^main$' | sort -u > build/sf.roots
sed 's/@main(/@sf_main(/' build/linked.ll | "$L/clang" -O1 -c -x ir - -o build/sf.o
rm -f build/libsf.a; ar rcs build/libsf.a build/sf.o
time ../../driver/cqcc --cq-lib --cq-roots build/sf.roots --cq-ext-roots ../lib/libc.roots build/linked.ll \
    --save-temps build/lib -o build/libqsf.tmp.a
mv build/libqsf.tmp.a build/libqsf.a
ls -la build/libqsf.a build/libsf.a
