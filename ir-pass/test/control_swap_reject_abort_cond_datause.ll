; control_swap_reject_abort_cond_datause.ll — Phase 7.2 Inc 3 DECLINE (Rule-13
; hardening probe): the branch condition compare `%c` is ALSO used as DATA in the
; remainder (`zext %c` -> measured). It must DECLINE.
;
; Hazard (verify-clean silent miscompile if accepted): the park mints its OWN flag
; from q0, then the CFG surgery erases the branch — leaving `%c` a pure
; data-position compare that `lowerOps` recomputes at its (post-park) position,
; reading the PARKED routed handle, a WRONG value (the data use intended the
; PRE-park `(q>5)`). The park has no shared-condition-flag (ziov) machinery, so
; `classifyAbortPark`'s `Cond->hasOneUse()` gate DECLINES (over-decline is safe;
; soundness must NOT rest on the `-O1` fold that value-propagates such a compare on
; the surviving edge — Rule 10).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition used outside the branch under quantum control
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cqrt_tape_write

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort()

define i32 @slice() {
  %q = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %z = zext i1 %c to i32          ; the condition compare used as DATA (2nd use)
  br i1 %c, label %a, label %cont
a:
  call void @abort()
  unreachable
cont:
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}
