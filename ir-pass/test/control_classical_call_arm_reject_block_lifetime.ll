; control_classical_call_arm_reject_block_lifetime.ll — block-lifetime reject
; (WI-5.8 probe, the sequential-region SIGSEGV class): TWO classical-call diamonds
; in sequence where the second region's Pred IS the first region's merge block
; (`merge1` hosts both the first merge phi AND the second tainted branch). Emitting
; the first region would flatten + ERASE `merge1`, after which the second region
; would dereference freed memory (a SIGSEGV on valid input).
;
; Detection forecloses it BEFORE any mutation: the first diamond's merge block ends
; in a tainted-condition branch, so `recoverRegion`'s Nested check
; (`hasTaintedCondBranch`) classifies it as a NESTED region — and the depth-2 nest
; prover declines (a classical-call inner is not a homogeneous phase nest). The
; result is a LOUD `nested control flow under quantum control` decline, never a
; crash. (A DIAMOND gets this protection incidentally — its merge is an immediate
; successor; the `SwapRouteEmit` cross-region pre-flight is the backstop if a future
; shape ever slips past detection.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}nested control flow under quantum control
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
