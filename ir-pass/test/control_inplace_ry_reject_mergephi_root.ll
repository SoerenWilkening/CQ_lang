; control_inplace_ry_reject_mergephi_root.ll — DECLINE (over-decline): a merge phi as the WHOLE Ry condition.
;
; bd test_C_libtooling-dm7f.53 admits a region-merge phi as a tree LEAF on the
; in-place Ry path; a phi ROOT (`if (a) cq_theta(&t,.3); if (t) cq_theta(&u,.7);`)
; is a one-leaf tree with no node, which the Ry consumer does not take yet
; (`control flow`). The kickback twin accepts
; (control_phase_kickback_mergephi_root_inplace_arm.ll). Filed as a follow-up;
; RETIREMENT TRIGGER: flip this file when the Ry phi-root row lands.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  br i1 %1, label %2, label %4

2:
  %3 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  br label %4

4:
  %5 = phi i1 [ %3, %2 ], [ false, %0 ]
  br i1 %5, label %6, label %8

6:
  %7 = call i1 @cq_theta_i1(i1 false, double 0x3FE6666666666666)
  br label %8

8:
  %9 = phi i1 [ %7, %6 ], [ false, %4 ]
  %10 = call i1 @cq_measure_i1(i1 %1)
  %11 = zext i1 %10 to i32
  %12 = call i1 @cq_measure_i1(i1 %5)
  %13 = zext i1 %12 to i32
  %14 = add nuw nsw i32 %13, %11
  %15 = call i1 @cq_measure_i1(i1 %9)
  %16 = zext i1 %15 to i32
  %17 = add nuw nsw i32 %14, %16
  ret i32 %17
}

; CHECK: cq controlled lowering: control flow under quantum control
