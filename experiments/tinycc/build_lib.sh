#!/bin/sh
# build_lib.sh: TinyCC lowered as one library, ../lib/libqtinycc.a: its exported functions (the libtcc API and the
# error helpers, build/tinycc.roots) are the roots, each exported once per argument arrangement; every other function
# is static in the ONE_SOURCE build and is lowered where a root reaches it. Input: build.sh's build/linked.ll. Calls
# into libc stay calls of the lowered C library's clones (--cq-ext-roots). Also builds the native archive
# build/libtinycc.a, linked after the lowered one (rule 27), with TinyCC's main renamed tcc_main so a program brings
# its own main.
set -eu
cd "$(dirname "$0")"
L=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
grep -E '^define ' build/linked.ll | grep -v -E '^define (internal|private|linkonce|weak)' |
    sed -E 's/^define [^@]*@"?([A-Za-z0-9_.$]+)"?\(.*/\1/' | grep -v '^main$' | sort -u > build/tinycc.roots
sed 's/@main(/@tcc_main(/' build/linked.ll | "$L/clang" -O1 -c -x ir - -o build/tinycc.o
rm -f build/libtinycc.a; ar rcs build/libtinycc.a build/tinycc.o
time ../../driver/cqcc --cq-lib --cq-roots build/tinycc.roots --cq-ext-roots ../lib/libc.roots build/linked.ll \
    --save-temps build/lib -o ../lib/libqtinycc.tmp.a
mv ../lib/libqtinycc.tmp.a ../lib/libqtinycc.a
ls -la ../lib/libqtinycc.a build/libtinycc.a
