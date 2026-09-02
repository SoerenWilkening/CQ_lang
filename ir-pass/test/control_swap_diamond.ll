; control_swap_diamond.ll — ACCEPT spec, one-content-arm PHASE diamond (§5a).
;
; `if (q > 5) { rz(q, a); rz(q, b); }` — a multi-gate phase arm over a tainted
; quantum handle. The lowering mints the flag from the tainted icmp, emits each arm
; Rz CONTROL-IN-PLACE on the user's own register (§6a peephole — one
; `cqrt_rz_i32_controlled(flag, q, theta)` per arm gate, no work rail and no CSWAP
; route), then strips the boolean with icmp_inv(q) — NO `phi i32`. Shape and symbol
; ORDER are still the contract, and are unchanged from the routed form apart from
; the collapsed arm; transcribed from
; docs/design/rssa-swap-control/swap_route_if_diamond.ll.
;
; WI-2 lands SwapRouteEmit (`lowerControlRegions`), so this XPASSes — XFAIL gone.
; WI-5's §8.2 no-spurious-free + §8.5 dephasing postconditions survive the collapse,
; restated for the single-register (diamond) shape: EXACTLY ONE cqrt_free (the flag —
; there is no work rail to free any more) and the later uncompute pass must add NO
; second (a spurious free is a hidden measurement that collapses q); and still ZERO
; copies (method-B copy on a PHASE arm dephases the answer, verified P0
; 0.585->0.500). The phase answer stays on q either way: the route put it there via
; the return CSWAP, the peephole never moves it off.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT free-count scan (§8.2): one cqrt_free and no second anywhere.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; The route's ABSENCE, anchored at the function header so the window is the whole
; function + the declares (a trailing CHECK-NOT scans only past the LAST positive of
; its prefix, and every route line would land BEFORE that — it could never fire).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
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

; br: mint the flag from the tainted icmp
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; arm body: one controlled Rz per arm gate, IN PLACE on q, in arm-gate order
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %b)
; strip the boolean: q==q0, so icmp_inv(q) returns the flag to |0>; reclaim it
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; q (not the phi) is measured — RAUW merge-phi -> q
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; no-spurious-free: the flag free is the LAST free — no second after it
; CHECK-NOT: call void @cqrt_free
; dephasing guard: zero copies, no surviving data mux
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — one (the flag), no second anywhere.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; No swap route survives: no |0> work rail, no CSWAP, no copy, no data mux —
; window is `define` -> EOF, so a re-introduced route WOULD trip these.
; NOROUTE:     define i32 @example
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: phi i32
