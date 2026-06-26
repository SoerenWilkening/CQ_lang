; lowering_reject_break_nonzero_start.ll — DECLINE (Phase 7.4 Inc 2, y05j.2; the
; Rule-13 finding 2026-06-26 — E7). A value-arm break loop whose classical counter
; STARTS at a non-zero constant (`for (i = 2; i < n; i++)`). The reverse-play
; companion loop replays the body `BoundLimit` (= `n`) times, which equals the
; forward trip count ONLY when the rolled loop (bounded by `icmp eq i.next, n`) runs
; exactly `n` iterations — i.e. the counter starts at 0. A non-zero start makes the
; forward run `n - start` iterations while the backward runs `n` — an OVER-REPLAY
; that leaves `fire`/the rail DIRTY at the `cqrt_free` (a hidden measurement, Rule 6;
; a verify-clean silent miscompile). E7 ties the two trip counts: the counter's
; preheader (start) incoming must be the constant 0; a non-zero start ⇒ LOUD decline
; (Prime Directive: over-declining is safe). Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break body is not a provable rolled single-rail loop
; CHECK-NOT: cqrt_toffoli

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_nonzero_start(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 2
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 2, %entry ], [ %inext, %loop ]      ; NON-ZERO start (2)
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted xor rail
  %qn = xor i32 %q, 5
  %a0 = and i32 %qn, 1
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
