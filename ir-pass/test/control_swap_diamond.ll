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
; WI-2 lands SwapRouteEmit (`lowerControlRegions`), so this XPASSes — XFAIL gone.
; WI-5 adds the §8.2 no-spurious-free + §8.5 dephasing postconditions for the
; single-rail (diamond) shape: EXACTLY TWO cqrt_free (work rail + flag) — the later
; uncompute pass must add NO third (a spurious free is a hidden measurement that
; collapses q) — and ZERO controlled gates / copies (method-B copy on a PHASE arm
; dephases the answer, verified P0 0.585->0.500).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; Independent EXACT free-count scan (§8.2): two cqrt_free and no third anywhere.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
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
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; q (not the phi) is measured — RAUW merge-phi -> q
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; no-spurious-free: EXACTLY two frees total — no third after the flag free
; CHECK-NOT: call void @cqrt_free
; dephasing guard: zero controlled gates, zero copies, no surviving data mux
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — two (work rail + flag), no third anywhere.
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
