#!/bin/bash
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d9542657-7eae-4089-ae6b-77dc3ed77cc3/scratchpad
L=/usr/local/opt/llvm@19/bin
P=/Users/sorenwilkening/Desktop/Projects/CQ_lang
D=$1
for f in $D/*.c; do
  n=$(basename $f .c)
  "$L/clang" -I$P/include -include CQ.h -O1 -emit-llvm -S $f -o $D/$n.s1.ll 2>$D/$n.s1err
  if [ $? -ne 0 ]; then echo "$n  STAGE1-FAIL"; continue; fi
  $S/oracle/cq-opt -passes=cq-lowering -S $D/$n.s1.ll -o $D/$n.or.ll 2>$D/$n.or.err; orc=$?
  $S/subj/cq-opt   -passes=cq-lowering -S $D/$n.s1.ll -o $D/$n.sj.ll 2>$D/$n.sj.err; sjc=$?
  ormsg=$(grep -o 'cq [a-z ]*lowering: [^"]*' $D/$n.or.err | head -1)
  sjmsg=$(grep -o 'cq [a-z ]*lowering: [^"]*' $D/$n.sj.err | head -1)
  streamdiff=SAME
  if [ $orc -eq 0 ] && [ $sjc -eq 0 ]; then
     diff -q $D/$n.or.ll $D/$n.sj.ll >/dev/null 2>&1 || streamdiff=STREAM-MOVED
  fi
  printf '%-24s oracle=%d %-58s | subj=%d %-58s %s\n' "$n" "$orc" "${ormsg:0:58}" "$sjc" "${sjmsg:0:58}" "$streamdiff"
done
