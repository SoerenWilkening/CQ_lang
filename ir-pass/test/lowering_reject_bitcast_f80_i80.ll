; lowering_reject_bitcast_f80_i80.ll — p119.7 DECLINE: an f80<->i80 reinterpret is
; OUT OF SCOPE. `castInScope` admits a bitcast only for a same-BIT-WIDTH fp<->int
; pair at a SHIPPED width; `intBits` has no `i80`, so the width capture returns ""
; for the i80 dest and `rewriteCast` hits `diagnoseNoTemplate` (Prime Directive:
; the six shipped pairs are f16<->i16, f32<->i32, f64<->i64 only; long double
; EXTRACT_WORDS uses a union, not a bitcast). Pins that widening the reinterpret
; family did not silently mint a phantom `cq_template_bitcast_f80_to_i80`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFF8000000000000000, double 5.000000e-01)
  %i = bitcast x86_fp80 %q to i80       ; OUT OF SCOPE: no i80 width
  %t = trunc i80 %i to i32
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}

; CHECK: error{{.*}}no template for opcode 'bitcast i80'
; CHECK-NOT: cq_template_bitcast_f80
