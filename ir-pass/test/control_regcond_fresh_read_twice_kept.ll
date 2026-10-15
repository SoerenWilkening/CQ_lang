; control_regcond_fresh_read_twice_kept.ll — ACCEPT (bd test_C_libtooling-
; dm7f.77, R11 round 1 C-F2; review_s2C/p3_h3_fresh_twice.c): a fresh register
; condition `c = a & !b` read as the control of TWO regions with a rotation of
; its parent `a` between them.
;   b ^= a; _Bool c = a & b; if (c) cq_theta(&t, .5); cq_theta(&a, .3);
;   if (c) cq_theta(&u, .9);
; `c` is a record genuinely live ACROSS the Ry on `a` (dead-record ruling: leave
; it allocated and warn, lyyf), so ChainWalk's row (c′) must NOT discharge it
; after the first control read: the `and` stays allocated (no `_unc`, no free)
; and the second region reads the same rail. M-A warns.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define range(i32 0, 4) i32 @main()
; CHECK:       %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i1(i32 %[[A:[a-zA-Z0-9_.]+]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[C]], i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[A]], double 3.000000e-01)
; CHECK-NEXT:  %[[U:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[C]], i32 %[[U]], double 9.000000e-01)
; CHECK-NOT:   cq_template_and_i1_unc
; CHECK-NOT:   call void @cqrt_free(i32 %[[C]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 4) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FE6666666666666)
  %3 = xor i1 %2, true
  %4 = and i1 %1, %3
  br i1 %4, label %5, label %7

5:                                                ; preds = %0
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %7

7:                                                ; preds = %5, %0
  %8 = phi i1 [ %6, %5 ], [ false, %0 ]
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 3.000000e-01)
  br i1 %4, label %10, label %12

10:                                               ; preds = %7
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 9.000000e-01)
  br label %12

12:                                               ; preds = %10, %7
  %13 = phi i1 [ %11, %10 ], [ false, %7 ]
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8)
  %15 = zext i1 %14 to i32
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13)
  %17 = zext i1 %16 to i32
  %18 = add nuw nsw i32 %17, %15
  %19 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %9)
  %20 = zext i1 %19 to i32
  %21 = add nuw nsw i32 %18, %20
  ret i32 %21
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
