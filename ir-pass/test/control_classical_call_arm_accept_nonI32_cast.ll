; control_classical_call_arm_accept_nonI32_cast.ll — bd p119.8 (Rule-13 clearance
; hardening: the THIRD merge emitter's consumer path). The 6.5 classical-call arm
; (`int64_t y = 5; if (q>3) y = f(a);`) merges a pure classical i64 call result into
; the controlled register. Here the NON-i32 (i64) merge feeds a downstream
; `trunc i64 -> i32`, exercising the ClassicalCallArmEmit HandleWidth[out]="i64"
; record (the existing ...accept_i64_measure.ll consumes its merge through a MEASURE,
; which re-types its own result and never reads HandleWidth — so it does not pin the
; cast/compare consumer this p119.8 line feeds). Without the record, the trunc reads
; the laundered i32 (getSrcTy after RAUW) and over-declines; with it, it recovers
; "i64" and lowers to cq_template_trunc_i64_to_i32. The merge is an UntaintedMergeRail,
; so the trunc lowers in the round-2 repropagateControlMerges re-seed — proving the
; recorded width persists across the second pass.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=INPUT < %s
;
; CHECK:     call void @cqrt_copy_i64_controlled(
; CHECK:     call i32 @cq_template_trunc_i64_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: = trunc
; CHECK-NOT: cq_template_trunc_i32
; INPUT: br i1 %c, label %arm, label %merge

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatablePureCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_reject_partial_callee.ll (a VISIBLE partial body,
; also declined). Nothing else in this fixture changes; the body is inert.
define i64 @f(i64 %a) #0 {
  %s = add i64 %a, 100
  ret i64 %s
}

define i32 @example(i32 %u0, i64 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i64 @f(i64 %a)                          ; pure classical i64 call
  br label %merge
merge:
  %y = phi i64 [ %r, %arm ], [ 5, %entry ]          ; i64 classical-call merge (non-i32)
  %t = trunc i64 %y to i32                           ; cast off the merge (needs From=i64)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
