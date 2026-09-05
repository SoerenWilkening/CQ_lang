; control_swap_ifelse.ll — ACCEPT spec, two-arm PHASE if/else (§5b).
;
; `if (q > 5) { rz(q, a); } else { rz(q, b); }`. Both arms act on the live handle.
; Under the §6a control-in-place peephole neither arm gets a work rail: each arm Rz
; is emitted as one `cqrt_rz_i32_controlled` on q itself — the THEN gate on %flag,
; the ELSE gate on ¬flag via a self-inverse `cqrt_x(flag)` bracket around the else
; gate run — then icmp_inv(q) strips the boolean. Transcribed from
; docs/design/rssa-swap-control/swap_route_ifelse.ll (the IR analog of
; prototype_semantics.py Demo A, matched to 3e-16).
;
; The two-arm property this pins is unchanged by the collapse and is the whole
; point: the arms are MUTUALLY EXCLUSIVE by polarity, both acting on the SAME
; register, and per shot exactly one fires. What the route encoded with a pair of
; distinct |0> rails, the peephole encodes with the flag polarity — the bracket is
; what makes the else gate the complement of the then gate.
;
; WI-3 lands the if/else (¬flag bracket) in SwapRouteEmit, so this XPASSes — XFAIL
; gone.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT free count: one cqrt_free (the flag; there are no work rails to
; free any more), and no second anywhere.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; The route's ABSENCE, anchored at the function header so the window is the whole
; function (a trailing CHECK-NOT scans only past the LAST positive of its prefix,
; and every route line would land BEFORE that — it could never fire).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  call void @cq_phi(double %a)
  br label %merge
else:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; THEN arm: controlled on %flag, in place on q — NOT bracketed
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; ELSE arm: the complement — its gate run is X-bracketed, so it fires on ¬flag
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %b)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the flag free is the LAST free — no work rails to free, and no spurious extra
; CHECK-NOT: call void @cqrt_free
; dephasing guard (§8.5): zero method-B copies on a phase arm (a CNOT-copy copies a
; basis label not a phase -> dephases, verified P0 0.585->0.500)
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — one (the flag), no second anywhere.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; No swap route survives: no |0> work rails, no CSWAP, no copy, no data mux —
; window is `define` -> EOF, so a re-introduced route WOULD trip these.
; NOROUTE:     define i32 @example
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: phi i32
