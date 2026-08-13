; lowering_sitofp_i32_to_f80.ll — ACCEPT (bd 3c6m.5): the cross-domain
; int→long-double cast `sitofp i32 to x86_fp80` (C `(long double)someInt`) now
; LOWERS to the unary cast template `cq_template_sitofp_i32_to_f80(handle)` →
; handle. bd 3c6m.4 shipped the fp-WIDTH f80 grid (fpext/fptrunc) but FENCED the
; cross-domain int<->f80 casts; 3c6m.5 lifts that fence (opcode_table.yaml +
; gen_templates.py + the castInScope isWideFp removal). Casts are arity-1 at the
; IR level and the handle is i32 on BOTH sides regardless of the domain/width
; crossing (Rule 15) — so f80's `long double` c_type never materializes in a
; cast body; the f128 c_type hazard categorically cannot reach casts. RE-PINNED
; from lowering_reject_sitofp_i32_to_f80.ll (Rule 12 baseline flip).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 5)
; CHECK:     call i32 @cq_template_sitofp_i32_to_f80(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call x86_fp80 @cqrt_measure_f80(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = sitofp
; CHECK-NOT: cq_theta_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  %f = sitofp i32 %q to x86_fp80
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %f)
  ret x86_fp80 %m
}
