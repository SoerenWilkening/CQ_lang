; control_swap_defer_valuearm.ll — value/permutation arm DEFERS to 4.2 (NOT §3c).
;
; Contrast partner of control_swap_reject_clobber.ll. The arm value-changes a
; quantum variable %p that the condition does NOT read (the condition reads %q).
; The diamond's straight-through (Pred-edge) incoming is %p, which is NOT in the
; condition's taint provenance — so this is a value-arm to be lowered by the 4.2
; compute→copy→reverse-play path, NOT a §3c clobber. WI-1 declines it with the
; distinct "value-arm swap-route" string; a wrong §3c reject here would be a
; false-positive that conflates "rewrites a NON-condition var" with the §3c bind.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}value-arm swap-route under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %p1 = add i32 %p, 3        ; value op on a NON-condition quantum var (%p, not %q)
  br label %merge
merge:
  %pm = phi i32 [ %p1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
