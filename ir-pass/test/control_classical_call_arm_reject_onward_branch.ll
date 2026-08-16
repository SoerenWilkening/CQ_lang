; control_classical_call_arm_reject_onward_branch.ll — DECLINE (yn71, Phase 4×6): a
; 6.5 classical-call arm whose UNTAINTED merge feeds a NEW tainted-condition BRANCH
; (`if (y > 7) …`) whose diamond is a bare DATA-MUX over the merge (`%z = phi [%y,
; %hot], [0, %cold]`, empty arms) — an onward control shape the value-arm classifier
; cannot prove.
;
; THE DECLINE AUTHORITY yn71 preserves: at round-1 detection the merge (`int y = 5;
; if (q>3) y = f(a)`) was data-untainted, so `if (y > 7)` was NOT a tainted-condition
; branch and `detectControlRegions` (step 183) never adjudicated it. After
; `repropagateControlMerges` re-seeds the second propagation from the emitted `%out`,
; `icmp sgt %out, 7` IS tainted — a genuinely new control region on the merge. yn71
; RE-RUNS `detectControlRegions` on it (replacing dugh's blanket
; `declineReClassifiedControl`): the re-detect is the DECLINE AUTHORITY, so this
; empty-arm data-mux-over-constant diamond declines with the real classifier's PRECISE
; per-shape reason — `value-arm swap-route under quantum control` — rather than dugh's
; generic `control flow`. (clang -O1 never emits this diamond form — it lowers `(y>7)?
; y:0` to a `select`, which yn71 DOES lower via the controlled-XOR copy merge; this
; handwritten diamond over a constant is the off-pattern residue the emitter declines.)
; Either way it NEVER lowers — over-decline is safe (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}value-arm swap-route under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatablePureCallee`). The old
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
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]        ; UNTAINTED merge
  %c2 = icmp sgt i32 %y, 7                          ; tainted only AFTER the re-seed
  br i1 %c2, label %hot, label %cold                ; NEW control on the merge
hot:
  br label %join
cold:
  br label %join
join:
  %z = phi i32 [ %y, %hot ], [ 0, %cold ]
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
