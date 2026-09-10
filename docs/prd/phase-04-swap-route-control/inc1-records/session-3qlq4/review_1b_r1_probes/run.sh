#!/bin/bash
# usage: ./run.sh file.c   -> prints stage1 decline/accept + trace
R=/Users/sorenwilkening/Desktop/CQ_lang
LLVM=/usr/local/opt/llvm@19/bin
f="$1"; b=$(basename "$f" .c)
d=$(mktemp -d)
$LLVM/clang -I $R/include -include CQ.h -O1 -emit-llvm -S "$f" -o $d/s1.ll 2>$d/c.err || { echo "CLANG-FAIL"; cat $d/c.err; exit 1; }
$LLVM/opt -load-pass-plugin $R/build/ir-pass/libCQPass.so -passes=cq-lowering -S $d/s1.ll -o $d/s2.ll 2>$d/o.err
rc=$?
if [ $rc -ne 0 ]; then echo "DECLINE(rc=$rc): $(grep -o 'error: .*' $d/o.err | head -3)"; rm -rf $d; exit 0; fi
echo "ACCEPT"
if grep -qE '@cq_theta|@cq_phi|@cq_measure' $d/s2.ll; then echo "!!! SURVIVING cq_* INTRINSIC:"; grep -nE 'call.*@cq_(theta|phi|measure)' $d/s2.ll | head; fi
python3 $R/tools/free_pairing_check.py $d/s2.ll > $d/fp.out 2>&1 || echo "STAGE2B-FAIL: $(cat $d/fp.out|head -5)"
$LLVM/clang $d/s2.ll $R/build/runtime/libcq_templates.a $R/build/runtime/libcq_runtime.a -o $d/a 2>$d/l.err || { echo "LINK-FAIL"; head -5 $d/l.err; cp $d/s2.ll ./$b.s2.ll; rm -rf $d; exit 1; }
$d/a
cp $d/s2.ll ./$b.s2.ll; cp $d/s1.ll ./$b.s1.ll
rm -rf $d
