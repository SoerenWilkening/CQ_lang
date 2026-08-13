; lowering_unroll_leave_identity_carry.ll — LEAVE→ROLLED (3c6m.55 Inc 2 Lever B,
; ticket lf8s; the U4(b) zero-hop probe): a CONSTANT-trip loop carrying the
; tainted register UNCHANGED (`%q = phi [%q0, entry], [%q, loop]` — the latch
; incoming IS the phi itself). There is no in-place-shaped op anywhere in the
; loop, so U4(a) is blind to it; only the U4(b) peel test (zero hops:
; `peelInPlaceBase(LatV) == &P`) recognizes the Case-A claim seed and keeps the
; force-unroll pre-pass off. `tryCaseA` must claim it exactly as before Lever B:
; the identity rail collapses onto the mint handle, the (now purely-classical)
; loop CFG survives, and the measure reads the invariant handle.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      loop:
; CHECK:        br i1 %{{[a-zA-Z0-9_.]+}}, label %exit, label %loop
; CHECK:      exit:
; CHECK-NEXT:   call i32 @cqrt_measure_i32(i32 %[[H]])

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @idcarry(i32 %u0) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %q, %loop ]     ; identity carry — zero-hop rail
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3                   ; CONSTANT bound — U6 passes
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
