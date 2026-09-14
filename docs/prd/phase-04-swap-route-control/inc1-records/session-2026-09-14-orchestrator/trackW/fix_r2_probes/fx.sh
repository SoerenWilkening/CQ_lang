#!/bin/zsh
# fx.sh <sub|ora> <cqTU> [libTU]   -- two-TU llvm-link recipe with -g, mirroring rv2link.sh
set -u
LLVM=/usr/local/opt/llvm@19/bin
SUB=/Users/sorenwilkening/Desktop/CQ_wx8g
ORA=/Users/sorenwilkening/Desktop/CQ_lang
D=${0:h}
WHICH=$1; P=$2; LIB=${3:-}
if [ "$WHICH" = "sub" ]; then B=$SUB; SFX=fxsub; else B=$ORA; SFX=fxora; fi
T=$(mktemp -d)
"$LLVM/clang" -I$SUB/include -include CQ.h -O1 -g -emit-llvm -S "$D/$P.c" -o $T/cq.ll || exit 1
if [ -n "$LIB" ]; then
  "$LLVM/clang" -O1 -g -emit-llvm -S "$D/$LIB.c" -o $T/lib.ll || exit 1
  "$LLVM/llvm-link" -S $T/cq.ll $T/lib.ll -o $T/s1.ll || exit 1
else
  cp $T/cq.ll $T/s1.ll
fi
[ -s $T/s1.ll ] || { echo "$P|$SFX|EMPTY-S1"; exit 1; }
cp $T/s1.ll $D/$P.$SFX.s1.ll
"$B/build/ir-pass/cq-opt" -load-pass-plugin "$B/build/ir-pass/libCQPass.so" -passes=cq-lowering -S $T/s1.ll -o $T/s2.ll 2>$T/o.err
E=$?
if [ $E -ne 0 ]; then
  cp $T/o.err $D/$P.$SFX.err
  echo "$P|$SFX|DECLINE|$(grep -o 'cq [a-z -]*lowering: .*' $T/o.err | head -1)|ANCHOR=$(grep -o 'error: [^:]*:[0-9]*:[0-9]*' $T/o.err | head -1 | sed 's/error: //')"
else
  [ -s $T/s2.ll ] || { echo "$P|$SFX|EMPTY-S2"; exit 1; }
  FP=$(python3 $SUB/tools/free_pairing_check.py $T/s2.ll 2>&1 | tail -1)
  cp $T/s2.ll $D/$P.$SFX.ll
  "$LLVM/clang" $T/s2.ll $SUB/build/runtime/libcq_templates.a $SUB/build/runtime/libcq_runtime.a -o $T/a 2>/dev/null && $T/a > $D/$P.$SFX.trace
  echo "$P|$SFX|ACCEPT|lines=$(wc -l < $D/$P.$SFX.trace 2>/dev/null|tr -d ' ')|$FP"
fi
rm -rf $T
