#!/bin/zsh
# 8 twin pairs + w_l: rolled vs hand-unrolled, byte-compared, on the SUBJECT.
set -u
LLVM=/usr/local/opt/llvm@19/bin
SUB=/Users/sorenwilkening/Desktop/CQ_wx8g
P=$SUB/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/probes
T=$(mktemp -d)
run() {  # run <basename> -> writes $T/<basename>.trace, echoes lines or DECLINE
  local B=$1
  "$LLVM/clang" -I$SUB/include -include CQ.h -O1 -g -emit-llvm -S "$P/$B.c" -o $T/$B.s1.ll 2>/dev/null || { echo "STAGE1FAIL"; return 1; }
  [ -s $T/$B.s1.ll ] || { echo "EMPTY-S1"; return 1; }
  "$SUB/build/ir-pass/cq-opt" -passes=cq-lowering -S $T/$B.s1.ll -o $T/$B.s2.ll 2>$T/$B.err || { echo "DECLINE"; return 1; }
  [ -s $T/$B.s2.ll ] || { echo "EMPTY-S2"; return 1; }
  "$LLVM/clang" $T/$B.s2.ll $SUB/build/runtime/libcq_templates.a $SUB/build/runtime/libcq_runtime.a -o $T/$B.exe 2>/dev/null || { echo "LINKFAIL"; return 1; }
  $T/$B.exe > $T/$B.trace
  wc -l < $T/$B.trace | tr -d ' '
}
pairs=(
  "w_a_carried_bool:w_a_carried_bool_unrolled"
  "w_a_neg:w_a_neg_unrolled"
  "w_grover_bool:w_grover_bool_unrolled"
  "w_b2_prep_bool:w_b_iterlocal_prep_bool_unrolled"
  "w_d_iterlocal_base_bool:w_d_iterlocal_base_bool_unrolled"
  "w_g_derived_cond_iterlocal:w_g_derived_cond_iterlocal_unrolled"
  "w_k_two_iterlocal_rails:w_k_two_iterlocal_rails_unrolled"
  "w_i_no_invariant_root:w_i_no_invariant_root_unrolled"
  "w_l_twofn_mixed_clauses:w_l_twofn_mixed_clauses_unrolled"
)
OK=0; BAD=0
for pr in $pairs; do
  R=${pr%%:*}; U=${pr##*:}
  LR=$(run $R); LU=$(run $U)
  if [ -s $T/$R.trace ] && [ -s $T/$U.trace ] && cmp -s $T/$R.trace $T/$U.trace; then
    echo "$R vs $U | BYTE-IDENTICAL | lines=$LR"; OK=$((OK+1))
  else
    echo "$R vs $U | DIVERGE/FAIL | rolled=$LR unrolled=$LU"; BAD=$((BAD+1))
    diff $T/$R.trace $T/$U.trace 2>/dev/null | head -8
  fi
done
echo "TWIN PAIRS: $OK identical, $BAD not"
rm -rf $T
