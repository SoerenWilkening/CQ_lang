; lowering_inplace_qq_decline_subtrahend.ll — DECLINE (owner ruling
; owner-ruling-dm7f51-inplace-qq-2026-10-14 Q1; bd test_C_libtooling-r2j3.33,
; dm7f.51 step 1): `t = a - t` with the old `t` dead.
;
; Source (clang -O1 -include CQ.h):
;   int a = 0, t = 0; cq_theta(&a, .5); cq_theta(&t, .4);
;   t = a - t; cq_theta(&a, .7); cq_measure(a); cq_measure(t);
;
; `sub` is directional: only the MINUEND can be overwritten in place
; (`cqrt_sub_<W>(src, dst)` computes dst - src). Here the dead operand is the
; SUBTRAHEND, and `a` (the minuend) is live, so there is no in-place form, the
; out-of-place form keeps the old `t` recording `a` beside `t'`, and the pass
; fails loudly. Before r2j3.33: rc 0, `cq_template_sub_i32(h_a, h_t)`.
; RETIREMENT TRIGGER: an in-place negate-and-add (`t := a - t`) lowering.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq in-place lowering: quantum reassignment of a dead register is not provable in place

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define noundef i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = sub nsw i32 %1, %2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3)
  ret i32 0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

