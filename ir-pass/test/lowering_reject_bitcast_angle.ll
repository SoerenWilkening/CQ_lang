; lowering_reject_bitcast_angle.ll — p119.7 DECLINE (re-points the iw81.1 f64-as-
; angle coverage). Lifting the fp<->int bitcast decline (now a lowerable reversible
; relabel) must NOT open the Rule-3 angle hazard: an `int->fp` bitcast that yields a
; tainted `double` reaching a rotation's ARG-1 ANGLE slot has no fixed unitary
; (angle = f(quantum value)). This is caught by the AUTHORITATIVE angle guard
; `declineTaintedAngle`, which runs in `lowerRotations` — BEFORE `lowerOps` lowers
; the bitcast — so the reinterpreted double is declined as a quantum-derived angle,
; never laundered. (Proven equivalent to the sitofp-produced-angle path.) The old
; `lowering_reject_bitcast_int_to_fp.ll` used a MEASURED float (data, now lowers);
; THIS fixture exercises the actual hazard the exclusion protected.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example() {
entry:
  %qi  = call i64 @cq_theta_sll(i64 7, double 5.000000e-01)   ; tainted i64
  %ang = bitcast i64 %qi to double                            ; int -> fp reinterpret
  %q   = call double @cq_theta_f64(double 5.000000e-01, double 5.000000e-01)
  %r   = call double @cq_phi_f64(double %q, double %ang)       ; tainted %ang in ARG-1 ANGLE slot
  %m   = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: error{{.*}}quantum-derived rotation angle
; CHECK-NOT: cq_template_bitcast
