; lowering_icmp_qq_crossblock.ll — Phase 7.1 Increment A cross-block derived
; positive (R-A minor). Both QQ-compare operands are minted in a DOMINATING
; predecessor block (`entry`) and the data-position compare lives in a successor
; (`cmp`). `HandleWidth` is keyed by `Value*` (block-agnostic), so the recovered
; widths AGREE (i32) across the block boundary and the bare-QQ
; `cq_template_icmp_slt_i32(i32, i32)` lowers — there is no same-block
; assumption in the Increment-A reader. The straight-line `br label` keeps this
; OFF the tainted-control path (no `br i1` on the compare), so `rewriteCompare`
; owns it, not a control emitter.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cq_template_icmp_slt_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = icmp slt
; CHECK-NOT: cq_template_icmp_slt_i32_hl(

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 9, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)
  br label %cmp
cmp:
  ; Operands dominate this block; the QQ data compare recovers each width
  ; (i32) across the block boundary.
  %c = icmp slt i32 %a, %b
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
