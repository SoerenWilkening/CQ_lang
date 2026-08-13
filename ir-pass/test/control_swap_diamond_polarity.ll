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
; incoming IDENTITY (ControlDetect), set `ArmNegated`, and the emitter MUST route
; on ¬flag via a self-inverse `cqrt_x(flag)` bracket around BOTH the route-in and
; the route-back (the adjoint of the split). The flag-strip is polarity-
; independent: Rz preserves q's basis value, so `icmp_inv(q)` returns the flag to
; |0> regardless of which polarity routed it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT free-count scan (§8.2): two cqrt_free and no third anywhere —
; the ¬flag X-bracket adds cqrt_x, NOT extra frees.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
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

; br: mint the flag, then route q into a |0> work rail — but on ¬flag (the gate
; arm is the false successor), so the cswap is X-bracketed.
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; arm body: VERBATIM, UNCONTROLLED Rz gates on the routed rail
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %a)
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %b)
; phi: route back (adjoint of the split, same ¬flag bracket)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_free(i32 %[[T]])
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
