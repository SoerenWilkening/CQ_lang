; control_swap_reject_abort_nonnoreturn.ll — Phase 7.2 Inc 3 DECLINE probe: an
; arm that LOOKS like an abort park (a call followed by `unreachable`) but whose
; callee is NOT a recognized process-terminating noreturn sink (`@foo`). It must
; still DECLINE — never park (PRD-7.2 §2.11-B; the issue's RED->GREEN negative #1).
;
; `classifyAbortPark` returns NotApplicable (the callee name is not in the sink
; set), so the `br` falls through to `recoverRegion`, where the `unreachable`-
; terminated arm yields `uncondSucc==null` -> `OffPattern` -> the generic loud
; decline. Nothing is parked. (Adversarial probe: clang does not emit `unreachable`
; after a non-noreturn call, so this is hand-constructed to stress the name gate —
; recognizing by the noreturn ATTRIBUTE instead would risk parking a DIVERGENT
; user noreturn, the §2.11-C-ii loop case deferred to 7.3/7.4.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cqrt_tape_write

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @foo()

define i32 @slice() {
  %q = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %cont
a:
  call void @foo()                ; NOT a recognized noreturn sink
  unreachable
cont:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
