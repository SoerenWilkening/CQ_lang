; lowering_icmp_qq_negative.ll — Q+Q data-position compare is UNSUPPORTED in
; Phase 3 and must be diagnosed LOUDLY (not silently mis-lowered). Two theta
; handles (both tainted) compared with `icmp slt` hit the both-operands-
; tainted branch of `rewriteCompare`. The logical width is genuinely
; unrecoverable here: after rotation lowering both operands are i32-laundered
; alloc handles, so there is no classical operand to read a real width from.
; Falling back to operand 0's laundered i32 type would silently emit a
; wrong/nonexistent symbol (e.g. `cq_template_fcmp_une_i32` for a float QQ
; compare — wrong width AND an integer-compare name on a float compare) with
; no diagnostic. So this case calls `diagnoseNoTemplate` and leaves the
; compare un-lowered, exactly like every other unsupported path in the pass.
;
; The compare result is routed to a measure (`cq_measure_i1`), NOT a `br`/
; `select` condition, so it is genuinely DATA-POSITION: `isDataPositionCompare`
; returns true, the driver enqueues it, and `rewriteCompare` then DIAGNOSES it
; (a branch-feeding compare would be gated out and never reach the diagnostic).
;
; Negative fixture: the loud diagnostic makes `cq-opt` exit non-zero, so
; `not` is required (modeled on the old `lowering_sub_negative.ll` shape).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: error{{.*}}no template{{.*}}
;
; The QQ compare must NOT be lowered to any compare template.
; CHECK-NOT: cq_template_icmp
; CHECK-NOT: cq_template_fcmp

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 9, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)
  ; Both operands tainted → Q+Q compare, unsupported in Phase 3 → diagnosed.
  ; Result flows to a measure (data position), so it is enqueued, not gated.
  %c = icmp slt i32 %a, %b
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
