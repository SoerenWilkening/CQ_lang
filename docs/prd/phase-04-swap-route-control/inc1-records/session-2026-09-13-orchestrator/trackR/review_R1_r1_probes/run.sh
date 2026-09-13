#!/bin/zsh
# Track R, Rule-13 review round 1 — re-runs every probe this review measured.
# ORACLE (read-only) vs SUBJECT, per PROTOCOL.md's per-probe pipeline.
# NO build, NO suite (PROTOCOL.md "review" row).  Usage: ./run.sh
set -u
L=/usr/local/opt/llvm@19/bin
OB=/Users/sorenwilkening/Desktop/CQ_lang/build
SB=/Users/sorenwilkening/Desktop/CQ_rb9x/build
SRC=/Users/sorenwilkening/Desktop/CQ_rb9x
HERE=${0:a:h}
TMP=$(mktemp -d)
oh=$(shasum -a 256 $OB/ir-pass/cq-opt | cut -c1-16)
sh_=$(shasum -a 256 $SB/ir-pass/cq-opt | cut -c1-16)
echo "ORACLE $oh (expect fbbe0820ef4b176a)   SUBJECT $sh_ (expect 221c1caa465db61e)"
run1() {  # run1 <name> <stage-1 .ll>
  for pair in "ORACLE:$OB" "SUBJECT:$SB"; do
    n=${pair%%:*}; b=${pair#*:}
    out=$("$b/ir-pass/cq-opt" -load-pass-plugin "$b/ir-pass/libCQPass.so" \
          -passes=cq-lowering -S $2 -o $TMP/$1.$n.ll 2>&1)
    if [[ $? -eq 0 ]]; then printf '%-28s %-8s ACCEPT md5=%s\n' $1 $n $(md5 -q $TMP/$1.$n.ll | cut -c1-8)
    else printf '%-28s %-8s DECLINE %s\n' $1 $n "$(print -r -- $out | grep -o 'cq controlled lowering: [^ ]*.*' | head -1)"; fi
  done
}
for f in $HERE/*.ll;  do run1 ${f:t:r} $f; done
for f in $HERE/*.c;   do
  "$L/clang" -I$SRC/include -include CQ.h -O1 -g -emit-llvm -S $f -o $TMP/${f:t:r}.s1.ll || continue
  run1 ${f:t:r} $TMP/${f:t:r}.s1.ll
done
echo "--- fixtures / probes from the tree ---"
for f in $SRC/ir-pass/test/control_peel_reject_fp_stateprep.ll \
         $SRC/ir-pass/test/control_peel_reject_stateprep_handwritten_clone_i1.ll \
         $SRC/ir-pass/test/control_peel_stateprep_datamux_peeled_control.ll \
         $SRC/ir-pass/test/control_inplace_ry_reject_stateprep_second_flag_i1.ll \
         $SRC/ir-pass/test/control_inplace_ry_reject_stateprep_zext_flag_i32seed.ll \
         $SRC/ir-pass/test/control_inplace_ry_reject_stateprep_second_cmp_onwire_merge.ll \
         $SRC/ir-pass/test/control_inplace_ry_reject_stateprep_second_cmp_onwire_pred.ll \
         $SRC/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackR/probes/r_R4_i32seed_i1clone.ll \
         $SRC/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackR/probes/b_HP_b_orig.ll ; do
  run1 ${f:t:r} $f
done
P=/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-11-orchestrator/review_integration_probes
for n in O3_mux_quantum_incomings R1_p80_bool R2_p80_window R4_p80_measured; do
  "$L/clang" -I$SRC/include -include CQ.h -O1 -g -emit-llvm -S $P/$n.c -o $TMP/$n.s1.ll && run1 $n $TMP/$n.s1.ll
done
echo "--- the two unmeasured customers, end to end on the SUBJECT ---"
for n in O3_mux_quantum_incomings R1_p80_bool; do
  "$SB/ir-pass/cq-opt" -load-pass-plugin "$SB/ir-pass/libCQPass.so" -passes=cq-lowering -S $TMP/$n.s1.ll -o $TMP/$n.s2.ll
  (cd $SRC && python3 tools/free_pairing_check.py $TMP/$n.s2.ll)
  "$L/clang" $TMP/$n.s2.ll $SB/runtime/libcq_templates.a $SB/runtime/libcq_runtime.a -o $TMP/$n.exe 2>/dev/null && $TMP/$n.exe | wc -l
done
echo "--- the R-1 slice, re-measured against its committed golden ---"
"$L/clang" -I$SRC/include -include CQ.h -O1 -emit-llvm -S $SRC/tests/e2e/slice_control_stateprep_bool_under_int_compare_fused.c -o $TMP/sl.s1.ll
"$SB/ir-pass/cq-opt" -load-pass-plugin "$SB/ir-pass/libCQPass.so" -passes=cq-lowering -S $TMP/sl.s1.ll -o $TMP/sl.s2.ll
(cd $SRC && python3 tools/free_pairing_check.py $TMP/sl.s2.ll)
"$L/clang" $TMP/sl.s2.ll $SB/runtime/libcq_templates.a $SB/runtime/libcq_runtime.a -o $TMP/sl.exe 2>/dev/null && $TMP/sl.exe > $TMP/sl.out
diff $TMP/sl.out $SRC/tests/e2e/slice_control_stateprep_bool_under_int_compare_fused.expected.log && echo "GOLDEN CLEAN ($(wc -l < $TMP/sl.out) lines)"
rm -rf $TMP
