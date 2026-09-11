#!/bin/zsh
# run.sh <dir> <name> — stage 1 (clang -O1) + stage 2 (cq-opt) for one probe.
# Prints the -O1 shape counters and the pass verdict. READ-ONLY: writes only into <dir>.
#
#   ./run.sh /tmp/boi6 p1
#
# REPO must point at the CQ_lang checkout whose build/ir-pass/cq-opt you are measuring.
set -u
REPO=${REPO:-$HOME/Desktop/CQ_lang}
LLVM=${LLVM:-/usr/local/opt/llvm@19/bin}
D=$1
N=$2
"$LLVM/clang" -I$REPO/include -include CQ.h -O1 -emit-llvm -S $D/$N.c -o $D/$N.s1.ll || exit 1
BRS=$(grep -c 'br i1' $D/$N.s1.ll)
SEL=$(grep -c 'select i1' $D/$N.s1.ll)
PHI1=$(grep -c 'phi i1' $D/$N.s1.ll)
"$REPO/build/ir-pass/cq-opt" -load-pass-plugin $REPO/build/ir-pass/libCQPass.so \
    -passes=cq-lowering -S $D/$N.s1.ll -o $D/$N.s2.ll 2> $D/$N.err
RC=$?
echo "== $N  rc=$RC  br_i1=$BRS select_i1=$SEL phi_i1=$PHI1"
[[ $RC -ne 0 ]] && head -2 $D/$N.err
# The decline ANCHOR (which instruction the control layer refused):
#   CQ_CTRL_DBG=1 "$REPO/build/ir-pass/cq-opt" … 2>&1 | grep CQ_CTRL_DBG
exit 0
