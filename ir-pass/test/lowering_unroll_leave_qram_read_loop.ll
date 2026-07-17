; lowering_unroll_leave_qram_read_loop.ll — LEAVE→DECLINE (3c6m.55 Inc 2
; Lever B, ticket lf8s; the U2b fence probe — the lf8s Rule-13 review's
; CONFIRMED BLOCKING find, now closed): a CONSTANT-trip (2) loop reading a
; const-global table through a DIRECT tainted-index gep, accumulated by a
; two-tainted `mul` (not an add/xor rail — U4 blind; no cq call — U2 blind;
; classical exit — U3/U5 blind; trip 2 — U6 passes). Before U2b this evaded
; every fence clause, unrolled, and the straight-line result was SILENTLY
; ACCEPTED into `cqrt_qram_*` — converting the rolled form's loud L3 decline
; into an unreviewed accept. U2b (a memory access / address arithmetic with a
; TAINTED operand in the loop) must SKIP, so the loop stays rolled and the
; existing L3 owner declines it — pinned CHARACTER-FOR-CHARACTER against
; `QramLowering.cpp`'s `kMsgQramLoop`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq QRAM access: tainted-index memory access inside a loop

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@T = internal constant [4 x i32] [i32 10, i32 20, i32 30, i32 40], align 4

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @qloop2(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 2.500000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %acc = phi i32 [ %q, %entry ], [ %sum, %loop ]
  %gep = getelementptr inbounds [4 x i32], ptr @T, i32 0, i32 %q  ; DIRECT tainted index
  %v = load i32, ptr %gep, align 4
  %sum = mul i32 %acc, %v                         ; two-tainted mul — no U4 rail
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 2                   ; CONSTANT bound — U6 passes
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %sum)
  ret i32 %m
}
