; control_swap_reject_stalecond_router_diamond.ll — DECLINE (bd tayx, the
; kjd1 post-fix round's E4 finding, probe p11): the VALUE-ROUTED spelling of
; the diamond stale condition. A chained cq_theta whose arg-0 reaches the
; condition's wire only through a one-register value-routing phi, positioned
; BEFORE the compare, was invisible to ArmClassify's
; `nonDiagonalGateBeforeBranch`: prong (a) walked the provenance wire with
; CrossValueRouting=false (routers not crossed) and the positional scan's
; window starts at the compare. The phase-arm diamond was ACCEPTED and
; SwapRouteEmit emitted the routed stream (mint -> cswap -> arm Rz -> cswap ->
; strip) with the flag minted AFTER the hidden in-place Ry while the SSA
; condition `fcmp(%q)` denoted the pre-Ry record — verify-clean wrong unitary
; (pre-fix exit 0; the direct spelling declined, so one unitary was
; adjudicated inconsistently by SSA spelling). Fixed by walking with
; CrossValueRouting=true — a router phi forwards the same physical handle
; (mirrors the kjd1 select GATE-2c fix; the SELECT twin is
; control_swap_reject_select_stalecond_phi_routed.ll).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_cswap
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define void @example(double %u0, i1 %cc) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  br i1 %cc, label %x, label %y
x:
  br label %pre
y:
  br label %pre
pre:
  %r = phi double [ %q, %x ], [ %q, %y ]                            ; one-register router
  %g = call double @cq_theta_f64(double %r, double 7.000000e-01)    ; hidden in-place Ry on q's wire
  %c = fcmp ogt double %q, 5.000000e-01                             ; reads the PRE-Ry alias
  br i1 %c, label %arm, label %merge
arm:
  %qd = call double @cq_phi_f64(double %q, double 3.000000e-01)     ; phase arm on q
  br label %merge
merge:
  %ph = phi double [ %qd, %arm ], [ %q, %pre ]
  %m1 = call double @cq_measure_f64(double %ph)
  %m2 = call double @cq_measure_f64(double %g)
  ret void
}
