; lowering_switch_value_nonI32_cast.ll — bd p119.8 (same gap as p119.6, for the
; SWITCH value-arm merge). A tainted `switch` with homogeneous VALUE arms over a
; shared routed base %p (an i64 theta) — %p, %p+1, %p+2 — produces a NON-i32 (i64)
; merge that feeds a downstream `trunc i64 -> i32`. The value arms lower (routed
; cqrt_copy_i64 + reverse-play) and RAUW the merge to the i64 out-rail. Without
; SwitchValueEmit recording HandleWidth[out]="i64", the trunc reads the laundered
; i32 and over-declines; with the fix it lowers to cq_template_trunc_i64_to_i32.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=INPUT < %s
;
; CHECK:     call i32 @cq_template_trunc_i64_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: = trunc
; CHECK-NOT: cq_template_trunc_i32
; INPUT: switch i32 %q, label %merge

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_theta_sll(i64, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i64 %p0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i64 @cq_theta_sll(i64 %p0, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %v0 = add i64 %p, 1
  br label %merge
a1:
  %v1 = add i64 %p, 2
  br label %merge
merge:
  %pm = phi i64 [ %p, %entry ], [ %v0, %a0 ], [ %v1, %a1 ]   ; i64 value merge (non-i32)
  %t  = trunc i64 %pm to i32                                  ; cast off the merge (needs From=i64)
  %m  = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
