#!/bin/bash
# corpus_one.sh — ONE corpus row, so corpus_x.sh can be driven by `xargs -P`.
# Same recipe as corpus_x.sh; see that file's header for the three corrections
# it makes to the 2026-09-11 shared script. Arguments come from the environment
# (ORC, SUBJ) plus the file path as $1; the row goes to stdout.
set -u
LLVM=${LLVM:-/usr/local/opt/llvm@19/bin}
f=$1
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
rel=${f#"$SUBJ"/}

case "$f" in
  *.c)
    base=$(basename "$f")
    case "$base" in
      *_lib.c|lib*.c) exit 0 ;;
    esac
    "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR|CLANGERR"; exit 0; } ;;
  *) cp -f "$f" "$T/s1.ll" ;;
esac

# (V0) a 0-byte / bodyless module ACCEPTS through the passthrough early-out.
if ! grep -q '^define' "$T/s1.ll" 2>/dev/null; then
  echo "$rel|NOBODY|NOBODY"; exit 0
fi

v() { # $1 = repo root, $2 = tag
  "$1/build/ir-pass/cq-opt" -load-pass-plugin "$1/build/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$T/s1.ll" -o "$T/$2.ll" 2>"$T/$2.err"
  if [ $? -eq 0 ]; then
    echo "A:$(md5 -q "$T/$2.ll" | cut -c1-8)"
  else
    echo "D:$(grep -m1 '^error:' "$T/$2.err" | sed -E 's#^error: [^ ]*: ##' | cut -c1-140)"
  fi
}

echo "$rel|$(v "$ORC" o)|$(v "$SUBJ" s)"
