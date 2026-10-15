; control_regcond_reject_target_measured_before.ll — DECLINE, ADVERSARIAL (bd
; test_C_libtooling-dm7f.77): a register condition whose in-place TARGET was
; measured before the control read.
;
; Source (clang -O1 -include CQ.h):
;   bool a = 0, t = 0; cq_theta(&a, .4); cq_theta(&t, .3); int m = cq_measure(t);
;   t ^= a; if (t) cq_theta(&a, .9); t ^= a;
;   return m | (cq_measure(a) << 1) | (cq_measure(t) << 2);
;
; `t` is dead after the xor (the measurement is a PRIOR use), so the xor commits
; with target `t`; the rail ladder's rung (ii) is asked over BOTH names of the
; condition's wire, and the target's measurement precedes the read point (the
; in-place gate would act on a measured handle). Loud.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: condition measured before the control route under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 8) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01)
  %3 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2)
  %4 = xor i1 %1, %2
  br i1 %4, label %5, label %7

5:                                                ; preds = %0
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 9.000000e-01)
  br label %7

7:                                                ; preds = %5, %0
  %8 = phi i1 [ %6, %5 ], [ %1, %0 ]
  %9 = zext i1 %3 to i32
  %10 = xor i1 %4, %8
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8)
  %12 = select i1 %11, i32 2, i32 0
  %13 = or disjoint i32 %12, %9
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10)
  %15 = select i1 %14, i32 4, i32 0
  %16 = or disjoint i32 %13, %15
  ret i32 %16
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
