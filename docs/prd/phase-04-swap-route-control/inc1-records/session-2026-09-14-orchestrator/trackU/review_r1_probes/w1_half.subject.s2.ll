; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/w1_half.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/w1_half.ll"
target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

define half @example() {
entry:
  %h = call i32 @cqrt_alloc_f16(half 0xH0000)
  call void @cqrt_ry_f16(i32 %h, double 5.000000e-01)
  %m1 = call half @cqrt_measure_f16(i32 %h)
  ret half %m1
}

declare void @cqrt_ry_f16(i32, double)

declare i32 @cqrt_alloc_f16(half)

declare half @cqrt_measure_f16(i32)
