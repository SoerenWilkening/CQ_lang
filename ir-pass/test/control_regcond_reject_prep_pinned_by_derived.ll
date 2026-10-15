; control_regcond_reject_prep_pinned_by_derived.ll — DECLINE (bd
; test_C_libtooling-dm7f.77, R11 round 1 A-F2; review_s2A/p3.c):
;   t ^= a; if (t) cq_theta(&b, .5); _Bool c = t & d; cq_theta(&c, .9);
; F2 finds `c = t & d` equal to b's literal seed 0 on the not-taken edge. The
; region's condition is the REGISTER CONDITION `t`, and the pinning register is
; not it, so the string says that (the shipped F2 string reads "the condition
; register"). Admitting it rests on the condition FORCING `t & d` there — an
; extension of the F2 forcedness ruling, filed as bd dm7f.51.5.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: state prep seed is proven equal to a live register other than the condition under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 16) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FE6666666666666)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.100000e+00)
  %4 = xor i1 %1, %2
  br i1 %4, label %5, label %7

5:                                                ; preds = %0
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %7

7:                                                ; preds = %5, %0
  %8 = phi i1 [ %6, %5 ], [ false, %0 ]
  %9 = and i1 %4, %3
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %9, double noundef 9.000000e-01)
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4)
  %12 = zext i1 %11 to i32
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2)
  %14 = select i1 %13, i32 2, i32 0
  %15 = or disjoint i32 %14, %12
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8)
  %17 = select i1 %16, i32 4, i32 0
  %18 = or disjoint i32 %15, %17
  %19 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10)
  %20 = select i1 %19, i32 8, i32 0
  %21 = or disjoint i32 %18, %20
  ret i32 %21
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
