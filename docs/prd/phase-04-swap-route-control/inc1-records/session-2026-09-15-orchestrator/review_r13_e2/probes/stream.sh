#!/bin/bash
# usage: stream.sh <tag> <file.c>  -> prints emitted runtime-call stream + non-dbg body hash
LLVM=/usr/local/opt/llvm@19/bin
ORACLE=/Users/sorenwilkening/Desktop/CQ_lang/build
SUBJECT=/Users/sorenwilkening/Desktop/CQ_E2/build
case "$1" in oracle) B=$ORACLE;; subject) B=$SUBJECT;; esac
D=$(mktemp -d)
"$LLVM/clang" -I/Users/sorenwilkening/Desktop/CQ_lang/include -include CQ.h -O1 -emit-llvm -S "$2" -o "$D/s1.ll" 2>/dev/null || exit 8
"$B/ir-pass/cq-opt" -load-pass-plugin "$B/ir-pass/libCQPass.so" -passes=cq-lowering -S "$D/s1.ll" -o "$D/s2.ll" 2>/dev/null || { echo "DECLINE"; exit 1; }
grep -oE 'call [^ ]+ @(cqrt_|cq_template_)[A-Za-z0-9_]+\([^)]*\)' "$D/s2.ll" | sed -E 's/ *![a-z]+ ![0-9]+//g'
