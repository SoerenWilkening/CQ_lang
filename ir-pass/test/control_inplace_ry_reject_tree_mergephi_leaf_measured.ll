; control_inplace_ry_reject_tree_mergephi_leaf_measured.ll — DECLINE: a phi leaf measured before the branch.
;
; bd test_C_libtooling-dm7f.53. `if (a) cq_theta(&b,.4); m = cq_measure(b);
; if (b & c) cq_theta(&t,.3);` — rung (ii) of the shared phi-leaf ladder
; (`condTreePhiLeafRefusal`): a control read of a collapsed register.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %1, label %3, label %5

3:
  %4 = call i1 @cq_theta_i1(i1 false, double 4.000000e-01)
  br label %5

5:
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  %7 = call i1 @cq_measure_i1(i1 %6)
  %8 = and i1 %2, %6
  br i1 %8, label %9, label %11

9:
  %10 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  br label %11

11:
  %12 = phi i1 [ %10, %9 ], [ false, %5 ]
  %13 = zext i1 %7 to i32
  %14 = call i1 @cq_measure_i1(i1 %1)
  %15 = zext i1 %14 to i32
  %16 = add nuw nsw i32 %15, %13
  %17 = call i1 @cq_measure_i1(i1 %2)
  %18 = zext i1 %17 to i32
  %19 = add nuw nsw i32 %16, %18
  %20 = call i1 @cq_measure_i1(i1 %12)
  %21 = zext i1 %20 to i32
  %22 = add nuw nsw i32 %19, %21
  ret i32 %22
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
