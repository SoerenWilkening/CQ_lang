; lowering_reject_break_intermediate_rail.ll — DECLINE (Phase 7.4 Inc 2, y05j.2;
; the Rule-13 RE-review 2026-06-26 — E8 multi-op generalization). A MULTI-OP rail
; chain (`q1 = q ^ 9; q2 = q1 + 3`) whose break-cond reads the INTERMEDIATE rail
; value `%q1` (after the xor, before the add), NOT the final post-all-mutations
; value `%q2` (which the escape phi carries). The dtzb collapse RAUWs every rail
; value onto the ONE in-place handle `%h`, and the two mutations run in program
; order (`cqrt_xorc(%h, 9)` then `cqrt_addc(%h, 3)`), so a break-cond reading the
; intermediate would read the FINAL value `%h` (post-both) instead of the intended
; post-xor-only value — a verify-clean WRONG UNITARY (off by the second mutation).
; E8 guards EVERY non-final rail value (the header phi + every intermediate mutation
; result): each must be consumed ONLY by the in-place mutation chain; reading an
; intermediate (`%q1` here is also read by `%a0 = and %q1, 1`) ⇒ LOUD decline. Only
; `RailLat` (the final `%q2`) may be read by the break-cond (lowering_loop_break_*).
; Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break body is not a provable rolled single-rail loop
; CHECK-NOT: cqrt_toffoli

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_inter(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %q2, %loop ]
  %q1 = xor i32 %q, 9                                ; first rail mutation
  %q2 = add i32 %q1, 3                               ; second (final) rail mutation
  %a0 = and i32 %q1, 1                               ; break-cond reads INTERMEDIATE %q1
  %brk = icmp eq i32 %a0, 0
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n
  %exit.cond = select i1 %brk, i1 true, i1 %bound
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %q2, %loop ]     ; answer = FINAL %q2
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
