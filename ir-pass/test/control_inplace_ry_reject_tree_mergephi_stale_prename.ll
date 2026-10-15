; control_inplace_ry_reject_tree_mergephi_stale_prename.ll — DECLINE: a tree reads BOTH the pre-region name and the merge.
;
; bd test_C_libtooling-dm7f.53 adversarial probe. `bool old = q1; if (q0)
; cq_theta(&q1,.4); if (old ^ q1) cq_theta(&q2,.1);` — `old` ALIASES q1's
; register, which region 1 relabelled: a stale read. By design
; `condTreeCoveredPhiGates` keeps region 1's arm gate as evidence because the
; OTHER leaf's provenance reaches it; that clause is MASKED here — the
; pre-detection stale-record fence fires first on the `xor` reading the stale
; name, and that string is what this file pins.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %3 = call i1 @cq_theta_i1(i1 false, double 1.000000e-01)
  br i1 %1, label %4, label %6

4:
  %5 = call i1 @cq_theta_i1(i1 %2, double 4.000000e-01)
  br label %6

6:
  %7 = phi i1 [ %5, %4 ], [ %2, %0 ]
  %8 = xor i1 %2, %7
  br i1 %8, label %9, label %11

9:
  %10 = call i1 @cq_theta_i1(i1 %3, double 1.000000e-01)
  br label %11

11:
  %12 = phi i1 [ %10, %9 ], [ %3, %6 ]
  %13 = call i1 @cq_measure_i1(i1 %1)
  %14 = zext i1 %13 to i32
  %15 = call i1 @cq_measure_i1(i1 %7)
  %16 = zext i1 %15 to i32
  %17 = add nuw nsw i32 %16, %14
  %18 = call i1 @cq_measure_i1(i1 %12)
  %19 = zext i1 %18 to i32
  %20 = add nuw nsw i32 %17, %19
  ret i32 %20
}

; CHECK: cq opcode lowering: operand predates a non-diagonal gate
