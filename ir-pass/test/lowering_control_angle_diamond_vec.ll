; lowering_control_angle_diamond_vec.ll — Family B1, diamond form, VECTOR-FP
; (test_C_libtooling-cwk, adversarial-review finding). A classical-FP merge `φ`
; under quantum control must be diagnosed, but `<2 x double>` is NOT caught by a
; scalar `isFloatingPointTy()` test — the vector-aware hazard is "the reduction
; has no ABI width for this type". `dissolveBranchPhi`/`reduceClassicalMux` cannot
; lower a `<2 x double>` (abiWidthFromType is empty), so before the broadened
; guard the region was built, the `φ` left undissolved, the diamond linearized
; away, and the `φ` stranded → "PHI nodes not grouped" broken module. The guard
; now mirrors the select-form predicate (`!isIntegerTy() || abiWidth.empty()`),
; so any non-handle classical merge `φ` — FP scalar/vector, pointer, odd-width
; integer — is diagnosed. (`_Complex double` and SLP-vectorized adjacent angle
; stores both surface as `<2 x double>` at -O1.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: PHI nodes not grouped
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @sink(<2 x double>)
define i32 @example(i32 %u0, <2 x double> %a, <2 x double> %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  br label %merge
merge:
  %p = phi <2 x double> [ %a, %arm ], [ %b, %entry ]
  call void @sink(<2 x double> %p)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
