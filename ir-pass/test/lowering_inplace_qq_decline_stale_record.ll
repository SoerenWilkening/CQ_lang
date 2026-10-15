; lowering_inplace_qq_decline_stale_record.ll — DECLINE (bd r2j3.33 / dm7f.51 step 1,
; R11 round 1 findings A-F3 / B-F1 / C-F1; repro review_s1C/p6.c).
;
; Source (clang -O1 -include CQ.h):
;   bool c = 0; int t = 0, a = 0, b = 0; (all four rotated)
;   int s = c ? t : b; t ^= a; int mt = cq_measure(t);
;   if (s == 2) cq_phi(.3); cq_theta(&a, .7); ...
;
; THE SILENT MISCOMPILE b12d4452 SHIPPED. The 4.4 merge copies `t` into `%out` with
; `cqrt_copy_i32_controlled` — a VOID `cqrt_*` reader, which M-C's G7 arm (c)
; settled — so `t ^= a` converted in place; the merge replay that discharges
; `%out` was then refused (the in-place write sat in its window) and `%out` (= old
; `t` on c=1) leaked beside `t'`, so `%out ^ t'` recorded `a` and the later Ry on
; `a` was dephased: rc 0, no diagnostic. The invariant restored: no record of the
; target's OLD value may survive undischarged beside the result. For a QUANTUM
; source a prior void reader is settled only if every rail it writes is user data
; or released before the gate (G7 arm (c′)); `%out` is neither, the dead `t` is
; eligible, so the pass fails loudly. (The classical-immediate M-C analogue is bd
; test_C_libtooling-r2j3.38.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq in-place lowering: quantum reassignment of a dead register is not provable in place

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 6.000000e-01)
  %5 = select i1 %1, i32 %2, i32 %4
  %6 = xor i32 %3, %2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %8 = icmp eq i32 %5, 2
  br i1 %8, label %9, label %10

9:                                                ; preds = %0
  tail call void @cq_phi(double noundef 3.000000e-01)
  br label %10

10:                                               ; preds = %9, %0
  %11 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 0x3FE6666666666666)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %13 = add nsw i32 %12, %7
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %15 = zext i1 %14 to i32
  %16 = add nsw i32 %13, %15
  %17 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %18 = add nsw i32 %16, %17
  ret i32 %18
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

declare void @cq_phi(double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr

