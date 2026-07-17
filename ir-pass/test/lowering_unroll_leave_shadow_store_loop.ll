; lowering_unroll_leave_shadow_store_loop.ll — LEAVE→DECLINE (3c6m.55 Inc 2
; Lever B, ticket lf8s; the U2b fence probe, store variant): a CONSTANT-trip
; (2) loop doing tainted-index STORE + LOAD through an alloca (the
; Shadow-shaped memory the 7.5 owner adjudicates), with the loop-carried value
; threaded through the memory round-trip — no cq call in-loop, no add/xor
; rail, classical exit, trip 2. Before U2b this unrolled and the straight-line
; residue reached `lowerShadowMemory`, which CRASHED on the self-referential
; store shape (a latent Shadow bug, filed separately — reachable on
; hand-written straight-line input too). U2b must SKIP the loop so it stays
; rolled with the existing L3 owner's loud decline — pinned
; CHARACTER-FOR-CHARACTER.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq QRAM access: tainted-index memory access inside a loop

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @shloop(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 2.500000e-01)
  %arr = alloca [4 x i32], align 16
  br label %loop

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %acc = phi i32 [ %q, %entry ], [ %v, %loop ]
  %sgep = getelementptr inbounds [4 x i32], ptr %arr, i32 0, i32 %acc  ; tainted-index store
  store i32 %acc, ptr %sgep, align 4
  %lgep = getelementptr inbounds [4 x i32], ptr %arr, i32 0, i32 %q    ; tainted-index load
  %v = load i32, ptr %lgep, align 4
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 2                   ; CONSTANT bound — U6 passes
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
