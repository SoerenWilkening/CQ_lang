; lowering_unroll_leave_alloca_tainted_size.ll — LEAVE→DECLINE (3c6m.55 Inc 2
; Lever B, ticket lf8s; the U2b alloca-class probe — the fix-delta Rule-13
; re-review's find, now closed): a CONSTANT-trip (2) loop containing a DEAD
; TAINTED-SIZE dynamic `alloca` (its only user a dead `ptrtoint`). An alloca
; is neither a gep nor mayReadFromMemory/mayWriteToMemory, so the first U2b
; draft was blind to it — the loop unrolled and `UnrollLoop`'s internal
; trivially-dead cleanup deleted the dead tainted consumer BEFORE the escape
; guard ran, silently converting the rolled form's loud decline into an
; accept (unitary-equivalent since the deleted code was dead and
; side-effect-free, but a decline→accept conversion without per-shape review
; violates the fence contract). With `AllocaInst` in the U2b class the fence
; SKIPS, the loop stays rolled, and the escape guard declines — pinned
; CHARACTER-FOR-CHARACTER, the same diagnostic the straight-line form gets.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value reaches an unsupported instruction

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @aloop(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 2.500000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %acc = phi i32 [ %q, %entry ], [ %sum, %loop ]
  %buf = alloca i8, i32 %acc, align 1             ; DEAD tainted-size alloca
  %pi = ptrtoint ptr %buf to i32                  ; dead user — DCE bait
  %sum = mul i32 %acc, 3                          ; tainted mul — no U4 rail
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 2                   ; CONSTANT bound — U6 passes
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %sum)
  ret i32 %m
}
