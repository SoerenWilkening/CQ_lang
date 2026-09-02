; control_swap_diamond_polarity.ll — ACCEPT spec, SUCCESSOR-SWAPPED phase diamond
; (Rule 9 polarity probe; swap-route 4.1 IMPLEMENTATION §6.3/§8.3).
;
; Same phase diamond as control_swap_diamond.ll, but the gate arm is the FALSE
; successor: `br i1 %c, label %merge, label %arm`, with the merge phi's
; entry-incoming listed FIRST. This is exactly what `clang -O1` produces for an
; `if (q <= 5) {} else { rz(q,·) }` / `if (u != k)`-style condition — it swaps the
; branch targets and the phi edge order. A lowering that assumed "successor 0 is
; the taken arm" or "phi incoming 0 is the arm value" would resolve the WRONG arm
; and miscompile (verify-clean). Detection MUST resolve the arm by merge-phi
; incoming IDENTITY (ControlDetect), set `ArmNegated`, and the emitter MUST gate on
; ¬flag via a self-inverse `cqrt_x(flag)` bracket. Under the §6a control-in-place
; peephole there is no route to bracket: the arm's Rz gates are emitted
; CONTROL-IN-PLACE on q, and the bracket wraps that gate RUN — ONCE, so EXACTLY TWO
; `cqrt_x` (the route needed four, one pair per CSWAP). The polarity property being
; pinned is unchanged: the arm resolved from the merge-phi incoming identity must be
; the one that fires, on ¬flag. The flag-strip is polarity-independent: Rz preserves
; q's basis value, so `icmp_inv(q)` returns the flag to |0> regardless of polarity.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT free-count scan (§8.2): one cqrt_free and no second anywhere —
; the ¬flag X-bracket adds cqrt_x, NOT frees.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; Independent EXACT ¬flag-bracket count: the gate run is bracketed ONCE, so exactly
; two cqrt_x and no third (a per-gate bracket would be a no-op pair between the two
; Rz — harmless here, but it would mean the emitter is bracketing the wrong unit).
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; The route's ABSENCE, anchored at the function header so the window is the whole
; function (a trailing CHECK-NOT scans only past the LAST positive of its prefix,
; and every route line would land BEFORE that — it could never fire).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %merge, label %arm     ; SWAPPED: gate arm is the FALSE successor
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q,  double %a)
  %q2 = call i32 @cq_phi_si32(i32 %q1, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %q2, %arm ]   ; entry-incoming FIRST (edge order swapped)
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; br: mint the flag — the gate arm is the FALSE successor, so the arm's gate run is
; X-bracketed and fires on ¬flag.
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; arm body: one controlled Rz per arm gate, IN PLACE on q, in arm-gate order — and
; INSIDE the single bracket, so both fire on ¬flag.
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %b)
; close the bracket (self-inverse X restores the flag's polarity)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
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

; Exact ¬flag-bracket count — two cqrt_x (ONE bracket around the whole gate run).
; XCNT-COUNT-2: call void @cqrt_x(i32
; XCNT-NOT:     call void @cqrt_x(i32

; No swap route survives: no |0> work rail, no CSWAP, no copy, no data mux —
; window is `define` -> EOF, so a re-introduced route WOULD trip these.
; NOROUTE:     define i32 @example
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: phi i32
