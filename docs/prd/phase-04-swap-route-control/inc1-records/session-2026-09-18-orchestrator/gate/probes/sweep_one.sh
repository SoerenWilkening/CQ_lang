#!/bin/bash
# sweep_one.sh <absfile> <relpath>  -> one row on stdout
# Row: relpath|O:<exit>:<A|D>:<md5|FULLERRLINE>:<stderr-sha8>|S:...
#
# Records the FULL first `error:` line, NOT the shared corpus.sh tag regex, and ALSO a
# sha of the whole stderr -- so a decline->decline STRING change (invisible to the tag
# regex inside the cq_measure_<sfx> family, PROTOCOL S3) shows up here.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/Projects/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ac2acfdde3461becc
f="$1"; rel="$2"
T=$(mktemp -d) || exit 1
trap 'rm -rf "$T"' EXIT

if [[ "$f" == *.c ]]; then
  base=$(basename "$f"); dir=$(dirname "$f")
  case "$base" in
    *_lib.c|lib*.c) exit 0 ;;
  esac
  if [[ "$base" == *_caller.c ]]; then
    stem=${base%_caller.c}
    libf="$dir/${stem}_lib.c"
    [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null | head -1)
    "$LLVM/clang" -I"$ORC/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR|CLANGERR"; exit 0; }
    if [ -n "$libf" ] && [ -f "$libf" ]; then
      "$LLVM/clang" -I"$ORC/include" -O1 -g -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null \
        && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp "$T/a.ll" "$T/s1.ll"
    else
      cp "$T/a.ll" "$T/s1.ll"
    fi
  else
    "$LLVM/clang" -I"$ORC/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR|CLANGERR"; exit 0; }
  fi
else
  cp "$f" "$T/s1.ll"
fi

# a 0-body module ACCEPTS through the passthrough early-out -- mark it, never score it
if ! grep -qE '^[[:space:]]*(define|declare|@)' "$T/s1.ll" 2>/dev/null; then
  echo "$rel|EMPTYMOD|EMPTYMOD"; exit 0
fi

v() {
  local root=$1 tag=$2
  "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
  local rc=$?
  local esha
  esha=$(shasum -a 256 "$T/$tag.err" | cut -c1-8)
  if [ $rc -eq 0 ]; then
    echo "$rc:A:$(md5 -q "$T/$tag.ll" | cut -c1-12):$esha"
  else
    local line
    line=$(grep -m1 'error:' "$T/$tag.err" | tr -s ' \t' ' ' | sed 's/^ *//;s/ *$//' | cut -c1-200)
    [ -z "$line" ] && line="<no-error-line rc=$rc>"
    echo "$rc:D:$line:$esha"
  fi
}
echo "$rel|O:$(v "$ORC" o)|S:$(v "$SUBJ" s)"
