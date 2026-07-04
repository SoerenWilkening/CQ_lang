; control_classical_call_arm_reject_onward_branch.ll — DECLINE (dugh, Phase 4×6): a
; 6.5 classical-call arm whose UNTAINTED merge feeds a NEW tainted-condition BRANCH
; (`if (y > 7) …`) — a nested/onward control region on the merge, OUT of dugh scope.
;
; THE HOLE dugh closes: at detection the merge (`int y = 5; if (q>3) y = f(a)`) was
; data-untainted, so `if (y > 7)` was NOT a tainted-condition branch and
; `detectControlRegions` never adjudicated it. After `repropagateControlMerges`
; re-seeds the second propagation from the emitted `%out`, the `icmp sgt %out, 7`
; condition IS tainted — a genuinely new control region on the merge. The escape net
; does not catch it (`declineTaintEscapes` skips a tainted br/switch condition — "that
; is ControlDetect's"). `declineReClassifiedControl` (run inside
; `repropagateControlMerges`, after the second propagation) declines it loudly. dugh
; accepts only the (A2) onward-QUANTUM straight-line subset (arith/phase → measure);
; onward tainted CONTROL on the merge is a future capability (over-decline is safe,
; Prime Directive). NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0
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
