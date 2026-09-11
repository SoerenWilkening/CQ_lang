#!/bin/bash
# r903 scoping harness — READ-ONLY probes against main @0c7380c.
REPO=/Users/sorenwilkening/Desktop/CQ_lang
LLVM=/usr/local/opt/llvm@19/bin
SP="$(cd "$(dirname "$0")" && pwd)"
f="$1"
b=$(basename "$f" .c)
out="$SP/out"; mkdir -p "$out"
"$LLVM/clang" -I$REPO/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$out/$b.s1.ll" 2> "$out/$b.cc.err" || { echo "$b CLANG-FAIL"; sed -n 1,3p "$out/$b.cc.err"; exit 0; }
brs=$(grep -c 'br i1' "$out/$b.s1.ll")
sel=$(grep -c ' = select i1' "$out/$b.s1.ll")
if "$REPO/build/ir-pass/cq-opt" -load-pass-plugin "$REPO/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$out/$b.s1.ll" -o "$out/$b.s2.ll" 2> "$out/$b.err"; then
  echo "$b | br=$brs sel=$sel | EXIT0 | $(grep -c 'call' "$out/$b.s2.ll") calls"
else
  echo "$b | br=$brs sel=$sel | DECLINE | $(grep -o 'cq [a-z ]*lowering: [^\"]*' "$out/$b.err" | head -1)"
fi
