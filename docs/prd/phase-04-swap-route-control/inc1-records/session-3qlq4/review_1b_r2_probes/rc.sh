#!/bin/bash
# rc.sh <abs file.c> [binary]  — C pipeline
R=/Users/sorenwilkening/Desktop/CQ_lang
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/399370cc-11ea-43ff-bc2d-6a55cc78fdb2/scratchpad/review_1b_r2
LLVM=/usr/local/opt/llvm@19/bin
BIN=${2:-$R/build/ir-pass/cq-opt}
f="$1"; b=$(basename "$f" .c); o=$SP/out
$LLVM/clang -I $R/include -include CQ.h -O1 -emit-llvm -S "$f" -o $o/$b.s1.ll 2>$o/$b.cerr || { echo "CLANG-FAIL"; head -3 $o/$b.cerr; exit 1; }
$BIN -passes=cq-lowering -S $o/$b.s1.ll -o $o/$b.s2.ll 2>$o/$b.err; rc=$?
if [ $rc -ne 0 ]; then echo "DECLINE(rc=$rc): $(grep -o 'error: .*' $o/$b.err | head -2 | tr '\n' ' | ')"; exit 0; fi
echo "ACCEPT"
grep -qE '@cq_theta|@cq_phi|@cq_measure' $o/$b.s2.ll && { echo "!!! SURVIVING cq_* CALL:"; grep -nE 'call.*@cq_(theta|phi|measure)' $o/$b.s2.ll|head -3; }
grep -qE '^\s+br i1' $o/$b.s2.ll && grep -nE '^\s+br i1' $o/$b.s2.ll | head -3 | sed 's/^/  br: /'
python3 $R/tools/free_pairing_check.py $o/$b.s2.ll > $o/$b.fp 2>&1 || echo "STAGE2B-FAIL"; tail -1 $o/$b.fp
$LLVM/clang $o/$b.s2.ll $R/build/runtime/libcq_templates.a $R/build/runtime/libcq_runtime.a -o $o/$b.exe 2>$o/$b.lderr || { echo "LINK-FAIL"; head -3 $o/$b.lderr; exit 1; }
$o/$b.exe | tee $o/$b.trace
