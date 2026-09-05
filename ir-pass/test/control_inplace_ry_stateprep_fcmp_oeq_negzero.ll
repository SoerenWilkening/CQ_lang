; control_inplace_ry_stateprep_fcmp_oeq_negzero.ll — ACCEPT, and it is the
; one-token control that pins the fp anchor's ±0.0 REFUSAL.
;
; It is `..._reject_stateprep_fcmp_oeq_folded.ll` with the compare constant and
; the seed changed from `5.0` to `0.0` and NOTHING else. It ACCEPTS, and the
; reason is arithmetic rather than an omission: `fcmp oeq %t, 0.0` is TRUE for
; `%t = -0.0` as well as `%t = +0.0`, so the equality edge admits TWO distinct
; bit patterns and pins `%t` to NEITHER. F2's whole test is BIT identity on the
; `APFloat` (`ConstantFP` uniques on bits, which is what keeps `+0.0` and `-0.0`
; distinct there), so pinning `%t` to the written `+0.0` would be claiming a fact
; the edge does not carry — and it is also exactly why `clang` cannot perform
; this substitution in the first place.
;
; ⚠ ROUND-4 RULE-13 (lens R4, F-R4-1). Without this file the zero refusal is
; unpinned: delete `FpK->getValueAPF().isZero()` from the anchor's guard and
; NOTHING reddens, because every OTHER fp fixture in the family uses a non-zero
; constant. Under that mutation this module flips to a DECLINE. Same argument as
; `..._stateprep_intrinsic_bswap_accept.ll` makes for the exact-fold half:
; precision is what a control pins, and a decline-only family cannot pin it.
;
; (The NaN half of the same guard needs no companion file: a NaN `K` makes the
; equality edge unreachable under `oeq` and universal under `ueq`, so removing
; that clause changes no verdict on any module — it is refused for clarity, and
; the code says so.)
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
  %c = fcmp oeq double %t, 0.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 0.000000e+00, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 0.000000e+00, %entry ]
  %mr = call double @cq_measure_f64(double %rm)
  %mt = call double @cq_measure_f64(double %t)
  %s  = fadd double %mr, %mt
  ret double %s
}

; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64_controlled(i32 {{.*}}, i32 %[[R]], double 9.000000e-01)

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
