#!/bin/bash
# rm2.sh <main.c> <lib.c> [binary]
R=/Users/sorenwilkening/Desktop/CQ_lang
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/399370cc-11ea-43ff-bc2d-6a55cc78fdb2/scratchpad/review_1b_r2
LLVM=/usr/local/opt/llvm@19/bin; BIN=${3:-$R/build/ir-pass/cq-opt}
b=$(basename "$1" .c); o=$SP/out
$LLVM/clang -I $R/include -include CQ.h -O1 -emit-llvm -c "$1" -o $o/$b.a.bc 2>$o/$b.cerr || { echo CLANGFAIL; head -3 $o/$b.cerr; exit 1; }
$LLVM/clang -O1 -emit-llvm -c "$2" -o $o/$b.b.bc 2>>$o/$b.cerr || { echo CLANGFAIL2; exit 1; }
$LLVM/llvm-link $o/$b.a.bc $o/$b.b.bc -S -o $o/$b.s1.ll
$BIN -passes=cq-lowering -S $o/$b.s1.ll -o $o/$b.s2.ll 2>$o/$b.err; rc=$?
if [ $rc -ne 0 ]; then echo "DECLINE(rc=$rc): $(grep -o 'error: .*' $o/$b.err|head -2|tr '\n' ' | ')"; exit 0; fi
echo ACCEPT
grep -qE '@cq_theta|@cq_phi|@cq_measure' $o/$b.s2.ll && echo "!!! SURVIVING cq_*"
python3 $R/tools/free_pairing_check.py $o/$b.s2.ll 2>&1|tail -1
grep -E "call (void|i1|i32|i64) @(cqrt_|cq_template_)" $o/$b.s2.ll | sed 's/^ *//' | head -40
