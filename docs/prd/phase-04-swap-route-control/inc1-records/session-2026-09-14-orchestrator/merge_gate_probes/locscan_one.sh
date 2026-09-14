#!/bin/bash
# Diagnostic-LOCATION scan: for one module, print the SOURCE LOCATION field of
# the ORACLE's and the MERGED binary's diagnostic.  A row whose ORACLE location
# is a real file:line:col and whose MERGED location is <unknown>:0:0 (or :0:0)
# has LOST its !dbg — invisible to every other gate in this tree.
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
loc(){ "$1/build/ir-pass/cq-opt" -passes=cq-lowering -S "$T/s1.ll" -o /dev/null 2>"$T/e"
  if [ $? -eq 0 ]; then echo "ACCEPT"; else sed -nE 's/^error: (.*): in function .*/\1/p' "$T/e" | head -1; fi; }
echo "$f|$(loc "$ORC")|$(loc "$MRG")"
