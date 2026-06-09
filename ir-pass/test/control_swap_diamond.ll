; control_swap_diamond.ll — ACCEPT spec, one-content-arm PHASE diamond (§5a).
;
; `if (q > 5) { rz(q, a); rz(q, b); }` — a multi-gate phase arm over a tainted
; quantum handle. The swap-route lowering mints the flag from the tainted icmp,
; CSWAPs q into a |0> work rail, runs the arm Rz gates VERBATIM/UNCONTROLLED on
; the rail, CSWAPs the result back (phi = adjoint of the split, same %flag), frees
; the |0> rail, then strips the boolean with icmp_inv(q) — ZERO controlled gates,
; NO `phi i32`. Transcribed from docs/design/rssa-swap-control/swap_route_if_diamond.ll
; (symbol order IS the contract).
;
; XFAIL until WI-2 lands SwapRouteEmit — WI-1 recognizes the region but declines
; transitionally ("phase-arm swap-route emission pending"). Remove the XFAIL line
; when this XPASSes.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; XFAIL: *
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q,  double %a)
  %q2 = call i32 @cq_phi_si32(i32 %q1, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %q2, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; br: mint the flag, then route q into a |0> work rail
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; arm body: VERBATIM, UNCONTROLLED Rz gates on the routed rail
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %a)
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %b)
; phi: route the active result back into q (adjoint of the split, same %flag)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; rail is |0> (Rz|0>=|0>): clean free — NOT a measurement
; CHECK:     call void @cqrt_free(i32 %[[T]])
; strip the boolean: q==q0, so icmp_inv(q) returns the flag to |0>; reclaim it
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK-NOT: _controlled
; CHECK-NOT: phi i32
