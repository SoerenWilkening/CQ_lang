#!/bin/bash
# full.sh <file.c> — subject pipeline: lower, 2b, link, run
LLVM=/usr/local/opt/llvm@19/bin
SUBJ=/Users/sorenwilkening/Desktop/CQ_l4x4
ORC=/Users/sorenwilkening/Desktop/CQ_lang
F="$1"; B=$(basename "$F" .c); T=$(mktemp -d)
"$LLVM/clang" -I$ORC/include -include CQ.h -O1 -emit-llvm -S "$F" -o "$T/s1.ll" || exit 1
"$SUBJ/build/ir-pass/cq-opt" -load-pass-plugin "$SUBJ/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll"
echo "opt exit: $?"
echo "--- stderr ---"; cat "$T/s2.ll".err 2>/dev/null
[ -s "$T/s2.ll" ] || { rm -rf $T; exit 1; }
echo "--- stage 2b ---"
python3 $ORC/tools/free_pairing_check.py "$T/s2.ll"
echo "--- link+run ---"
"$LLVM/clang" "$T/s2.ll" $SUBJ/build/runtime/libcq_templates.a $SUBJ/build/runtime/libcq_runtime.a -o "$T/a" 2>/dev/null && "$T/a"
echo "--- (rc=$?) ---"
cp "$T/s1.ll" /tmp/last_s1.ll; cp "$T/s2.ll" /tmp/last_s2.ll
rm -rf $T
