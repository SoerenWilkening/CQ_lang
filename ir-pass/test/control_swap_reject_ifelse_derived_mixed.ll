; control_swap_reject_ifelse_derived_mixed.ll — DECLINE: arms bottom at DIFFERENT
; lineage depths of the handle.
;
; The then-arm's spine bottoms at the pre-region-derived %qd while the else-arm's
; bottoms at the underlying theta result %q. Both are tainted handles of the same
; physical qubit, but the swap-route if/else routes ONE shared base register: a
; mixed-depth pair means the merge phi muxes the post-pre-rotation value against
; the pre-pre-rotation one — off-design (same ambiguity as the diamond
; cross-handle variant). classifyArms anchors Routed on the first arm's base
; (%qd) and must keep declining the second arm (Base %q != Routed, a leaf that is
; not the routed handle → "control flow") after the derived-base accept lands
; (test_C_libtooling-9hh). Never the §3c/value-arm strings, never an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c = icmp sgt i32 %qd, 5
  br i1 %c, label %then, label %else
then:
  %qt = call i32 @cq_phi_si32(i32 %qd, double %a)   ; bottoms at the DERIVED %qd
  br label %merge
else:
  %qe = call i32 @cq_phi_si32(i32 %q, double %b)    ; bottoms at the THETA %q
  br label %merge
merge:
  %qm = phi i32 [ %qt, %then ], [ %qe, %else ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK: error{{.*}}control flow under quantum control
