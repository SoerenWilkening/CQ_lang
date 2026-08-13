; control_swap_ifelse.ll — ACCEPT spec, two-arm PHASE if/else (§5b).
;
; `if (q > 5) { rz(q, a); } else { rz(q, b); }`. Both arms act on the live handle,
; so q is routed to a DISTINCT |0> work rail per arm — the then rail under %flag,
; the else rail under ¬flag via a self-inverse `cqrt_x(flag)` bracket. Each arm
; body runs uncontrolled on its own rail; the join repeats the identical two
; CSWAP-pairs (adjoint of the split); both rails free clean; icmp_inv(q) strips
; the boolean. Transcribed from docs/design/rssa-swap-control/swap_route_ifelse.ll
; (the IR analog of prototype_semantics.py Demo A, matched to 3e-16).
;
; WI-3 lands the if/else (¬flag bracket + dual rails) in SwapRouteEmit, so this
; XPASSes — XFAIL gone.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  %qt = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
else:
  %qe = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %then ], [ %qe, %else ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[TT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[EE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; split: route q -> then rail iff flag, q -> else rail iff ¬flag
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[TT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[EE]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; arm bodies: VERBATIM, UNCONTROLLED
; CHECK:     call void @cqrt_rz_i32(i32 %[[TT]], double %a)
; CHECK:     call void @cqrt_rz_i32(i32 %[[EE]], double %b)
; join = adjoint of the split
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[TT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[EE]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_free(i32 %[[TT]])
; CHECK:     call void @cqrt_free(i32 %[[EE]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; dephasing guard (§8.5): zero controlled gates, zero method-B copies on a phase arm
; (a CNOT-copy copies a basis label not a phase -> dephases, verified P0 0.585->0.500)
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32
