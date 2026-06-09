; control_swap_reject_crosshandle.ll — cross-handle multiplexer is NOT a phase arm.
;
; Regression for the WI-1 adversarial finding that accept-criterion (3) ("base is
; tainted") is too weak. Here the arm's phase spine bottoms at a DIFFERENT tainted
; handle %p (a rotation of a second qubit), muxed against the routed straight-
; through handle %q. The merge is a coherent cross-rail multiplexer, not a phase
; rotation of the routed handle — the icmp_inv(q) flag-strip would be invalid. The
; phase-arm accept MUST require the spine to bottom at the SAME handle threaded
; straight through (%q), not merely "some tainted value". Over-decline is safe.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %p1 = call i32 @cq_phi_si32(i32 %p, double %a)   ; rotates %p, NOT the routed %q
  br label %merge
merge:
  %qm = phi i32 [ %p1, %arm ], [ %q, %entry ]      ; muxes %q vs a phase of %p
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
