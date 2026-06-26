; lowering_reject_break_stray_taint.ll — DECLINE (Phase 7.4 Inc 2, y05j.2; the
; Rule-13 RE-review 2026-06-26 — E11 body coverage). A value-arm break body that
; carries a STRAY tainted value (`%z = and %qn, 2`) beyond the single rail + single
; break-cond. The forward transform (`emitBreakForward`) RAUWs the exit phi to `out`
; and strips the terminator BEFORE the post-lowering capture; the post-lowering
; structural re-scan (`discoverLoweredBreak`) then enforces a SINGLE break-flag
; compare. A stray tainted value (a second compare, an extra producer) would break
; that re-scan, and a silent return there would leave `out` = |0> (a silent wrong
; answer). E11 closes the loop: every TAINTED value in the body block must be a rail
; value (`RailPhi` / a `RailOp`), a break-cond op, or the fused exit terminator —
; a stray tainted body value ⇒ LOUD decline BEFORE any mutation (keeping the forward
; transform and the post-lowering emission in lock-step; Prime Directive — over-
; declining is safe; never emit a half-transformed `out` = |0>). Mirror-exact
; (Rule 12). (`clang -O1` would DCE such a dead tainted value; this hand-written IR
; is the coverage-check vehicle.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break body is not a provable rolled single-rail loop
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: break reverse-play could not re-derive

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_stray(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %qn = xor i32 %q, 5
  %a0 = and i32 %qn, 1
  %brk = icmp eq i32 %a0, 0
  %z = and i32 %qn, 2                                ; STRAY tainted body value
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n
  %exit.cond = select i1 %brk, i1 true, i1 %bound
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
