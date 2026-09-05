; control_inplace_ry_stateprep_fcmp_oeq_derived_accept.ll — ACCEPT, the one-token
; control for `..._reject_stateprep_fcmp_oeq_derived.ll`.
;
; It is that module with the seed changed from `15.0` to `16.0` and NOTHING else.
; `%t` is still pinned to `5.0` on the equality edge and `%d = %t * 3.0` still
; folds EXACTLY to `15.0` — which is now not the seed, so the region is
; unambiguous and lowers to the ordinary fresh-rail controlled prep.
;
; ⚠ Its job is to keep the fp forward hand-off a DISCRIMINATOR (round-4 Rule-13
; mini-fix, F-R4-1). A decline-only family proves only that SOMETHING declined;
; the pair proves the fold is being computed and compared, which is the §12.3 M5
; lesson applied to the fp side.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %t = fmul double %q, 2.000000e+00
  %c = fcmp oeq double %t, 5.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 1.600000e+01, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 1.600000e+01, %entry ]
  %d = fmul double %t, 3.000000e+00
  %mr = call double @cq_measure_f64(double %rm)
  %md = call double @cq_measure_f64(double %d)
  %s  = fadd double %mr, %md
  ret double %s
}

; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 1.600000e+01)
; CHECK-NEXT: call void @cqrt_ry_f64_controlled(i32 {{.*}}, i32 %[[R]], double 9.000000e-01)

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
