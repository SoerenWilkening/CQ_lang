#!/bin/sh
# Compiler wrapper for GMP's own build: compiles as asked and, for each C file compiled to an object, also writes the
# unit as -O1 LLVM IR with CQ.h included (what cqcc's first step does) into $CQ_IR_DIR, named after the object.
CLANG=/usr/local/opt/llvm@19/bin/clang
"$CLANG" "$@" || exit $?
out=""; src=""; c=0; prev=""
for a in "$@"; do
    [ "$prev" = "-o" ] && out=$a
    case $a in -c) c=1;; *.c) src=$a;; esac
    prev=$a
done
[ $c = 1 ] && [ -n "$src" ] && [ -n "$out" ] || exit 0
case $out in *.o|*.lo) ;; *) exit 0;; esac
args=""
for a in "$@"; do case $a in -c|-o|"$out"|-O*|-M*|-g*|-fPIC|-DPIC) ;; *) args="$args '$a'";; esac; done
n=$(printf %s "$PWD/$out" | cksum | cut -d' ' -f1)
eval "$CLANG" -O1 -S -emit-llvm -target x86_64-apple-macosx -include "$CQ_H" -w $args -o "$CQ_IR_DIR/$n.ll" 2>/dev/null
exit 0
