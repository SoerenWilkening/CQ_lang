; lowering_inplace_qq_decline_both_dead.ll — DECLINE (bd r2j3.33 / dm7f.51 step 1,
; R11 round 1; ruling ruling-dm7f51-both-dead-loud-2026-10-15; repro review_s1A/p6.c).
;
; Source (clang -O1 -include CQ.h):
;   bool a = 0, t = 0; cq_theta(&a, .5); cq_theta(&t, .4);
;   t ^= a; cq_theta(&t, .7); return cq_measure(t);
;
; BOTH old operands are dead after the xor and the result survives (it is rotated),
; so BOTH rails are eligible in-place targets. Which register the user overwrote is
; not recoverable from -O1 SSA (clang commutes operands; there is no `!dbg`
; without -g), and the choice changes the unitary: the LEFTOVER register differs
; (the reviewer's analytic P(t=0) 0.6837 vs 0.6547). b12d4452 broke the tie by
; BirthOrder and so could pick the wrong one silently. Now: loud, at the
; eligibility level, before any fence is asked. RETIREMENT TRIGGER: the owner
; question bd test_C_libtooling-dm7f.74 — (i) recover the lvalue from `cqc -g` debug
; metadata, loud if absent, or (ii) keep it permanently loud (workaround: keep one
; operand live).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq in-place lowering: both operands of a quantum reassignment are dead registers; the overwritten one is not recoverable

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 2) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01)
  %3 = xor i1 %1, %2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 0x3FE6666666666666)
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4)
  %6 = zext i1 %5 to i32
  ret i32 %6
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr

