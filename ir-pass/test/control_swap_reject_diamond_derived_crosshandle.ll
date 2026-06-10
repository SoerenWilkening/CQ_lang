; control_swap_reject_diamond_derived_crosshandle.ll — DECLINE: derived arm base
; vs STALE straight-through.
;
; The arm's spine bottoms at the pre-region-derived %qd, but the merge phi's
; straight-through (Pred-edge) incoming is the STALE theta result %q — the merge
; muxes the post-pre-rotation register against the pre-pre-rotation one. The
; derived-base accept (test_C_libtooling-9hh) routes ONLY a base that EQUALS the
; straight-through; an SSA mux of two different lineage depths of the same
; handle is off-design (the user's merge intent is ambiguous), so classifyArms
; must keep declining it: Base (%qd) != Routed (%q), and a cq_phi base is NOT a
; value-changing op, so this falls to the cross-handle leaf decline ("control
; flow") — never to the §3c/value-arm strings, and never an accept.
;
; This pins that relaxing the WI-3 `isPhiCall(Base)` guard does NOT widen the
; accept past Base == StraightThrough (over-decline is safe; Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c = icmp sgt i32 %qd, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %qd, double %a)   ; arm rotates the DERIVED %qd
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]        ; straight-through = STALE %q
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK: error{{.*}}control flow under quantum control
