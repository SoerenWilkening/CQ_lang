; control_inplace_ry_seq_bool_storage_two_rails.ll — ACCEPT: prep under a, in-place Ry under b, one _Bool.
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
;   bool a,b (rotated), t = 0; if (a) cq_theta(&t,.3); if (b) cq_theta(&t,.7);
;
; t = Ry(.3·a + .7·b)|0>: region 1 a controlled prep, region 2 a controlled Ry
; on region 1's merge rail (the same handle), both controls read-only.
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
  br i1 %1, label %3, label %6

3:
  %4 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %5 = zext i1 %4 to i8
  br label %6

6:
  %7 = phi i8 [ %5, %3 ], [ 0, %0 ]
  br i1 %2, label %8, label %12

8:
  %9 = trunc nuw i8 %7 to i1
  %10 = call i1 @cq_theta_i1(i1 %9, double 0x3FE6666666666666)
  %11 = zext i1 %10 to i8
  br label %12

12:
  %13 = phi i8 [ %11, %8 ], [ %7, %6 ]
  %14 = call i1 @cq_measure_i1(i1 %1)
  %15 = zext i1 %14 to i32
  %16 = call i1 @cq_measure_i1(i1 %2)
  %17 = zext i1 %16 to i32
  %18 = add nuw nsw i32 %17, %15
  %19 = trunc nuw i8 %13 to i1
  %20 = call i1 @cq_measure_i1(i1 %19)
  %21 = zext i1 %20 to i32
  %22 = add nuw nsw i32 %18, %21
  ret i32 %22
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H2]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H1]], i32 %[[H2]], double 0x3FE6666666666666)
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])
; CHECK:      %[[H4:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])
; CHECK:      %[[H5:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
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
