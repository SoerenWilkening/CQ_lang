; lowering_loop_break_unsigned.ll — POSITIVE recognition (Phase 7.4 Inc 2, y05j.2;
; PRD-7.4 §2.8). The UNSIGNED-bound twin of lowering_loop_break_value.ll: a
; classically-bounded, DATA-MUTATING loop with a SINGLE tainted-condition value-arm
; early break, measured after, but with an UNSIGNED trip bound:
;     int q = cq_theta(x, 0.25);
;     for (unsigned i = 0; i < n; i++) {   // UNSIGNED counter + bound
;         q = q ^ 9;                        // value mutation (the dirty rail)
;         if ((q & 1) == 0) break;          // TAINTED value-arm break
;     }
;     return cq_measure(q);
;
; Verified against real `clang -O1` output (Rule 11, $SP/uns_s1.ll): for an UNSIGNED
; loop the zero-trip ENTRY guard is `icmp eq %n, 0` with the loop body as the FALSE
; successor (`br i1 %guard, label %exit, label %loop`) — the OPPOSITE polarity of the
; signed `icmp sgt %n, 0` (loop on TRUE) guard in the value/add/step fixtures.
;
; THE POINT OF THIS FIXTURE — the E12 guard-reuse fix (Rule-13 FINAL round, the
; CRITICAL signed-guard finding): the backward reverse-play companion loop MUST reuse
; the FORWARD zero-trip guard, not re-invent a signed `sgt(n, 0)`. A re-invented
; `sgt(n, 0)` is FALSE for any unsigned `n ≥ 2^31` while this loop's forward guard
; (`enter iff n != 0`) is TRUE — so the forward loop would capture into R/idx while the
; backward reverse-play is SKIPPED, freeing R/idx DIRTY (a Rule-6 hidden measurement,
; a SILENT miscompile). `emitBreakForward` captures `Rgn.GuardCond`/`GuardLoopOnTrue`
; (LoopLowering.cpp E12); `lowerBreakReversePlay` reuses it — here, since the loop is
; the guard's FALSE successor, the backward guard is the inverted forward guard
; `xor i1 %guard, true` (BreakReversePlay.cpp `CreateNot`). The lowered module is
; `opt -verify` clean and every forward `cqrt_*` has its backward adjoint.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; CHECK: %[[GUARD:[a-z0-9.]+]] = icmp eq i32 %n, 0
; CHECK: br i1 %[[GUARD]], label %{{.*}}, label %[[LOOP:[a-z0-9.]+]]
; The rolled rail collapse + the index-gated capture (forward body):
; CHECK: call void @cqrt_xorc_i32(i32 %[[H:[a-z0-9]+]], i32 9)
; CHECK: call void @cqrt_toffoli(
; CHECK: call void @cqrt_copy_i32_controlled(i32 %{{.*}}, i32 %[[H]], i32 %cq.brk.R)
; The exit copy-out:
; CHECK: call void @cqrt_copy_i32(i32 %cq.brk.R, i32 %cq.brk.out)
; The E12 backward guard — the inverted forward guard, NOT a fresh sgt(n,0):
; CHECK: %cq.brk.guard = xor i1 %[[GUARD]], true
; CHECK: br i1 %cq.brk.guard, label %cq.brk.rev, label %cq.brk.tail
; CHECK: cq.brk.rev:
; CHECK: call void @cqrt_xorc_i32(i32 %[[H]], i32 9)
; Frees AFTER the backward loop, then the measure of the disentangled out:
; CHECK: cq.brk.tail:
; CHECK: call void @cqrt_free(i32 %cq.brk.R)
; CHECK: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK: call i32 @cqrt_measure_i32(i32 %cq.brk.out)
; CHECK-NOT: cq controlled lowering: loop under quantum control
; CHECK-NOT: cq loop lowering: early break emission not yet implemented

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_unsigned(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp eq i32 %n, 0                          ; UNSIGNED zero-trip guard
  br i1 %guard, label %exit, label %loop              ; loop is the FALSE successor

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]      ; classical induction (unsigned)
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted value-mutating rail
  %qn = xor i32 %q, 9                                ; value mutation (tainted)
  %a0 = and i32 %qn, 1
  %brk = icmp eq i32 %a0, 0                          ; TAINTED break flag
  %inext = add nuw i32 %i, 1
  %bound = icmp eq i32 %inext, %n                    ; CLASSICAL loop bound
  %exit.cond = select i1 %brk, i1 true, i1 %bound    ; FUSED select(brk, true, bound)
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; value-class escaping answer
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
