; control_classical_call_arm_reject_block_lifetime.ll — block-lifetime reject
; (WI-5.8 probe, the sequential-region SIGSEGV class): TWO classical-call diamonds
; in sequence where the second region's Pred IS the first region's merge block
; (`merge1` hosts both the first merge phi AND the second tainted branch). Emitting
; the first region would flatten + ERASE `merge1`, after which the second region
; would dereference freed memory (a SIGSEGV on valid input).
;
; The decline is now the `SwapRouteEmit` CROSS-REGION PRE-FLIGHT, and the move is
; deliberate (bd hcrg). Detection used to foreclose this shape: the first
; diamond's merge ends in a tainted-condition branch, so `recoverRegion`'s Nested
; check classified it as NESTED and the depth-2 prover declined it. hcrg made the
; merge-hosted branch a SEQUENTIAL signal rather than a nested one, so both
; diamonds now recover cleanly and `classifyClassicalCallArm` accepts both as
; `ClassicalCallArm` regions — and the block-lifetime hazard lands, as designed,
; on the pre-flight that exists for exactly this.
;
; It declines there because `sequentialChainAlias` admits the reorder for ONE
; shape only: both regions flat, childless, Depth-0 `BranchRegion`s. A
; `ClassicalCallArm` is a different Kind with a different emitter — it HOISTS the
; call out of the arm before flattening — and that emitter's interaction with a
; preceding region's flatten has never been analysed. Over-declining is always
; safe (Prime Directive); admitting it would be a separate increment with its own
; clearance.
;
; The message therefore changed from `nested control flow` to `control flow`,
; which is the pre-flight's string. What did NOT change is the only property this
; file has ever asserted: a LOUD decline, never a crash, never a silent accept of
; quantum-controlled flow.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @pure_f(i32) #0

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %merge1
arm1:
  %r1 = call i32 @pure_f(i32 7)
  br label %merge1
merge1:
  %y1 = phi i32 [ %r1, %arm1 ], [ %q, %entry ]
  %c2 = icmp sgt i32 %y1, 3      ; merge1 also hosts the SECOND tainted branch
  br i1 %c2, label %arm2, label %merge2
arm2:
  %r2 = call i32 @pure_f(i32 8)
  br label %merge2
merge2:
  %y2 = phi i32 [ %r2, %arm2 ], [ %y1, %merge1 ]
  %m = call i32 @cq_measure_si32(i32 %y2)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
