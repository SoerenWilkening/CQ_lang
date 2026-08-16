; control_classical_call_arm_accept_onward_phase_downstream_if.ll — ACCEPT (dugh,
; Phase 4×6; the block-lifetime crash regression): a 6.5 classical-call arm whose
; UNTAINTED merge `%out` flows ONWARD into a DOWNSTREAM CLASSICAL `if (cc)` diamond
; that applies a phase — `int y = 5; if (q>3) y = f(a); if (cc) y = cq_phi(y, .25);
; measure y`. The onward phase under classical control is the 5j5 one-register merge
; (`declineClassicalMuxes` lifts the downstream `%pp` phi to the wire base `%out`).
;
; THE BUG THIS PINS (found by the dugh Rule-13 adversarial sweep, fixed in
; RegionFlatten.cpp): the ccarm `flattenRegion` splices the merge block's terminator
; into `Pred` and erases the merge block — but here the merge block ends in the
; downstream `br i1 %cc`, and `m2`'s `%pp` phi lists the merge block as a predecessor.
; A PHI incoming BLOCK is not an operand-use of the block, so the erase left `%pp`
; with a dangling `<badref>` predecessor — a broken module that SIGSEGV'd the pass
; (a crash on VALID input, Rule 1). PRE-dugh this shape declined at the retired
; merge-out gate, so the latent flatten bug was never reached. The fix is the
; standard `Pred->replaceSuccessorsPhiUsesWith(Merge, Pred)` merge-into-pred fixup.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
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

define i32 @example(i32 %u0, i32 %a, i1 %cc) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]         ; UNTAINTED ccarm merge
  br i1 %cc, label %ph, label %m2                   ; downstream CLASSICAL diamond
ph:
  %p = call i32 @cq_phi_si32(i32 %y, double 0.25)   ; ONWARD phase under classical if
  br label %m2
m2:
  %pp = phi i32 [ %p, %ph ], [ %y, %merge ]         ; the phi whose pred-block flatten fixes
  %m = call i32 @cq_measure_si32(i32 %pp)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; the ccarm builds %out in the (flattened) entry, then the downstream classical
; branch stays, with the onward Rz applied IN PLACE to %out inside the if(cc) arm,
; and the measure reads %out (the %pp phi lifted to %out — no dangling pred):
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     br i1 %cc
; CHECK:     call void @cqrt_rz_i32(i32 %[[OUT]], double 2.500000e-01)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; no surviving merge phi over the handle (the one-register lift ran), the onward
; phase is uncontrolled (classical if, not a controlled Rz), and the region ACCEPTS:
; CHECK-NOT: phi i32
; CHECK-NOT: cqrt_rz{{.*}}_controlled
; ACC-NOT: under quantum control
