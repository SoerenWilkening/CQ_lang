#!/bin/zsh
# Track W review r1 harness. usage: rv.sh <sub|ora> <probe.c basenames...>
set -u
LLVM=/usr/local/opt/llvm@19/bin
SUB=/Users/sorenwilkening/Desktop/CQ_wx8g
ORA=/Users/sorenwilkening/Desktop/CQ_lang
D=${0:h}
WHICH=$1; shift
if [ "$WHICH" = "sub" ]; then B=$SUB; SFX=sub; else B=$ORA; SFX=ora; fi
for P in "$@"; do
  T=$(mktemp -d)
  "$LLVM/clang" -I$SUB/include -include CQ.h -O1 -g -emit-llvm -S "$D/$P.c" -o $T/s1.ll 2>$T/c.err || { echo "$P|$SFX|STAGE1FAIL"; cat $T/c.err|head -3; rm -rf $T; continue; }
  if [ ! -s $T/s1.ll ]; then echo "$P|$SFX|EMPTY-S1"; rm -rf $T; continue; fi
  "$B/build/ir-pass/cq-opt" -load-pass-plugin "$B/build/ir-pass/libCQPass.so" -passes=cq-lowering -S $T/s1.ll -o $T/s2.ll 2>$T/o.err
  E=$?
  if [ $E -ne 0 ]; then
    echo "$P|$SFX|DECLINE|$(grep -o 'cq [a-z -]*lowering: .*' $T/o.err | head -1)"
    cp $T/o.err $D/$P.$SFX.err
  else
    if [ ! -s $T/s2.ll ]; then echo "$P|$SFX|EMPTY-S2"; rm -rf $T; continue; fi
    FP=$(python3 $SUB/tools/free_pairing_check.py $T/s2.ll 2>&1 | tail -1)
    cp $T/s2.ll $D/$P.$SFX.ll
    "$LLVM/clang" $T/s2.ll $SUB/build/runtime/libcq_templates.a $SUB/build/runtime/libcq_runtime.a -o $T/a 2>/dev/null && $T/a > $D/$P.$SFX.trace
    echo "$P|$SFX|ACCEPT|lines=$(wc -l < $D/$P.$SFX.trace 2>/dev/null|tr -d ' ')|$FP"
  fi
  rm -rf $T
done
