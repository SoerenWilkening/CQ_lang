; control_cmp_merge_phi_covered_accept.ll — ACCEPT (bd test_C_libtooling-
; dm7f.77): a COMPARE condition whose operand chain reads a claimed region-merge φ
; (`condProvCoveredPhiGates`, ArmClassify.cpp), and a 4.4 select whose condition
; tree holds a logical NOT read as a fresh REGISTER root.
;
; Source (clang -O1 -include CQ.h) — dicke.c's SCS_{3,2} CCRy, in miniature:
;   bool a = 0, q = 0, t = 0; cq_theta(&a, .5); cq_theta(&q, .6); bool n = a ^ 1;
;   if (n) cq_theta(&q, .7); int s = 2 * (q ^ n) + q; if (s == 3) cq_theta(&t, .9);
;   return cq_measure(a) | (cq_measure(q) << 1) | (cq_measure(t) << 2)
;        | (cq_measure(n) << 3);
;
; The compare reads q's merge φ, whose producing arm Ry is ON its ancestry: the
; wire walk used to see that Ry as a staling gate on the φ's pre-Ry incoming and
; declined `condition predates a non-diagonal gate` (main 27aaf1e1). The select's
; condition `q ^ !a` decomposes into a NOT no network takes, so its own
; out-of-place rail is the register root, discharged after its last control read
; (ChainWalk row (c′)). Analytic (trace vs textbook, identical to 12 digits):
; P(a,q,t,n) = 0001: 0.594958424460, 0101: 0.343832856485, 1000: 0.055863227417,
; 1100: 0.004334151263, 1110: 0.001011340375.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define range(i32 0, 16) i32 @main()
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i1(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT:  %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[R]], i32 %[[BF]])
; CHECK:       call void @cqrt_ry_i1_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, double 9.000000e-01)
; CHECK:       call void @cqrt_cnot(i32 %[[R]], i32 %[[BF]])
; CHECK-NEXT:  call void @cq_template_xor_i1_unc(i32 %[[R]],
; CHECK-NEXT:  call void @cqrt_free(i32 %[[R]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 16) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01)
  %3 = xor i1 %1, true
  br i1 %1, label %6, label %4

4:                                                ; preds = %0
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 0x3FE6666666666666)
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i1 [ %5, %4 ], [ %2, %0 ]
  %8 = zext i1 %7 to i32
  %9 = xor i1 %7, %3
  %10 = select i1 %9, i32 2, i32 0
  %11 = or disjoint i32 %10, %8
  %12 = icmp eq i32 %11, 3
  br i1 %12, label %13, label %15

13:                                               ; preds = %6
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 9.000000e-01)
  br label %15

15:                                               ; preds = %13, %6
  %16 = phi i1 [ %14, %13 ], [ false, %6 ]
  %17 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %18 = zext i1 %17 to i32
  %19 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7)
  %20 = select i1 %19, i32 2, i32 0
  %21 = or disjoint i32 %20, %18
  %22 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %16)
  %23 = select i1 %22, i32 4, i32 0
  %24 = or disjoint i32 %21, %23
  %25 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3)
  %26 = select i1 %25, i32 8, i32 0
  %27 = or disjoint i32 %24, %26
  ret i32 %27
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
