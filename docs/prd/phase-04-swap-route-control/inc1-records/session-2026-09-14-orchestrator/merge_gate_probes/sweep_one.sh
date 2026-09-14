#!/bin/bash
# One corpus row.  A row is: rel | ORACLE verdict | MERGED verdict | STDERR-EQ
# ORACLE = /Users/sorenwilkening/Desktop/CQ_lang/build (frozen, read-only)
# MERGED = /Users/sorenwilkening/Desktop/CQ_merge/build
# Verdict: "A:<md5 of lowered IR, 8>" on exit 0, else "D:<first cq diagnostic>".
# STDERR-EQ closes PROTOCOL S3's blind spot (the cq_measure_<sfx> family renders
# as an empty tag under the shared regex): it byte-compares the FULL stderr of
# the two binaries, so a decline->decline STRING or LOCATION change is visible.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
MRG=/Users/sorenwilkening/Desktop/CQ_merge
f="$1"; rel="$f"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$MRG" || exit 1
if [[ "$f" == *.c ]]; then
  base=$(basename "$f"); dir=$(dirname "$f")
  case "$base" in
    *_lib.c|lib*.c) exit 0 ;;
  esac
  "$LLVM/clang" -I"$MRG/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR|-"; exit 0; }
  stem="${base%.c}"; libf=""
  [ -f "$dir/${stem%_caller}_lib.c" ] && libf="$dir/${stem%_caller}_lib.c"
  [ -z "$libf" ] && [ -f "$dir/${stem}_lib.c" ] && libf="$dir/${stem}_lib.c"
  if [ -n "$libf" ]; then
    "$LLVM/clang" -I"$MRG/include" -O1 -g -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null &&
      "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp "$T/a.ll" "$T/s1.ll"
  else cp "$T/a.ll" "$T/s1.ll"; fi
else
  cp "$f" "$T/s1.ll" 2>/dev/null || { echo "$rel|READERR|READERR|-"; exit 0; }
fi
v(){ local root=$1 tag=$2
  "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
  if [ $? -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll" | cut -c1-8)"
  else echo "D:$(grep -oE 'cq [a-z0-9 ]+: [^\"]+' "$T/$tag.err" | head -1 | sed 's/ under quantum control//' | cut -c1-80)"; fi; }
O=$(v "$ORC" o); M=$(v "$MRG" m)
if cmp -s "$T/o.err" "$T/m.err"; then E="STDERR-EQ"; else E="STDERR-DIFF"; fi
echo "$rel|$O|$M|$E"
