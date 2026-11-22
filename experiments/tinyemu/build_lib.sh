#!/bin/sh
# build_lib.sh: TinyEMU lowered as four libraries, ../lib/libqtinyemu_<group>.a, with every exported function a
# root (300 functions; each exported once per argument arrangement). LIBS="cpu64" builds only those named. Its input is the IR of
# build.sh (run that first); calls into libc stay calls of the lowered C library's clones (--cq-ext-roots).
# Also builds the native archive build/libtinyemu.a that a program links after the lowered one (rule 27).
set -eu
cd "$(dirname "$0")"
L=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
# One lowered library per group, built one at a time: the three RISC-V CPU units (the interpreters need up to 5 GB
# each) and the rest. A group's roots are the exported functions its units define; the other groups' roots and
# libc's are --cq-ext-roots, so a call across groups is a call of that library's clone.
mkdir -p build/native build/roots
# TinyEMU's main (temu.c) is renamed temu_main in the native archive and is no root, so a program brings its own main.
for f in build/ir/*.ll; do sed 's/@main(/@temu_main(/' "$f" | "$L/clang" -O1 -c -x ir - -o "build/native/$(basename "$f" .ll).o"; done
rm -f build/libtinyemu.a; ar rcs build/libtinyemu.a build/native/*.o
exported() { cat "$@" | grep -E '^define ' | grep -v -E '^define (internal|private|linkonce|weak)' |
    sed -E 's/^define [^@]*@"?([A-Za-z0-9_.$]+)"?\(.*/\1/' | grep -v '^main$' | sort -u; }
units() { case $1 in cpu32|cpu64|cpu128) echo build/ir/riscv_$1.ll;;
    rest) ls build/ir/*.ll | grep -v riscv_cpu;; esac; }
for g in cpu32 cpu64 cpu128 rest; do exported $(units $g) > build/roots/$g.roots; done
for g in ${LIBS:-cpu32 cpu64 cpu128 rest}; do
    [ -s ../lib/libqtinyemu_$g.a ] && continue
    cat $(ls build/roots/*.roots | grep -v "/$g.roots") > build/roots/$g.ext
    echo "== $g $(wc -l < build/roots/$g.roots) roots $(date +%H:%M:%S)"
    time ../../driver/cqcc --cq-lib --cq-roots build/roots/$g.roots --cq-ext-roots ../lib/libc.roots \
        --cq-ext-roots build/roots/$g.ext $(units $g) --save-temps build/lib_$g -o ../lib/libqtinyemu_$g.tmp.a
    mv ../lib/libqtinyemu_$g.tmp.a ../lib/libqtinyemu_$g.a
done
ls -la ../lib/libqtinyemu_*.a build/libtinyemu.a
