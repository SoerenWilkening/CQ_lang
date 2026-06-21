; control_swap_reject_switch_i128.ll — DECLINE: i128 data-mux (G4). i128 IS
; isIntegerTy and (since the n0ui Tier-1 follow-up) a RECOGNIZED intermediate
; width, so abiWidthFromType(i128) is NON-empty — the decline now rides
; `widthHasReversibleCopy(abiWidthFromType(T))` == false (i128 has no cqrt_copy_i128:
; intermediate-only, source/sink stay i64), NOT the legacy `.empty()` arm. NEVER
; key the data-mux decision on the type-class or width-presence alone.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %wm = phi i128 [ 0, %entry ], [ 1, %a0 ], [ 2, %a1 ]
  %t = trunc i128 %wm to i32
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
