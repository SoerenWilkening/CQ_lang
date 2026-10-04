; lowering_loop_value_accum.ll — ACCEPT (issue dtzb, the in-place reversible
; arithmetic strategy): the VALUE twin of lowering_loop_phase_accum_dynamic. A
; classically-bounded loop over an in-place-mutated VALUE rail
;     int q = seed; cq_theta(&q, 0.25);
;     for (int i = 0; i < n; i++) q = q ^ 9;        // n a runtime param
;     return cq_measure(q);
; lowers ROLLED IN PLACE. Today (7.3) the rail `%qn = xor %q, 9` threads a FRESH
; out-of-place `cq_template_xor` handle through the header phi each iteration —
; the X1 cross-iteration dirty rail (lowering_reject_loop_cross_iter.ll). dtzb
; recognizes the loop-rail SELF-UPDATE (one tainted operand + a CLASSICAL
; immediate, opcode add/xor — a reversible bijection) and lowers it IN PLACE on
; the single rail handle: `cqrt_xorc_i32(%h, 9)` rolled in the body (the value
; analogue of Case A's `cqrt_rz`), the loop-carried header phi AND the
; zero-trip/exit merge phi collapse to the one rail, ZERO uncompute, ZERO frees.
; Bennett.jl's in-place adder (src/adder.jl): the result OVERWRITES the rail.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLEAN < %t.cqd0.ll
;
; Mint + Ry in the preheader, in place; the classical zero-trip guard is UNTOUCHED:
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{.*}})
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      br i1 %{{.*}}, label %loop, label %exit
; The rolled body: ONE in-place xor-immediate on the loop-invariant handle:
; CHECK:      loop:
; CHECK:        call void @cqrt_xorc_i32(i32 %[[H]], i32 9)
; The exit measures the ONE handle; BOTH rail phis are GONE (the measure reads
; the handle directly, not a surviving exit merge phi):
; CHECK:      exit:
; CHECK-NEXT:   call i32 @cqrt_measure_i32(i32 %[[H]])
;
; The out-of-place data template is NEVER emitted (the whole point — no fresh
; per-iteration rail), and the rail mints/frees are gone (whole-input scan):
; CLEAN-NOT:  cq_template_xor
; CLEAN-NOT:  cq_theta
; CLEAN-NOT:  cqrt_free

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @accum(i32 %seed, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %seed, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit         ; classical zero-trip guard

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]    ; loop-carried VALUE rail
  %qn = xor i32 %q, 9                             ; in-place reversible self-update
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n                  ; classical exit condition
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %entry, %loop
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]  ; zero-trip / exit merge phi
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
