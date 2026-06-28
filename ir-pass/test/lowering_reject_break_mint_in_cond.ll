; lowering_reject_break_mint_in_cond.ll — DECLINE (Phase 7.4 Inc 2, y05j.2; the Rule-13
; sign-off round 3, 2026-06-28, E15). The break-cond reads the rail MINT (`int q0 = q;
; … if (q == q0) break;`) — a FROZEN-snapshot comparison. After the dtzb collapse RAUWs
; the rail phi to `Root` (the mint `%q0`) and lowers the in-loop `^5` as the in-place
; `cqrt_xorc_i32(%h, 5)` on `%q0`'s handle `%h`, BOTH the mint `%q0` and the post-mutation
; rail `%qn` become the SAME handle `%h`. So the break flag `icmp eq %qn, %q0` lowers to
; `cq_template_icmp_eq_i32(%h, %h)` — the rail compared to ITSELF, unconditionally true —
; firing the break on iteration 0 and capturing `q0^5` instead of the intended `q0`: a
; VERIFY-CLEAN WRONG UNITARY, the break decision fully decoupled from the user predicate.
; E8 forbids reading the rail phi / intermediate rail ops and E9 forbids an UNTAINTED
; header operand, but the mint is TAINTED and preheader-defined, so both skip it. E15
; requires the mint (`Root` == `RailPre`) to be read ONLY by the rail phi (loop-entry
; incoming) and the escape phi (zero-trip incoming — n==0, rail unmutated, correct); the
; break-cond `icmp eq %qn, %q0` is a third reader ⇒ LOUD decline. (A frozen-mint snapshot
; would need a separately allocated copy — a near-term widening; Prime Directive: over-
; declining is safe.) Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break body is not a provable rolled single-rail loop
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: cqrt_copy_i32_controlled

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_mint(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)   ; the mint (Root == RailPre)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %qn = xor i32 %q, 5                                ; RailLat
  %brk = icmp eq i32 %qn, %q0                        ; break-cond reads the MINT %q0
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n
  %exit.cond = select i1 %brk, i1 true, i1 %bound
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; escape == {RailPre=%q0, RailLat=%qn} (passes E13/E14)
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
