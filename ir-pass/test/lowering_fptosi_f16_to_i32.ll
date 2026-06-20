; lowering_fptosi_f16_to_i32.ll — Phase 7.1 Increment D: a cross-domain
; fp->int cast FROM f16. A tainted `half` theta handle flows through
; `fptosi half to i32` and lowers to `cq_template_fptosi_f16_to_i32(handle)`.
; This pins (1) the f16 fp->int cast direction (castInScope: fptosi excludes an
; i1 DEST but i32 is fine; the f16 SOURCE is in scope) and (2) the cast-fix's
; HandleWidth recovery for an f16 source (the half theta is laundered to an i32
; handle before capture; the source width is recovered as "f16", not "i32").
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f16(half 0xH4000)
; CHECK:     call i32 @cq_template_fptosi_f16_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: cq_template_fptosi_i32_to_i32
; CHECK-NOT: = fptosi
; CHECK-NOT: cq_theta_f16

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare half @cq_theta_f16(half, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %a = call half @cq_theta_f16(half 0xH4000, double 5.000000e-01)
  %i = fptosi half %a to i32
  %m = call i32 @cq_measure_si32(i32 %i)
  ret i32 %m
}
