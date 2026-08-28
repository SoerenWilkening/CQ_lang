; control_swap_reject_post_region_theta_valuearm.ll — DECLINE: precondition P1
; of the Inc-4 position-aware accept (bd test_C_libtooling-lom0). A VALUE arm
; keeps the POSITION-FREE reading, verbatim.
;
; The condition's wire gains a chained `cq_theta` that runs strictly AFTER the
; region — the exact structural situation the phase path now ACCEPTS
; (control_swap_accept_post_region_theta.ll) — but the arm is a value chain
; (`p = p + 3`), so the region stays declined:
;     cq controlled lowering: condition predates a non-diagonal gate
; MEASURED IDENTICAL at HEAD (b4e329b) and in this tree: message, anchor and
; exit code all unchanged. This file is the pin that the widening is
; PHASE-ONLY.
;
; WHY THE TWO CLASSES ARE NOT THE SAME PHYSICS (Rule 7). A PHASE arm keeps its
; answer IN PLACE on the routed register and strips the flag with the
; UNCONTROLLED `icmp_inv` — after the strip the region owns nothing on the wire,
; which is what makes "the Ry runs later, so it cannot stale anything" true. A
; VALUE arm is method-B: compute → `cqrt_copy_<W>` the basis LABEL out →
; reverse-play. The copy-out is a second rail carrying a record of the wire, the
; replay reads the routed rail, and the §3c/routed-base reasoning that admits
; the arm is stated over a basis that a later in-place Ry moves. None of the
; Inc-4 argument transfers, so none of it was extended: the value path's own
; routed-base walk (`ArmClassify`, "routed base predates a non-diagonal gate")
; also stays position-free.
;
; NOTE THE ARM'S REGISTER IS DELIBERATELY A DIFFERENT WIRE (`%p`, its own
; `cq_theta` source) from the condition's (`%q`). Rewriting `%q` in the arm
; would decline earlier as the §3c clobber `arm rewrites a condition operand`
; and would prove nothing about P1 — this way the ONLY thing standing between
; the region and the emitter is the value/phase class.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)   ; the CONDITION's wire
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)   ; the muxed register
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge

arm:
  %p1 = add nsw i32 %p, 3                                      ; VALUE arm
  br label %merge

merge:
  %pm = phi i32 [ %p1, %arm ], [ %p, %entry ]
  %w = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)    ; POST-region Ry on %q
  %m1 = call i32 @cq_measure_si32(i32 %pm)
  %m2 = call i32 @cq_measure_si32(i32 %w)
  %r = add nsw i32 %m1, %m2
  ret i32 %r
}

; CHECK: error{{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
