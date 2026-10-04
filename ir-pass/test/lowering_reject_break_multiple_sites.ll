; lowering_reject_break_multiple_sites.ll — DECLINE (Phase 7.4 Inc 1, y05j.1;
; PRD-7.4 §2.7, §2.10 multiple-site row): a classically-bounded loop with TWO
; tainted-condition early breaks:
;     int q = x; cq_theta(&q, 0.25);
;     for (int i = 0; i < n; i++) {
;         q = q ^ 9;
;         if ((q & 1) == 0) break;   // tainted break #1
;         q = q + 3;
;         if ((q & 2) == 0) break;   // tainted break #2
;     }
;     return cq_measure(q);
;
; Verified against real `clang -O1` output (Rule 11, /tmp/spike/v3_multi.ll): TWO
; exiting blocks carry a tainted condition (the bare `%brk1` and the fused
; `select(%brk2, true, %bound)`), and the exit merge phi has THREE incomings.
; `tryBreak` counts >1 tainted exiting block ⇒ multiple early-break sites. This is
; an INTERIM decline: Increment 3 (y05j.3) accepts it (the O(1) monotone first-
; break INDEX latch gives first-in-program-order-wins with NO per-site exit-priority
; cascade — §2.7); it is NOT a permanent deferral. Decline-safe today (Prime
; Directive). Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: multiple early-break sites

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_multi(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %body2
  %i = phi i32 [ 0, %entry ], [ %inext, %body2 ]
  %q = phi i32 [ %q0, %entry ], [ %q2, %body2 ]
  %qn = xor i32 %q, 9
  %a0 = and i32 %qn, 1
  %brk1 = icmp eq i32 %a0, 0                       ; TAINTED break #1 (bare exit)
  br i1 %brk1, label %exit, label %body2

body2:                                            ; preds = %loop
  %q2 = add i32 %qn, 3
  %a1 = and i32 %q2, 2
  %brk2 = icmp eq i32 %a1, 0                       ; TAINTED break #2
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n                  ; CLASSICAL bound
  %exit.cond = select i1 %brk2, i1 true, i1 %bound ; FUSED exit
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %body2, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ], [ %q2, %body2 ]
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
