#!/bin/bash
R=/Users/sorenwilkening/Desktop/CQ_lang
d=$(mktemp -d)
cat h/hdr.ll "$1" > $d/t.ll
$R/build/ir-pass/cq-opt -passes=cq-lowering -S $d/t.ll -o $d/o.ll 2>$d/e.txt
rc=$?
if [ $rc -ne 0 ]; then echo "DECLINE(rc=$rc): $(grep -o 'error:.*' $d/e.txt|head -2)"; rm -rf $d; exit 0; fi
echo "ACCEPT"
grep -E "call (void|i1|i32) @(cqrt_|cq_template_|cq_theta|cq_phi|cq_measure)" $d/o.ll | sed 's/^  //' 
if grep -qE '@cq_(theta|phi|measure)' $d/o.ll; then echo "!!! SURVIVING cq_* CALL"; fi
python3 $R/tools/free_pairing_check.py $d/o.ll 2>&1 | grep -v '^$' | head -5
cp $d/o.ll ./$(basename $1 .ll).out.ll
rm -rf $d
