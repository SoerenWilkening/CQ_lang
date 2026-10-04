; lowering_reject_break_preloop_mutation.ll — DECLINE (Phase 7.4 Inc 2, y05j.2; the
; Rule-13 sign-off 2026-06-28, E14). The rail has a PRE-LOOP in-place mutation between
; its mint and the loop (`cq_theta(&q, …); q = q ^ 7; for(…){ q = q ^ 5; … }`). The dtzb
; collapse RAUWs the rail phi to `Root = peelInPlaceBase(RailPre)`, which peels THROUGH
; the pre-loop `^7` to the BARE MINT (`%q0`), and marks only the IN-LOOP rail ops
; (`^5`) as InPlaceRailOps — so the pre-loop `^7` orphans to a DEAD out-of-place
; `cq_template_xor` handle and is NEVER applied to the rail handle. The post-lowering
; capture (BreakReversePlay.cpp) copies that rail handle (`= q0 ^ 5^k`) into `out`,
; DROPPING the `^7` — a VERIFY-CLEAN WRONG UNITARY (out off by the pre-loop mutation).
; E13 (escape == RailPre) does NOT catch this: the escape phi correctly carries RailPre
; (`%qpre = q0 ^ 7`) on the zero-trip edge; the divergence is `Root` (`%q0`) ≠ RailPre.
; E14 requires `Root == RailPre` (the rail entering the loop IS the bare mint — no
; pre-loop in-place rail mutation) ⇒ here `Root` (`%q0`) ≠ RailPre (`%qpre`) ⇒ LOUD
; decline. (Pre-loop-mutation support is a near-term widening, not this increment's
; proven shape — Prime Directive: over-declining is safe.) Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break body is not a provable rolled single-rail loop
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: cqrt_copy_i32_controlled

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_preloop(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %qpre = xor i32 %q0, 7                             ; PRE-LOOP in-place rail mutation
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %qpre, %entry ], [ %qn, %loop ]     ; RailPre = %qpre (= q0 ^ 7), not the bare mint
  %qn = xor i32 %q, 5                                ; RailLat
  %a0 = and i32 %qn, 1
  %brk = icmp eq i32 %a0, 0
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n
  %exit.cond = select i1 %brk, i1 true, i1 %bound
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %qpre, %entry ], [ %qn, %loop ]   ; escape == rail on both edges (passes E13)
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
