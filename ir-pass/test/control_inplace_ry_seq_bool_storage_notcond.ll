; control_inplace_ry_seq_bool_storage_notcond.ll — ACCEPT: two Ry regions on one _Bool, conditions a / !a.
;
; bd test_C_libtooling-dm7f.53 (CQ_FINDINGS F3). A C `_Bool` written by two
; controlled regions lives in an `i8` STORAGE-WIDTH phi web after -O1 (`trunc`
; into each arm theta, `zext` out of it), and every such region declined
; `value-arm swap-route under quantum control`. `narrowBoolStoragePhis`
; (BoolStorageNarrow.h, run first in `peelIndependentMergePhis`) narrows a web
; whose members provably hold 0/1 and are read only through bit 0 back to the
; `i1` spelling -O1 emits for one region, so each region lowers as the shipped
; in-place controlled Ry / controlled state prep: `cqrt_ry_<W>_controlled` on
; the SAME rail, never a copy or a route (R6). IR transcribed from clang -O1.
;
;   bool a (rotated), t = 0; if (a) cq_theta(&t,.3); if (!a) cq_theta(&t,.7);
;
; Analytic check (Ry additivity): a=1: Ry(.3)Ry(.7)Ry(-.7) = Ry(.3), t =
; cos(.15)|0> + sin(.15)|1>; a=0: Ry(.7), t = cos(.35)|0> + sin(.35)|1>.
; Region 1 is a controlled state prep (fresh |0> rail, seed false); region 2's
; seed is region 1's MERGE (a chained in-place Ry on that rail), and its ¬a arm
; is spelled ry(t,θ); ry_controlled(a,t,−θ) — nothing non-diagonal under ¬a.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.d53.ll
; RUN: %filecheck %s < %t.d53.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.d53.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.d53.ll
; RUN: %filecheck %s --check-prefix=CRCNT < %t.d53.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  br i1 %1, label %2, label %5

2:
  %3 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %4 = zext i1 %3 to i8
  br label %5

5:
  %6 = phi i8 [ %4, %2 ], [ 0, %0 ]
  br i1 %1, label %11, label %7

7:
  %8 = trunc nuw i8 %6 to i1
  %9 = call i1 @cq_theta_i1(i1 %8, double 0x3FE6666666666666)
  %10 = zext i1 %9 to i8
  br label %11

11:
  %12 = phi i8 [ %6, %5 ], [ %10, %7 ]
  %13 = call i1 @cq_measure_i1(i1 %1)
  %14 = zext i1 %13 to i32
  %15 = trunc nuw i8 %12 to i1
  %16 = call i1 @cq_measure_i1(i1 %15)
  %17 = zext i1 %16 to i32
  %18 = add nuw nsw i32 %17, %14
  ret i32 %18
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 0xBFE6666666666666)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK:      %[[H3:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])
;
; Whole-file, pure negatives (a positive in a prefix windows the negatives
; after it): no route / copy / adjoint gate, every arm theta and region phi
; consumed; FCNT/CRCNT count the frees and the controlled Ry gates.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: call i1 @cq_theta
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = trunc
; NOROUTE-NOT: zext i1 {{.*}} to i8
; FCNT-NOT:     call void @cqrt_free(
; CRCNT-COUNT-2: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
