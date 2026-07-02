; control_swap_reject_select_stalecond_phi_routed.ll — DECLINE (kjd1 POST-FIX
; refute-default round, E1 blocker; FP_SELECT_CLEARANCE.md addendum): the
; VALUE-ROUTED spelling of the D1 stale condition. The chained cq_theta's
; arg-0 reaches the condition's wire only through a one-register value-routing
; PHI (`%m = phi [%q,%a],[%q,%b]`), and the theta sits BEFORE the compare — so
; GATE 2c's positional prong never sees it and the first-cut position-free
; prong (CrossValueRouting=false) never crossed the router: the select was
; ACCEPTED and the flag minted from the post-Ry basis while the SSA condition
; `fcmp(%q)` denoted the pre-Ry record (verify-clean wrong predicate; probe
; exit 0 pre-fix). Fixed by walking GATE 2c prong (a) with
; CrossValueRouting=true — a router phi/select forwards the same physical
; handle, so a theta behind it is an in-place Ry on the condition's wire.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define void @example(double %u0, i1 %cc) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  br i1 %cc, label %a, label %b
a:
  br label %join
b:
  br label %join
join:
  %r = phi double [ %q, %a ], [ %q, %b ]                            ; one-register router
  %g = call double @cq_theta_f64(double %r, double 7.000000e-01)    ; hidden in-place Ry on q's wire
  %c = fcmp ogt double %q, 5.000000e-01                             ; reads the PRE-Ry alias
  %sel = select i1 %c, double 1.000000e+00, double 2.000000e+00
  %m1 = call double @cq_measure_f64(double %sel)
  %m2 = call double @cq_measure_f64(double %g)
  ret void
}
