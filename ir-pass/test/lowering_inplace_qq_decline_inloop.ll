; lowering_inplace_qq_decline_inloop.ll — DECLINE (owner ruling
; owner-ruling-dm7f51-inplace-qq-2026-10-14 Q1; bd test_C_libtooling-r2j3.33,
; dm7f.51 step 1): an ITERATION-LOCAL `t ^= a` inside a bounded loop.
;
; Source (clang -O1 -include CQ.h):
;   int a = 0; cq_theta(&a, .5);
;   for (int i = 0; i < 3; i++) { int t = 0; cq_theta(&t, .4); t ^= a;
;                                 cq_measure(t); }
;   cq_measure(a);
;
; The per-trip `t` is born and dies inside the trip, so its old value is dead at
; the xor (`!cq.qq.dead`: the loop CONTAINS its definition), and the result is
; measured. The in-place fence's G5 refuses every site in a loop (the rolled
; in-loop machinery owns in-loop in-place gates), so the pass fails loudly rather
; than mint a template per trip beside a kept old `t` per trip. Before r2j3.33:
; rc 0, out of place. Contrast the loop-INVARIANT operand (`t` defined outside
; the loop, re-read every trip): that one is live, never recorded dead, and stays
; out of place. RETIREMENT TRIGGER: an in-loop QQ in-place lowering (rolled), bd
; test_C_libtooling-8h7d.22.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq in-place lowering: quantum reassignment of a dead register is not provable in place

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define noundef i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %4

2:                                                ; preds = %4
  %3 = tail call i32 @cq_measure_si32(i32 noundef %1)
  ret i32 0

4:                                                ; preds = %0, %4
  %5 = phi i32 [ 0, %0 ], [ %9, %4 ]
  %6 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %7 = xor i32 %6, %1
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %9 = add nuw nsw i32 %5, 1
  %10 = icmp eq i32 %9, 3
  br i1 %10, label %2, label %4
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

