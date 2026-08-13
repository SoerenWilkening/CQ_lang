; lowering_bitcast_fp_to_int.ll — p119.7: the EXTRACT_WORDS half. A tainted f64
; theta handle is REINTERPRETED to i64 (`bitcast double to i64`) and its high word
; read (`lshr`, GET_HIGH_WORD). A tainted same-width fp<->int bitcast is a
; reversible IDENTITY RELABEL (same basis states, new type label, zero gate) —
; lowered like any other cross-domain cast to `cq_template_bitcast_f64_to_i64`
; (arity-1, i32 handle in/out, Rule 15). This is the idiom that opens nearly every
; injected openlibm body (p119 Phase-1 audit) and was formerly declined (iw81.1);
; the f64-as-angle hazard that motivated the old decline is now owned by the
; authoritative angle guard (see lowering_reject_bitcast_angle.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f64(double 5.000000e-01)
; CHECK:     call i32 @cq_template_bitcast_f64_to_i64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: = bitcast
; CHECK-NOT: cq_template_bitcast_i32_to_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i64 @cq_measure_sll(i64)

define i64 @example() {
entry:
  %q  = call double @cq_theta_f64(double 5.000000e-01, double 5.000000e-01)
  %i  = bitcast double %q to i64        ; EXTRACT_WORDS: fp -> int reinterpret
  %hi = lshr i64 %i, 32                 ; GET_HIGH_WORD (supported int op, tainted)
  %m  = call i64 @cq_measure_sll(i64 %hi)
  ret i64 %m
}
