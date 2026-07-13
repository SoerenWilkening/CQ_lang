; control_swap_reject_nested_value_pure.ll — DECLINE: depth-2 all-value nest
; whose arm divides by a TAINTED (non-constant) divisor.
;
; HISTORY: until 3c6m.14 this fixture pinned the plain pure-value nest as
; "declined until the pure-value-nest increment". That increment landed
; (PredMux, L6) and the plain shape now ACCEPTS — pinned by the twin
; `control_predmux_accept_nested_value_chain.ll` (same IR, `udiv` replaced by
; `mul`). THIS fixture re-pins the residual decline: a `udiv %g, %q` cannot be
; speculated (UB on a zero divisor — PredMux E4 admits integer division only
; by a nonzero, non-minus-one constant), so PredMux LEAVES the region and it
; falls through to the existing loud decline exactly as before.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %t1 = mul nsw i32 %q, 7
  %g  = add nsw i32 %t1, 11
  %c2 = icmp slt i32 %q, 12
  br i1 %c2, label %arm, label %merge
arm:
  %t2 = udiv i32 %g, %q
  %h  = add nsw i32 %t2, 3
  br label %merge
merge:
  %qm = phi i32 [ %h, %arm ], [ %g, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}value-arm swap-route under quantum control
