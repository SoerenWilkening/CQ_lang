; lowering_reject_sitofp_i32_to_f80.ll — DECLINE: a cross-domain int→long-double
; cast (`sitofp i32 to x86_fp80`, the C `(long double)someInt`) loud-declines. bd
; 3c6m.4 ships the fp-WIDTH cast grid for f80 (fpext/fptrunc) but FENCES the
; cross-domain int<->fp casts OUT of castInScope (parallel to the i128<->fp
; deferral) — so `sitofp`/`uitofp` to f80 and `fptosi`/`fptoui` from f80 have no
; template and decline loudly, never minting a phantom
; cq_template_sitofp_i32_to_f80 the YAML does not carry (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)  ; tainted i32
  %f = sitofp i32 %q to x86_fp80                               ; cross-domain, FENCED
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %f)
  ret x86_fp80 %m
}

; CHECK: error{{.*}}no template for opcode 'sitofp x86_fp80' in tainted context
; CHECK-NOT: cq_template_sitofp_i32_to_f80
