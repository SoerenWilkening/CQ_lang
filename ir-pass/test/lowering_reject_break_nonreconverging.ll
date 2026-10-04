; lowering_reject_break_nonreconverging.ll — DECLINE (Phase 7.4 Inc 1, y05j.1;
; PRD-7.4 §2.5 B2, §2.10 non-reconverging row): a classically-bounded loop whose
; single tainted early break and natural (classical-bound) exit reach DISTINCT
; blocks — there is no single loop-exit merge phi carrying the escaping answer:
;     int q = x; cq_theta(&q, 0.25);
;     for (int i = 0; i < n; i++) {
;         q = q ^ 9;
;         if ((q & 1) == 0) goto brk_exit;   // break -> a distinct exit
;     }
;     // natural exit -> nat_exit
;
; Verified shape (Rule 11, cf. /tmp/spike/v4_nonreconv.ll, the early-return proxy):
; the loop has ONE tainted exiting block (the break, to %brk_exit) and one CLASSICAL
; exiting block (the bound, to %nat_exit) — two DISTINCT exit blocks, so
; `Loop::getExitBlock()` is null. The §2.2 capture + reverse-play assumes the break
; edge and the natural exit converge to one merge block with one escaping merge phi
; (the 7.2 reconvergence fence); a non-reconverging break has no such single answer
; to capture ⇒ DECLINE → defer (§2.7). Decline-safe today (Prime Directive).
; Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break does not reconverge

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_nonreconv(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  br label %loop

loop:                                             ; preds = %entry, %cont
  %i = phi i32 [ 0, %entry ], [ %inext, %cont ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %cont ]
  %qn = xor i32 %q, 9
  %a0 = and i32 %qn, 1
  %brk = icmp eq i32 %a0, 0                        ; TAINTED break flag
  br i1 %brk, label %brk_exit, label %cont         ; break -> %brk_exit (distinct)

cont:                                             ; preds = %loop
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n                  ; CLASSICAL bound
  br i1 %bound, label %nat_exit, label %loop       ; natural exit -> %nat_exit (distinct)

brk_exit:                                         ; preds = %loop
  %m1 = call i32 @cq_measure_si32(i32 %qn)
  ret i32 %m1

nat_exit:                                         ; preds = %cont
  %m2 = call i32 @cq_measure_si32(i32 %qn)
  ret i32 %m2
}
