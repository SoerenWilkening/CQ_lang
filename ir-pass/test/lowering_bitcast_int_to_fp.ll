; lowering_bitcast_int_to_fp.ll — p119.7: the INSERT_WORDS half. A tainted i64
; theta handle is bit-manipulated (`or`, set a mantissa bit) then REINTERPRETED
; back to a double (`bitcast i64 to double`) and measured as f64. The int->fp
; reinterpret lowers to `cq_template_bitcast_i64_to_f64` — the reversible identity
; relabel that closes the EXTRACT/INSERT_WORDS round-trip. The produced double is
; DATA (measured here); an int->fp bitcast whose result reaches a rotation arg-1
; ANGLE is still declined by the angle guard (lowering_reject_bitcast_angle.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i64(i64 7)
; CHECK:     call i32 @cq_template_bitcast_i64_to_f64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call double @cqrt_measure_f64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: = bitcast
; CHECK-NOT: cq_template_bitcast_f64_to_f64

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)
declare double @cq_measure_f64(double)

define double @example() {
entry:
  %q = call i64 @cq_theta_sll(i64 7, double 5.000000e-01)
  %b = or i64 %q, 1                    ; set a mantissa bit (supported int op, tainted)
  %f = bitcast i64 %b to double        ; INSERT_WORDS: int -> fp reinterpret
  %m = call double @cq_measure_f64(double %f)
  ret double %m
}
