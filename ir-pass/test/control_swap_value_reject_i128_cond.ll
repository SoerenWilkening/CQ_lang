; control_swap_value_reject_i128_cond.ll — DECLINE: a VALUE diamond whose branch
; condition is a tainted `icmp i128`. The pin for the Inc-2 round-1 review's
; PRE-MUTATION flag-mintability fence (finding F-V1-2), and — measured — a
; partial repair of the Rule-1 gap the same review filed as F-V1-9.
;
; THE FENCE. `emitValueRegion` hands the region to `emitSelectRegion`, which
; mints its flag as its own step 1 — i.e. AFTER the chain has been hoisted, the
; select built, the merge phi RAUW'd and the diamond FLATTENED. A mint that
; returns null there is a MUTATE-THEN-DECLINE: loud, but on a module already
; rewritten. The retired route minted the flag as its FIRST emission step, so
; its bail left the region intact; Inc 2's round-1 fix restores that property by
; re-asking `comparePredLowerable` and `compareFlagMintable` in LOCKSTEP before
; the first mutation, exactly as `AngleSelectEmit` step 0b and the 6.5
; classical-call gate do (Rule 14 — the same two predicates, never a third
; spelling). `compareFlagMintable` is false at i128, so this module declines
; before anything moves.
;
; ⚠ THIS FIXTURE ALSO RECORDS A DISPOSITION CHANGE, and it is the reason the
; round-1 review's "no reproducer exists" note is superseded. MEASURED:
;   pre-3qlq oracle 52d7764  rc=1, `no template for opcode 'icmp i1' in tainted
;                                  context` — and ZERO `cq controlled lowering:`
;                                  diagnostics, i.e. a tainted `br` reached the
;                                  end of the pass neither claimed nor declined
;                                  by the control layer (Rule 1 says there is no
;                                  third path). That is finding F-V1-9,
;                                  PRE-EXISTING and outside Inc 2's scope.
;   Inc 2 @ 8c526d9          rc=1, the SAME template message — the gap intact.
;   this commit              rc=1, `cq controlled lowering: control flow under
;                                  quantum control`, at the compare
;                                  (`CQ_CTRL_DBG=1` names `%c = icmp sgt i128`).
; So the VALUE-arm half of that gap is now claimed loudly. The PHASE-arm half is
; NOT (`f2_i128cond_phase.ll` under
; docs/prd/phase-04-swap-route-control/inc2-records/ still reports only the
; template error on both binaries) and stays open on bd test_C_libtooling-3qlq.8.
; No accept class moved in either direction: both binaries exit non-zero on this
; module and neither emits a gate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_theta_sll(i64, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i64 %u0, i32 %v0) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %qw = sext i64 %q to i128
  %c = icmp sgt i128 %qw, 5         ; out-of-surface condition width
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i32 %p, 5
  %v2 = add i32 %v1, 15
  br label %merge
merge:
  %pm = phi i32 [ %v2, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
; PRE-MUTATION: nothing is hoisted, no select is built, no merge gate is emitted.
; CHECK-NOT: cqrt_copy_i32_controlled
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cqrt_alloc_i32(i32 0)
