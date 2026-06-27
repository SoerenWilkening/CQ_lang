; lowering_reject_break_escape_zerotrip.ll — DECLINE (Phase 7.4 Inc 2, y05j.2; the
; Rule-13 RE-review 2026-06-27 — the escape≠rail fix, E13, ZERO-TRIP edge). The escape
; merge phi carries `RailLat` (`%qn = q ^ 5`) on the loop-exit edge — so the latch-side
; E13 check passes — but a DIFFERENT value (the constant `999`) on the zero-trip bypass
; edge (`int ans = 999; for(…){…; ans = q; …} return measure(ans)`). The post-lowering
; exit consolidation (`idx==0` ⇒ never-broke/zero-trip) copies the RAIL handle into
; `out`, so for n==0 `out` receives the rail's INITIAL value (`q0`) instead of the
; asked-for `999` — a VERIFY-CLEAN WRONG UNITARY on the zero-trip branch. E13 requires
; the escape phi to be exactly {`RailLat` from the latch, `RailPre` from PreB}; the
; zero-trip incoming here is `999` (≠ `RailPre` = `%q0`) ⇒ LOUD decline. This is the
; companion of lowering_reject_break_escape_not_rail.ll (which diverges on the LATCH
; edge); a latch-only check would WRONGLY accept this one. Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break body is not a provable rolled single-rail loop
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: cqrt_copy_i32_controlled

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_ztrip(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %qn = xor i32 %q, 5                                ; RailLat
  %a0 = and i32 %qn, 1
  %brk = icmp eq i32 %a0, 0
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n
  %exit.cond = select i1 %brk, i1 true, i1 %bound
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ 999, %entry ], [ %qn, %loop ]     ; zero-trip = 999 (≠ RailPre %q0)
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
