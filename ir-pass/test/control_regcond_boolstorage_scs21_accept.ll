; control_regcond_boolstorage_scs21_accept.ll — ACCEPT (bd test_C_libtooling-
; dm7f.77, design D1 + D3): the Dicke SCS_{2,1} block on a prepped register.
;
; Source (clang -O1 -include CQ.h):
;   bool q1 = 0, q2 = 0; cq_theta(&q2, .5); if (q2) cq_theta(&q1, .6);
;   q2 ^= q1; if (q2) cq_theta(&q1, .7); q2 ^= q1;
;   return cq_measure(q1) | (cq_measure(q2) << 1);
;
; -O1 keeps q1 at its `_Bool` storage width (`phi i8 [zext %q1', 0]`) and spells
; `q2 ^= q1` as `icmp ne i8 %phi, (zext %q2)`. The `_Bool` narrowing now admits a
; BOOLEAN COMPARE reader (D1, BoolStorageNarrow.cpp) and rewrites it to
; `xor i1 %phi', %q2`, which the commit stage takes as a register condition with
; target q2 (dead after it). Main 27aaf1e1: `value-arm swap-route`. Analytic
; (trace vs textbook, identical to 12 digits): P(q1,q2) = 00: 0.938791280945,
; 01: 0.049294890232, 10: 0.006568337185, 11: 0.005345491638.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define range(i32 0, 4) i32 @main()
; CHECK-NEXT:  %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[Q2]], double 5.000000e-01)
; CHECK-NEXT:  %[[Q1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[Q2]], i32 %[[Q1]], double 6.000000e-01)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[Q1]], i32 %[[Q2]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[Q2]], i32 %[[Q1]], double 0x3FE6666666666666)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[Q1]], i32 %[[Q2]]), !cq.inplace.qq
; CHECK-NOT:   cq_template
; CHECK-NOT:   cqrt_free

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 4) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br i1 %1, label %2, label %5

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01)
  %4 = zext i1 %3 to i8
  br label %5

5:                                                ; preds = %2, %0
  %6 = phi i8 [ %4, %2 ], [ 0, %0 ]
  %7 = zext i1 %1 to i8
  %8 = icmp ne i8 %6, %7
  br i1 %8, label %9, label %13

9:                                                ; preds = %5
  %10 = trunc nuw i8 %6 to i1
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %10, double noundef 0x3FE6666666666666)
  %12 = zext i1 %11 to i8
  br label %13

13:                                               ; preds = %9, %5
  %14 = phi i8 [ %12, %9 ], [ %6, %5 ]
  %15 = trunc nuw i8 %14 to i1
  %16 = xor i1 %8, %15
  %17 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %15)
  %18 = zext i1 %17 to i32
  %19 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %16)
  %20 = select i1 %19, i32 2, i32 0
  %21 = or disjoint i32 %20, %18
  ret i32 %21
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
