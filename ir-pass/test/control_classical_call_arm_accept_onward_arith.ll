; control_classical_call_arm_accept_onward_arith.ll — ACCEPT (dugh, Phase 4×6): a
; 6.5 classical-call arm whose UNTAINTED merge (`int y = 5; if (q>3) y = f(a)`, a
; classical constant straight-through + a pure classical call) feeds ONWARD-QUANTUM
; stock arithmetic (`z = y + 1`) that terminates at a measurement.
;
; PRE-dugh this DECLINED at the classifier's merge-out gate: the merge phi is
; data-untainted (constant 5 + classical call %r), so the FIRST forward propagation
; classified `%z` classical, and the gate rejected any non-measure/non-i32-ret merge
; user. dugh retires that gate and RE-SEEDS a second propagation from the emitted
; `%out` (`repropagateControlMerges`): `%z` is re-tainted and lowers as the reversible
; quantum producer `cq_template_add_i32_hl(%out, 1)`; `%m` measures it. This is the
; (A2) onward-QUANTUM subset the bead accepts.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatableTotalCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_reject_partial_callee.ll (a VISIBLE partial body,
; also declined). Nothing else in this fixture changes; the body is inert.
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %z = add i32 %y, 1                 ; ONWARD QUANTUM: was a classical-over-quantum leak
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; M-C NOTE (bd test_C_libtooling-6uqc, Increment 2a): the ONWARD add lowers
; IN PLACE on the merge out-rail (`cqrt_addc_i32`) rather than minting a fresh
; rail off it. What this file pins is UNCHANGED and slightly sharper — the
; onward arithmetic is still re-tainted and still lowered (never left as a stock
; `add`), and the measurement now reads the very register the merge built, so no
; ancestor copy of it survives the region.
;
; the controlled-XOR copy merge builds %out, then the ONWARD add re-tainted and
; lowered over %out, then the measure:
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call void @cqrt_addc_i32(i32 %[[OUT]], i32 1)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; the onward add is NOT left as a stock `add`, and the region ACCEPTS (no decline):
; CHECK-NOT: = add i32
; ACC-NOT: under quantum control
