#!/bin/bash
# rh.sh <abs file.ll frag> [binary]  — hand IR with hdr
R=/Users/sorenwilkening/Desktop/CQ_lang
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/399370cc-11ea-43ff-bc2d-6a55cc78fdb2/scratchpad/review_1b_r2
BIN=${2:-$R/build/ir-pass/cq-opt}
f="$1"; b=$(basename "$f" .ll); o=$SP/out
cat $SP/h/hdr.ll "$f" > $o/$b.in.ll
$BIN -passes=cq-lowering -S $o/$b.in.ll -o $o/$b.out.ll 2>$o/$b.err; rc=$?
if [ $rc -ne 0 ]; then echo "DECLINE(rc=$rc): $(grep -o 'error: .*' $o/$b.err|head -2|tr '\n' ' | ')"; exit 0; fi
echo "ACCEPT"
grep -qE '@cq_theta|@cq_phi|@cq_measure' $o/$b.out.ll && { echo "!!! SURVIVING cq_* CALL"; grep -nE 'call.*@cq_(theta|phi|measure)' $o/$b.out.ll|head -3; }
grep -E "call (void|i1|i32|i8|i16|i64) @(cqrt_|cq_template_)" $o/$b.out.ll | sed 's/^  */  /'
python3 $R/tools/free_pairing_check.py $o/$b.out.ll 2>&1 | tail -1
