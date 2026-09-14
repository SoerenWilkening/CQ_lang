#!/bin/zsh
# F-W2-6 / F-W2-7 re-measurement on BOTH binaries, with the twin diff.
set -u
LLVM=/usr/local/opt/llvm@19/bin
SUB=/Users/sorenwilkening/Desktop/CQ_wx8g
ORA=/Users/sorenwilkening/Desktop/CQ_lang
D=${0:h}/corpus
T=$(mktemp -d)
one() { # one <which> <basename> -> trace at $T/<which>.<b>.trace ; echo lines|DECLINE
  local W=$1 B=$2 BD
  if [ "$W" = sub ]; then BD=$SUB/build; else BD=$ORA/build; fi
  "$LLVM/clang" -I$SUB/include -include CQ.h -O1 -g -emit-llvm -S "$D/$B.c" -o $T/$W.$B.s1.ll 2>/dev/null || { echo STAGE1FAIL; return; }
  [ -s $T/$W.$B.s1.ll ] || { echo EMPTY-S1; return; }
  "$BD/ir-pass/cq-opt" -passes=cq-lowering -S $T/$W.$B.s1.ll -o $T/$W.$B.s2.ll 2>/dev/null || { echo DECLINE; return; }
  [ -s $T/$W.$B.s2.ll ] || { echo EMPTY-S2; return; }
  "$LLVM/clang" $T/$W.$B.s2.ll $SUB/build/runtime/libcq_templates.a $SUB/build/runtime/libcq_runtime.a -o $T/$W.$B.exe 2>/dev/null || { echo LINKFAIL; return; }
  $T/$W.$B.exe > $T/$W.$B.trace; wc -l < $T/$W.$B.trace | tr -d ' '
}
for pr in "w2c_inplace_rail:w2c_inplace_rail_un" "w2c_noregion_inplace:w2c_noregion_inplace_un" "w2g_mut_d3_invread:w2g_mut_d3_invread_un" "w2g_mut_d1_no_invread:w2g_mut_d1_no_invread_un"; do
  R=${pr%%:*}; U=${pr##*:}
  for W in sub ora; do
    LR=$(one $W $R); LU=$(one $W $U)
    ID="n/a"
    if [ -s $T/$W.$R.trace ] && [ -s $T/$W.$U.trace ]; then
      cmp -s $T/$W.$R.trace $T/$W.$U.trace && ID="IDENTICAL" || ID="DIVERGE"
    fi
    echo "$W | $R=$LR  twin($U)=$LU  -> $ID"
    if [ "$ID" = DIVERGE ]; then diff $T/$W.$R.trace $T/$W.$U.trace | head -10; fi
  done
done
echo "--- cross-binary: is the SUB rolled trace == ORA rolled trace where both accept?"
for B in w2c_noregion_inplace w2c_noregion_inplace_un; do
  if [ -s $T/sub.$B.trace ] && [ -s $T/ora.$B.trace ]; then
    cmp -s $T/sub.$B.trace $T/ora.$B.trace && echo "$B: SUB==ORA byte-identical" || echo "$B: SUB!=ORA"
  fi
done
rm -rf $T
