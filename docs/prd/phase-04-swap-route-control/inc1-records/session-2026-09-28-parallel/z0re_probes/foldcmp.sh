#!/bin/bash
# foldcmp.sh <a.c> <b.c> : compile both at clang -O1 -include CQ.h and diff the function
# bodies (debug intrinsics dropped). Prints IDENTICAL or the diff.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
L=/usr/local/opt/llvm@19/bin
T=$(mktemp -d)
for x in 1 2; do
  src=$1; [ $x = 2 ] && src=$2
  "$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$src" -o "$T/$x.ll" || exit 1
  awk '/^define/{p=1} p{print} /^}/{p=0}' < "$T/$x.ll" | grep -v 'llvm.dbg' > "$T/$x.body"
done
if cmp -s "$T/1.body" "$T/2.body"; then echo "IDENTICAL: $(basename "$1") $(basename "$2")"; else echo "DIFFERENT: $(basename "$1") $(basename "$2")"; diff "$T/1.body" "$T/2.body"; fi
rm -rf "$T"
