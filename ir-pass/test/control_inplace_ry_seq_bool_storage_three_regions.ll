; control_inplace_ry_seq_bool_storage_three_regions.ll — ACCEPT: a 3-region chain on one _Bool.
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
;   bool a,b,c (rotated), t = 0; if (a) cq_theta(&t,.3); if (b) cq_theta(&t,.7);
;   if (c) cq_theta(&t,.9);
;
; t = Ry(.3a + .7b + .9c)|0>; three controlled Ry on ONE rail, no free.
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
  %2 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %3 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  br i1 %1, label %4, label %7

4:
  %5 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %6 = zext i1 %5 to i8
  br label %7

7:
  %8 = phi i8 [ %6, %4 ], [ 0, %0 ]
  br i1 %2, label %9, label %13

9:
  %10 = trunc nuw i8 %8 to i1
  %11 = call i1 @cq_theta_i1(i1 %10, double 0x3FE6666666666666)
  %12 = zext i1 %11 to i8
  br label %13

13:
  %14 = phi i8 [ %12, %9 ], [ %8, %7 ]
  br i1 %3, label %15, label %19

15:
  %16 = trunc nuw i8 %14 to i1
  %17 = call i1 @cq_theta_i1(i1 %16, double 9.000000e-01)
  %18 = zext i1 %17 to i8
  br label %19

19:
  %20 = phi i8 [ %18, %15 ], [ %14, %13 ]
  %21 = call i1 @cq_measure_i1(i1 %1)
  %22 = zext i1 %21 to i32
  %23 = call i1 @cq_measure_i1(i1 %2)
  %24 = zext i1 %23 to i32
  %25 = add nuw nsw i32 %24, %22
  %26 = call i1 @cq_measure_i1(i1 %3)
  %27 = zext i1 %26 to i32
  %28 = add nuw nsw i32 %25, %27
  %29 = trunc nuw i8 %20 to i1
  %30 = call i1 @cq_measure_i1(i1 %29)
  %31 = zext i1 %30 to i32
  %32 = add nuw nsw i32 %28, %31
  ret i32 %32
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H2]], double 2.000000e-01)
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H3]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H1]], i32 %[[H3]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H2]], i32 %[[H3]], double 9.000000e-01)
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK:      %[[H5:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])
; CHECK:      %[[H6:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
; CHECK:      %[[H7:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H3]])
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
; CRCNT-COUNT-3: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
