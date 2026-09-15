#!/bin/bash
# usage: full.sh <tag> <file.c> ; full pipeline stage1->2->2b->3->run
LLVM=/usr/local/opt/llvm@19/bin
ORACLE=/Users/sorenwilkening/Desktop/CQ_lang/build
SUBJECT=/Users/sorenwilkening/Desktop/CQ_E2/build
case "$1" in oracle) B=$ORACLE;; subject) B=$SUBJECT;; esac
D=$(mktemp -d); N=$(basename "$2" .c)
"$LLVM/clang" -I/Users/sorenwilkening/Desktop/CQ_lang/include -include CQ.h -O1 -emit-llvm -S "$2" -o "$D/s1.ll" 2>/dev/null || { echo "$N CLANGERR"; exit 8; }
"$B/ir-pass/cq-opt" -load-pass-plugin "$B/ir-pass/libCQPass.so" -passes=cq-lowering -S "$D/s1.ll" -o "$D/s2.ll" 2>"$D/e" || { echo "$N DECLINE: $(head -c 120 $D/e)"; exit 1; }
FP=$(python3 /Users/sorenwilkening/Desktop/CQ_lang/tools/free_pairing_check.py "$D/s2.ll" 2>&1 | tail -1)
"$LLVM/clang" "$D/s2.ll" "$ORACLE/runtime/libcq_templates.a" "$ORACLE/runtime/libcq_runtime.a" -o "$D/a" 2>"$D/le" || { echo "$N LINKERR: $(head -c 200 $D/le)"; exit 7; }
"$D/a" > "$D/trace" 2>&1; RC=$?
echo "$N | ret=$RC | 2b: $FP | trace-sha=$(shasum -a 256 < $D/trace | cut -c1-16) | lines=$(wc -l < $D/trace)"
cat "$D/trace" | sed 's/^/    /'
