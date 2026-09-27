#!/bin/bash
# usage: gm_one.sh BIN FILE OUTDIR  -> prints "base rc"
BIN=$1; F=$2; OUT=$3
b=$(basename "$F" .ll)
DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib "$BIN" -passes=cq-lowering -S "$F" -o "$OUT/$b.ll" > "$OUT/$b.err" 2>&1
rc=$?
printf '%s\t%s\n' "$b" "$rc"
