; p3 — the D5-SANCTIONED shape, and the POSITIVE CONTROL for the whole fix: a
; rail-bank cell is stored, then loaded, and the load result's ONLY use is the
; user's `cq_measure`. This is the L-1a design target
; ($SESP/trackL/probes/TARGET_rolled_stage2.ll, trimmed to one cell and one
; trip). It must keep VERIFYING after the fix — a checker that refuses the
; increment's own emitted shape is an over-decline, not a safety margin.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() local_unnamed_addr {
entry:
  %bank = alloca [1 x i32], align 4, !cq.railbank !0
  %ha = call i32 @cqrt_alloc_i32(i32 5)
  %f = call i32 @cq_template_icmp_sgt_i32_hl(i32 %ha, i32 2)
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1_controlled(i32 %f, i32 %hb, double 5.000000e-01)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %f, i32 %ha, i32 2)
  call void @cqrt_free(i32 %f)
  %cell = getelementptr inbounds [1 x i32], ptr %bank, i64 0, i64 0
  store i32 %hb, ptr %cell, align 4
  %v = load i32, ptr %cell, align 4
  %m = call i1 @cqrt_measure_i1(i32 %v)
  %z = zext i1 %m to i32
  ret i32 %z
}

declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)

!0 = !{!"i1"}
