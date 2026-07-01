; lowering_reject_tainted_angle_f80.ll — DECLINE: a long-double value that is
; quantum-derived, then narrowed to the `double` angle slot of a rotation, STILL
; loud-declines (the angle fence generalizes to every width — bd 3c6m.4 adds no
; new angle hazard). `%s` is a tainted x86_fp80; `(double)%s` (fptrunc f80→f64) is
; therefore tainted; feeding it to `cq_phi`'s arg-1 has NO fixed unitary (angle =
; f(quantum value) in superposition), so RotationLowering::declineTaintedAngle
; fires BEFORE any emission — never laundering a long-double angle through the new
; f80 templates. Mirrors lowering_reject_tainted_angle_cast.ll at the f80 width.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(x86_fp80 %u0, double %v0) {
entry:
  %s   = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)  ; tainted f80
  %ang = fptrunc x86_fp80 %s to double                                    ; tainted angle
  %q   = call double @cq_theta_f64(double %v0, double 1.000000e-01)
  %qd  = call double @cq_phi_f64(double %q, double %ang)                  ; arg-1 tainted
  %m   = call double @cq_measure_f64(double %qd)
  ret double %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; Declined inside lowerRotations, BEFORE lowerOps — no f80 template is minted:
; CHECK-NOT: cq_template_fptrunc_f80
; CHECK-NOT: cqrt_rz
