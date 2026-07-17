; lowering_unroll_leave_caseA_rail.ll — LEAVE→ROLLED-IN-PLACE (3c6m.55 Inc 2
; Lever B, ticket lf8s; THE 799w non-clobber probe, fence U4): a CONSTANT-trip
; (3) dtzb in-place value rail `for (i<3) q ^= 9` — NO cq call inside the loop,
; classical exit, proven trip ≤ 8, tainted values in the body: every OTHER
; fence condition passes, so ONLY the shared rail-structure gate
; (`loopHasInPlaceRailStructure` — the same `inPlaceValueRailOperand` /
; `peelInPlaceBase` predicates `tryCaseA` claims with) keeps the force-unroll
; pre-pass off this loop. It must lower EXACTLY as before Lever B: the Case-A
; collapse onto ONE loop-invariant handle with the loop CFG SURVIVING —
; `cqrt_xorc_i32(%h, 9)` rolled in the body, the backedge intact, the measure
; on the invariant handle. (The existing 799w fixtures are all
; ARGUMENT-bounded, which the U6 constant-trip fence also skips — this fixture
; is the only sentinel for the constant-bounded rail, where U4 is the SOLE
; protection. An unrolled 3× xorc stream would be trace-identical but is
; forbidden drift: rolled-in-place is the 799w contract.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck --check-prefix=CLEAN %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; The loop SURVIVES, rolled, with the one in-place xor on the invariant handle:
; CHECK:      loop:
; CHECK:        call void @cqrt_xorc_i32(i32 %[[H]], i32 9)
; CHECK:        br i1 %{{[a-zA-Z0-9_.]+}}, label %exit, label %loop
; CHECK:      exit:
; CHECK-NEXT:   call i32 @cqrt_measure_i32(i32 %[[H]])
;
; Exactly ONE xorc call — an unrolled 3× stream is the drift this probe pins out:
; CLEAN:      call void @cqrt_xorc_i32
; CLEAN-NOT:  call void @cqrt_xorc_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @railconst(i32 %u0) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]    ; in-place value rail
  %qn = xor i32 %q, 9
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3                   ; CONSTANT bound — U6 passes
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %qn)
  ret i32 %m
}
