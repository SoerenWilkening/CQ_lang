; lowering_loop_value_accum_add.ll — ACCEPT (issue dtzb): the `add`-immediate
; sibling of lowering_loop_value_accum (which covers `xor`). A loop-rail
; self-update `q = q + 5` lowers ROLLED IN PLACE to `cqrt_addc_i32(%h, 5)`.
;
; This is an IR-LEVEL fixture (no e2e .c twin) ON PURPOSE: at the C level
; `clang -O1` STRENGTH-REDUCES a constant-step integer accumulator
; (`for(i<n) q += 5`) into a single closed-form `q + 5*n` out-of-place add,
; eliminating the loop-carried rail entirely (also correct, lowered by the normal
; out-of-place path) — so the in-place ADD recognizer only fires on an add loop
; the optimizer did NOT closed-form (here, hand-written IR; in practice a
; non-strength-reducible add). The XOR loop survives `-O1` (parity is not
; closed-formed), so its e2e golden (slice_loop_value_accum) exercises the
; runtime path; this fixture pins the add recognizer/lowering + the `cqrt_addc`
; ABI at the IR level. The inverse (EmitInverse add-negate) is exercised by the
; y05j.2 break reverse-play.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLEAN < %t.cqd0.ll
;
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{.*}})
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      loop:
; CHECK:        call void @cqrt_addc_i32(i32 %[[H]], i32 5)
; CHECK:      exit:
; CHECK-NEXT:   call i32 @cqrt_measure_i32(i32 %[[H]])
;
; CLEAN-NOT:  cq_template_add
; CLEAN-NOT:  cq_theta

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @accum(i32 %seed, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %seed, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %qn = add i32 %q, 5                             ; in-place reversible self-update
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %entry, %loop
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
