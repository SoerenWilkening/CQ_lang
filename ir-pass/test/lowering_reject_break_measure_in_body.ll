; lowering_reject_break_measure_in_body.ll — DECLINE (Phase 7.4 Inc 2, y05j.2; the
; Rule-13 FINAL review 2026-06-26). A value-arm break loop with a `cq_measure` (or
; any observable / side-effecting op) INSIDE the body. The rolled break virtualizes
; the early exit by running the body its FULL classical trip count AND the whole-loop
; reverse-play replays it — sound ONLY for a pure-coherent-reversible body. An in-body
; `cq_measure` would (a) violate Rule 5 (the compiler emits a measurement the user's
; control flow never reaches — it fires ~2n times: full-trip forward + reverse-play)
; and (b) be an irreversible op the adjoint cannot undo. `tryBreak`'s body scan
; declines any body op that `mayHaveSideEffects()` (a `cq_measure` / side-effecting
; call / volatile-atomic store), riding the existing L1 `loop under quantum control`
; (the body is not the proven pure-coherent single-break shape). The canonical
; value-arm break body is pure arithmetic + phis (the rail mint lives in the
; preheader), so this never over-declines it. Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: cqrt_copy_i32_controlled

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_measure_body(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %qn = xor i32 %q, 5
  %m = call i32 @cq_measure_si32(i32 %qn)            ; MEASURE inside the body
  %a0 = and i32 %qn, 1
  %brk = icmp eq i32 %a0, 0
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n
  %exit.cond = select i1 %brk, i1 true, i1 %bound
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %mm = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %mm
}
