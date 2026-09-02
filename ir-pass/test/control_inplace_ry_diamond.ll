; control_inplace_ry_diamond.ll — ACCEPT spec, the CONTROL-IN-PLACE ROTATION
; diamond (control-in-place-PRD §4 shape (a), bd test_C_libtooling-drbq Inc 1).
;
;     int q = cq_theta(0,.7); int r = cq_theta(0,.3);
;     if (q == 5) r = cq_theta(r, .9);         // S1
;
; A tainted-control Ry has NO swap-route form, so this is not an optimization of
; the phase path — it is the mechanism (PRD §2). The route's premise is that the
; arm gate is a no-op on the INACTIVE |0> work rail: true for Rz = diag(1,e^{iθ}),
; FALSE for Ry(θ)|0> = cos|0> + sin|1>, which hands that rail back DIRTY and
; ENTANGLED with the flag (Rules 6/8). Cleaning it would need a controlled Ry† —
; method-A, dropped 2026-06-09 precisely because a gate you would emit to clean a
; rail is a gate you could have controlled in place from the start.
;
; So the whole stream is: mint the flag at the compare, fire ONE
; `cqrt_ry_i32_controlled(flag, r, θ)` in place on the user's own register, strip
; the flag with the same `icmp_..._unc`, free it. No alloc, no cswap, no work
; rail, no reverse-play. The flag strip stays valid because R4 proved `r`'s
; PHYSICAL wire is disjoint from every wire the condition reads, so `q`'s basis at
; the strip is the basis the mint read (PRD §3).
;
; The merge φ RAUWs to the base — both incomings denote the ONE physical rail,
; exactly as for a phase arm; what differs is that the rail has been RELABELLED on
; the flag=1 branch, which is why R6 refuses any pre-region SSA record of it read
; after the region (see control_inplace_ry_reject_stale_*.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT free/alloc scan: ONE cqrt_free (the flag) and no work rail.
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}

; THE WHOLE EMITTED STREAM, AS AN ADJACENCY CHAIN. `CHECK-NEXT` throughout,
; deliberately: the round-1 Rule-13 review (lens L6 §1) measured that the earlier
; loose `CHECK`-only form let an injected `cqrt_x(%h1)` between the mint and the
; gate — and an injected `cqrt_cswap(f, h1, h1)` after the free — pass GREEN,
; while the `_negated` sibling's `CHECK-NEXT` chain caught the same injection.
; A fixture whose stated assertion ("no route, no work rail") is not the
; assertion FileCheck evaluates is not an assertion.
;
; the two source registers, each on its OWN rail
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; flag mint at the compare — unchanged from the phase path
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; the arm gate, CONTROLLED and IN PLACE on r (no route, no rail)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; flag strip + free: q == q0 (the Ry landed on a disjoint wire), so icmp_inv(q)
; returns the flag to |0> and it is freed clean
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the merge users read the HANDLE (merge-φ RAUW'd to the base register)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

; NO ROUTE, no work rail, no dissolved data mux, and no UNCONTROLLED Ry on r's
; rail (that would fire the arm gate on both branches — the shape this whole
; increment exists to avoid). These run as their OWN prefix so FileCheck scans
; the WHOLE file: as trailing `CHECK-NOT`s after the last positive `CHECK` they
; only ever saw the `declare` block (L6 §1).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h1, double 9.000000e-01)

; EXACT counts: two allocs (the two source registers, no work rail) and ONE free.
; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
