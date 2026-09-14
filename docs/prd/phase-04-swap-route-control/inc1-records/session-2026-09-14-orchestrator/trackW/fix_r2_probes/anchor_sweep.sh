#!/bin/zsh
# F-W2-5 anchor sweep: compile every corpus probe with -O1 -g and record, for
# BOTH binaries, the decline message and the SOURCE ANCHOR. Single-TU recipe.
set -u
LLVM=/usr/local/opt/llvm@19/bin
SUB=/Users/sorenwilkening/Desktop/CQ_wx8g
ORA=/Users/sorenwilkening/Desktop/CQ_lang
D=${0:h}/corpus
OUT=${0:h}/anchor_sweep.txt
: > $OUT
for F in $D/*.c; do
  P=${F:t:r}
  T=$(mktemp -d)
  "$LLVM/clang" -I$SUB/include -include CQ.h -O1 -g -emit-llvm -S "$F" -o $T/s1.ll 2>/dev/null || { echo "$P|STAGE1FAIL" >> $OUT; rm -rf $T; continue; }
  [ -s $T/s1.ll ] || { echo "$P|EMPTY-S1" >> $OUT; rm -rf $T; continue; }
  for W in sub ora; do
    if [ "$W" = "sub" ]; then B=$SUB; else B=$ORA; fi
    "$B/build/ir-pass/cq-opt" -passes=cq-lowering -S $T/s1.ll -o $T/s2.$W.ll 2>$T/o.$W.err
    if [ $? -ne 0 ]; then
      M=$(grep -o 'cq [a-z -]*lowering: [^ ]*.*' $T/o.$W.err | head -1)
      A=$(grep -o 'error: [^:]*:[0-9]*:[0-9]*' $T/o.$W.err | head -1 | sed 's/error: //')
      [ -n "$A" ] || A=$(grep -o 'error: <unknown>:0:0' $T/o.$W.err | head -1 | sed 's/error: //')
      echo "$P|$W|DECLINE|$A|$M" >> $OUT
    else
      echo "$P|$W|ACCEPT|-|-" >> $OUT
    fi
  done
  rm -rf $T
done
echo "wrote $OUT"
