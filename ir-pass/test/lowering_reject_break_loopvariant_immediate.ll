; lowering_reject_break_loopvariant_immediate.ll — DECLINE (Phase 7.4 Inc 2,
; y05j.2; the Rule-13 review 2026-06-26 — E10). A value-arm break whose in-place
; rail self-update uses a LOOP-VARIANT classical immediate (`q = q ^ i`, the
; counter): dtzb accepts any UNTAINTED immediate, including a loop-variant one. The
; whole-loop reverse-play re-emits the rail-mut adjoint (`cqrt_xorc_i32(%h, <imm>)`)
; in the post-loop backward companion block, reusing the FORWARD immediate — a
; loop-body value (`%i`) is undefined there (a dominance violation / broken module:
; `opt -verify` aborts on valid C). E10 guards it: each rail op's classical
; immediate must be loop-INVARIANT (dominate the exit merge — hence the downstream
; reverse-play block). A constant / function-arg immediate passes
; (lowering_loop_break_value.ll, lowering_loop_break_add.ll); a counter-derived
; immediate declines LOUDLY (Prime Directive — over-declining is safe; never emit a
; broken module). Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break body is not a provable rolled single-rail loop
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: Instruction does not dominate

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_loopvar_imm(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %qn = xor i32 %q, %i                               ; LOOP-VARIANT immediate (%i)
  %a0 = and i32 %qn, 3
  %brk = icmp eq i32 %a0, 0
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n
  %exit.cond = select i1 %brk, i1 true, i1 %bound
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
