#!/bin/bash
# R3 probe harness. $1 = .ll file. Runs SUBJECT (B13) and ORACLE (main) cq-opt.
SUB=/Users/sorenwilkening/Desktop/CQ_3d8q/build/ir-pass/cq-opt
ORA=/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt
f="$1"; b=$(basename "$f" .ll)
[ -s "$f" ] || { echo "$b: EMPTY INPUT FILE"; exit 1; }
for who in SUB ORA; do
  bin=$SUB; [ $who = ORA ] && bin=$ORA
  out=$("$bin" -passes=cq-lowering -S "$f" -o /tmp/r3_${b}_${who}.ll 2>/tmp/r3_${b}_${who}.err; echo "rc=$?")
  rc=${out##rc=}
  if [ "$rc" = 0 ]; then
    n=$(grep -c 'call.*@cqrt_' /tmp/r3_${b}_${who}.ll)
    echo "$b  $who: ACCEPT ($n cqrt calls)"
  else
    echo "$b  $who: DECLINE  [$(head -c 300 /tmp/r3_${b}_${who}.err | tr '\n' ' ' | sed 's/  */ /g')]"
  fi
done
