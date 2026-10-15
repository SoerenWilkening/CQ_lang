; control_inplace_ry_reject_tree_mergephi_leaf_target.ll — DECLINE: the Ry target lies on a phi leaf's wire.
;
; bd test_C_libtooling-dm7f.53. `if (a) cq_theta(&t,.3); if (t & b)
; cq_theta(&t,.7);` — the second region rotates the register its own tree
; reads (dm7f.51 / dm7f.9 territory: the tree strip would read a relabelled
; leaf). Loud at the wire disposition; the narrowing turned `icmp ne i8 %t, 0`
; into the narrowed phi, so this is the phi-leaf ladder's refusal, not the
; retired-route one.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %1, label %3, label %6

3:
  %4 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %5 = zext i1 %4 to i8
  br label %6

6:
  %7 = phi i8 [ %5, %3 ], [ 0, %0 ]
  %8 = icmp ne i8 %7, 0
  %9 = select i1 %2, i1 %8, i1 false
  br i1 %9, label %10, label %14

10:
  %11 = trunc nuw i8 %7 to i1
  %12 = call i1 @cq_theta_i1(i1 %11, double 0x3FE6666666666666)
  %13 = zext i1 %12 to i8
  br label %14

14:
  %15 = phi i8 [ %13, %10 ], [ %7, %6 ]
  %16 = call i1 @cq_measure_i1(i1 %1)
  %17 = zext i1 %16 to i32
  %18 = call i1 @cq_measure_i1(i1 %2)
  %19 = zext i1 %18 to i32
  %20 = add nuw nsw i32 %19, %17
  %21 = trunc nuw i8 %15 to i1
  %22 = call i1 @cq_measure_i1(i1 %21)
  %23 = zext i1 %22 to i32
  %24 = add nuw nsw i32 %20, %23
  ret i32 %24
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
