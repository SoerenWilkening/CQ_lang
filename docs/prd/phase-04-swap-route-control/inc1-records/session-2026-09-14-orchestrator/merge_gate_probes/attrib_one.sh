#!/bin/bash
# Attribute ONE corpus mover to a track: run it on the ORACLE, on each of the
# five single-track binaries (Track T has no pass source, so its binary IS the
# ORACLE and is omitted), and on the MERGED binary.  Prints one row:
#   rel | ORACLE | U | F | P | W | D | MERGED
# A mover whose MERGED verdict is reproduced by exactly one single-track binary
# is attributed to that track; one reproduced by NONE is a COMPOSITION and, per
# the merge brief, a FINDING.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
MRG=/Users/sorenwilkening/Desktop/CQ_merge
f="$1"; T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$MRG" || exit 1
if [[ "$f" == *.c ]]; then
  base=$(basename "$f"); dir=$(dirname "$f"); stem="${base%.c}"
  case "$base" in *_lib.c|lib*.c) exit 0 ;; esac
  "$LLVM/clang" -I"$MRG/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null || exit 0
  libf=""; [ -f "$dir/${stem%_caller}_lib.c" ] && libf="$dir/${stem%_caller}_lib.c"
  [ -z "$libf" ] && [ -f "$dir/${stem}_lib.c" ] && libf="$dir/${stem}_lib.c"
  if [ -n "$libf" ]; then "$LLVM/clang" -I"$MRG/include" -O1 -g -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp "$T/a.ll" "$T/s1.ll"; else cp "$T/a.ll" "$T/s1.ll"; fi
else cp "$f" "$T/s1.ll" 2>/dev/null || exit 0; fi
v(){ "$1/build/ir-pass/cq-opt" -passes=cq-lowering -S "$T/s1.ll" -o "$T/x.ll" 2>"$T/x.err"
  if [ $? -eq 0 ]; then echo "A:$(md5 -q "$T/x.ll"|cut -c1-8)"
  else echo "D:$(grep -oE 'cq [a-z0-9 ]+: [^\"]+' "$T/x.err"|head -1|sed 's/ under quantum control//'|cut -c1-48)"; fi; }
echo "$f|$(v $ORC)|$(v /Users/sorenwilkening/Desktop/CQ_undef)|$(v /Users/sorenwilkening/Desktop/CQ_f2phi)|$(v /Users/sorenwilkening/Desktop/CQ_phiphase)|$(v /Users/sorenwilkening/Desktop/CQ_wx8g)|$(v /Users/sorenwilkening/Desktop/CQ_3d8q)|$(v $MRG)"
