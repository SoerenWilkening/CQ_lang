; control_swap_reject_select_fp128.ll — DECLINE (fp-data-select-PRD §5 matrix
; 6): an `fp128` select. abiWidthFromType returns "" for fp128 (the only sound
; runtime c_type is a real 128-bit fp this x86-64 build cannot compile), so
; `abiWidthHasControlledFpCopy` is false and gate 4 declines — no
; `cqrt_copy_f128_controlled` exists and none may be phantom-minted. The fp
; un-staging covers exactly {f16,f32,f64,f80}; everything else keeps declining.
;
; Gate 3 note: the `fptrunc` back to double IS a value-preserving carrier, but
; the walk lands only on a measure (a data sink), so gate 3 passes and the
; decline is gate 4's width fence — pinning the fence, not the angle gate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c   = fcmp ogt double %q, 5.000000e+00
  %qe  = fpext double %q to fp128                  ; tainted fp128 (whitelisted cast)
  %sel = select i1 %c, fp128 %qe, fp128 0xL00000000000000000000000000000000
  %st  = fptrunc fp128 %sel to double              ; back to a measurable width
  %m   = call double @cq_measure_f64(double %st)
  ret double %m
}
