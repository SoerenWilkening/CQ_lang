; control_swap_reject_value_fp_merge.ll — an FP-typed merge under tainted
; control is categorically an ANGLE, never routable data (4.2 WI-3; PRD Part II
; §8.1/§8.3; the f64 silent-miscompile family).
;
; `if (q > 5) { ang = ang + 0.5; }` over a tainted f64 register — the arm is a
; structurally perfect fadd chain bottoming at the straight-through %ang0, and
; f64 even has a valid ABI width. That is exactly the trap: routing it would
; mint an FP data copy (`cqrt_copy_f64` does not exist — dead-ABI by design)
; and treat a rotation-angle carrier as basis data. The value classification
; declines ANY FP-typed merge before the base/§3c checks; acceptance never
; keys on abiWidthFromType() non-emptiness (CLAUDE.md correctness-risk block).
; FP-ness is tested with isFPOrFPVectorTy (scalar-only isFloatingPointTy
; misses <2 x double>). Contrast: control_swap_diamond_derived_f64.ll — an f64
; PHASE arm (cq_phi_f64 spine) stays accepted; only the VALUE leg is FP-fenced.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: value-arm swap-route
; CHECK-NOT: arm rewrites a condition operand
declare i32 @cq_theta_si32(i32, double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define double @example(i32 %u0, double %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang0 = call double @cq_theta_f64(double %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %f1 = fadd double %ang0, 5.000000e-01   ; routable-LOOKING tainted FP chain
  br label %merge
merge:
  %am = phi double [ %f1, %arm ], [ %ang0, %entry ]
  %m  = call double @cq_measure_f64(double %am)
  ret double %m
}
