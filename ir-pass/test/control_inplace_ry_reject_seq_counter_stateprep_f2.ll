; control_inplace_ry_reject_seq_counter_stateprep_f2.ll — **NOW AN ACCEPT**: the Dicke counter, FRESH target.
;
; ⚠ The `reject_` in the name is history; the file is deliberately NOT renamed
; (the bd `gahu` precedent: a `git mv` can be resurrected by a merge, L8).
;
; bd test_C_libtooling-dm7f.53, delegated ruling
; `ruling-dm7f53-p4-sibling-cond-prep-2026-10-15` (applying
; `owner-ruling-f2-condwire-2026-09-11` / `owner-ruling-drbq14-tree-leaves-2026-10-14`):
;   int x (rotated); bool t = 0; if (x == 0) cq_theta(&t,.3); if (x == 1) cq_theta(&t,.7);
; compiles as two controlled state preps. F2 used to fire on region 1: on its
; arm edge the SIBLING condition `x == 1` is forced false = the seed. That pin
; is read through an EQUALITY compare of the condition register `x` itself, so
; the byte-identical -O1 rival `t = (x == 1)` (measured identical, 2026-10-14)
; is the identity on the seed: `siblingConditionCompareOnWire` (amended to
; any forced icmp, ruling-dm7f53-p4-sibling-cond-prep-amend-forced), the fourth
; conjunct of F2's `excludedAtTest`. Off-wire pins stay loud
; (control_inplace_ry_reject_seq_counter_f2_offwire_*.ll).
;
; Analytic trace: region 1 mints eq(x,0), Ry(.3) on a fresh |0> t under it,
; strips + frees the flag; region 2 the same with eq(x,1), Ry(.7) on the SAME
; rail. x = 0 -> Ry(.3)|0>; x = 1 -> Ry(.7)|0>; else |0> (the two flags are
; never both 1). Stage 2b: 2 frees, 2 verified.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.d53.ll
; RUN: %filecheck %s < %t.d53.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.d53.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.d53.ll
; RUN: %filecheck %s --check-prefix=CRCNT < %t.d53.ll

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %2 = icmp eq i32 %1, 0
  br i1 %2, label %3, label %6

3:
  %4 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %5 = zext i1 %4 to i8
  br label %6

6:
  %7 = phi i8 [ %5, %3 ], [ 0, %0 ]
  %8 = icmp eq i32 %1, 1
  br i1 %8, label %9, label %13

9:
  %10 = trunc nuw i8 %7 to i1
  %11 = call i1 @cq_theta_i1(i1 %10, double 0x3FE6666666666666)
  %12 = zext i1 %11 to i8
  br label %13

13:
  %14 = phi i8 [ %12, %9 ], [ %7, %6 ]
  %15 = call i32 @cq_measure_si32(i32 %1)
  %16 = trunc nuw i8 %14 to i1
  %17 = call i1 @cq_measure_i1(i1 %16)
  %18 = zext i1 %17 to i32
  %19 = add nsw i32 %15, %18
  ret i32 %19
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H0]], i32 0)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H1]], i32 %[[H2]], double 3.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H1]], i32 %[[H0]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H1]])
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H0]], i32 1)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H3]], i32 %[[H2]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H3]], i32 %[[H0]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H3]])
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H0]])
; CHECK-NEXT: %[[H5:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
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
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CRCNT-COUNT-2: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
