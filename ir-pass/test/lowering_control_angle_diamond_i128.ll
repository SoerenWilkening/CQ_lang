; lowering_control_angle_diamond_i128.ll — Family B1, diamond form, NON-ABI-WIDTH
; integer (test_C_libtooling-cwk, adversarial-review finding). The classical-FP
; guard must reject not only floating-point but any classical merge `φ` whose
; type the reduction cannot lower. `abiWidthFromType(i128)` is empty (supported
; data widths are i1/i8/i16/i32/i64), so `reduceClassicalMux` returns null and
; leaves the `i128` `φ` standing; the diamond is then linearized away and the
; `φ` is stranded → "PHI nodes not grouped" broken module. The broadened guard
; (`!isIntegerTy() || abiWidth.empty()`) diagnoses it, while the legitimate
; i32/i64 classical-data mux (WP4/WP7, non-empty abiWidth) still lowers normally.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: PHI nodes not grouped
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @sink(i128)
define i32 @example(i32 %u0, i128 %a, i128 %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  br label %merge
merge:
  %p = phi i128 [ %a, %arm ], [ %b, %entry ]
  call void @sink(i128 %p)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
