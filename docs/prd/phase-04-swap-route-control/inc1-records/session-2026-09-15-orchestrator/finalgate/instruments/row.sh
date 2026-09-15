#!/bin/bash
# row.sh <file> — one corpus row, ORACLE vs SUBJECT, FULL-STDERR hashed.
# Row format: <relpath>|<oracle verdict>|<subject verdict>
#   verdict = A:<md5-8 of lowered IR>            (exit 0)
#           = D:<exit>:<sha256-12 of FULL stderr> (exit != 0)
#           = X:<exit>                            (127 / harness failure)
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_VERIFY
f="$1"
rel="${f#$SUBJ/}"
TD=$(mktemp -d) || { echo "$rel|X:MKTEMP|X:MKTEMP"; exit 0; }
trap 'rm -rf "$TD"' EXIT
if [[ "$f" == *.c ]]; then
  base=$(basename "$f"); dir=$(dirname "$f")
  if [[ "$base" == *_lib.c || "$base" == lib*.c ]]; then exit 0; fi
  if [[ "$base" == *_caller.c ]]; then
    stem=${base%_caller.c}
    libf="$dir/${stem}_lib.c"; [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null | head -1)
    "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$TD/a.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR|CLANGERR"; exit 0; }
    if [ -n "$libf" ] && [ -f "$libf" ]; then
      "$LLVM/clang" -I$SUBJ/include -O1 -g -emit-llvm -S "$libf" -o "$TD/b.ll" 2>/dev/null \
        && "$LLVM/llvm-link" -S "$TD/a.ll" "$TD/b.ll" -o "$TD/s1.ll" 2>/dev/null || cp "$TD/a.ll" "$TD/s1.ll"
    else cp "$TD/a.ll" "$TD/s1.ll"; fi
  else
    "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$TD/s1.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR|CLANGERR"; exit 0; }
  fi
else
  cp "$f" "$TD/s1.ll"
fi
# ANTI-VACUITY: a 0-byte module ACCEPTS through the passthrough early-out.
if [ ! -s "$TD/s1.ll" ]; then echo "$rel|EMPTY|EMPTY"; exit 0; fi
v() {
  local root=$1 tag=$2
  "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$TD/s1.ll" -o "$TD/$tag.ll" 2>"$TD/$tag.err"
  local e=$?
  if [ $e -eq 0 ]; then
    printf 'A:%s' "$(md5 -q "$TD/$tag.ll" | cut -c1-8)"
  elif [ $e -eq 127 ] || [ $e -eq 126 ]; then
    printf 'X:%s' "$e"
  else
    printf 'D:%s:%s' "$e" "$(shasum -a 256 "$TD/$tag.err" | cut -c1-12)"
  fi
}
echo "$rel|$(v $ORC o)|$(v $SUBJ s)"
