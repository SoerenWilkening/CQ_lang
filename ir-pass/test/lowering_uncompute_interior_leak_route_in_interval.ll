; lowering_uncompute_interior_leak_route_in_interval.ll — LEAK PROBE (M-B
; Increment 5, bd test_C_libtooling-4p7j Rule-13 round, finding F4a). CLAUSE (d)'s
; OWN ROUTE CASE: a Phase-4 `cqrt_cswap` route on a BORROWED parent, strictly
; INSIDE the interval [first recovered gate reading it, `At`], satisfies neither
; disjunct and leaks the group.
;
; The clause-(d) scan has exactly two ways out for a mutation `M` of a borrowed
; parent `P`:
;   LEFT   `provablyBefore(M, First)` — M ran before the interval opened;
;   RIGHT  `provablyBefore(At, M)`    — M runs only after the discharge.
; The shipped fixtures pin LEFT (the source `Ry` that mints the wire —
; interior_straightline) and RIGHT (the chained `cq_theta` after the discharge —
; live_record_derived_cond_theta_discharged; and a region route after it —
; interior_region_chain, then named interior_region_partial). THE STRICTLY-INSIDE
; CASE HAD NO FIXTURE, which is
; the one where an `_unc` would read a RELABELLED register: `cqrt_cswap(flag, P,
; work)` exchanges P's amplitude with the work rail on the flag-set branch, so
; between the forward gate and the adjoint P no longer holds what the forward
; gate read, and the "adjoint" would neither zero the rail nor be the forward's
; inverse. Freeing it would then be a hidden measurement (Rules 6/8).
;
; THE SHAPE (the hand-IR spelling of `x = a*a; m0 = measure(x < 3); if (a > 2)
; { a = cq_phi(a, .25); } measure(x > 100)` — the C form is
; `scratchpad/review-inc5/a19_cswap_interval_c.c` and lowers identically).
; `%h_op = mul(%h, %h)` is read BEFORE the region and again AFTER it, so `At`
; lands after the region while `First` is before it, and the emitter's own route
; pair sits between them.
;
; ⚠ RE-DISPOSITIONED BY M-B INCREMENT 6 — SAME VERDICT, DIFFERENT REASON, AND
; THE HEADER ABOVE IS NOW HISTORY. Increment 6 added clause (d2): the phase-arm
; emitter RECORDS its route as a matched group, and a group every member of which
; lies inside the interval IS admitted (it is the identity on the base's basis
; label, and an `_unc` is a label-only reader). So the two `cqrt_cswap` calls in
; this file are no longer what refuses it.
;
; WHAT REFUSES IT NOW, measured: the region's FLAG STRIP,
; `cq_template_icmp_sgt_i32_hl_unc(%[[FLAG]], %[[H]], 2)`. This region's
; condition is DIRECT, so the strip reads the borrowed source wire itself.
; `preservesBorrowedParent` proves only two shapes read-only (a diagonal
; `cqrt_rz_<W>` on the parent, and a forward reassigning producer) and an adjoint
; twin is neither, so the strip must clear the positional scan — and it cannot:
; it is after the interval opens (not LEFT) and before the discharge would go
; (not RIGHT), and it is not a route, so clause (d2) never looks at it.
;
; THAT IS AN OVER-DECLINE AND IS RECORDED AS ONE. A recorded strip demonstrably
; does not WRITE the operands in its shifted handle slots — that is the whole
; basis on which `isInteriorConsumer` admits it as a consumer — so admitting it
; in `preservesBorrowedParent` too would be the same claim from the other side.
; Increment 6 deliberately did not make it (its customers do not need it and the
; leak direction is free), and the widening is filed rather than assumed. If this
; file ever ACCEPTS, check that it was that widening and not a lost fence.
;
; NOTE WHAT IS *NOT* THE ARGUMENT, and it is why the route half moved. The route
; pair is self-cancelling — the second `cqrt_cswap` restores the basis label,
; which is why the emitter's own flag strip may read `%h` between the halves and
; why a chain SUNK past a whole region still discharges (`a9b_after_region.c`,
; LEFT). Increment 5 refused it anyway, on the grounds that clause (d) is a
; POSITIONAL proof and a data-uncompute driver that does not own the route should
; not reason about it. Increment 6 resolved that by having the OWNER record the
; pair, rather than by having this scan infer it.
;
; ⚠ AND SINCE drbq Inc 2a THERE IS NO ROUTE HERE AT ALL — SAY IT PLAINLY, BECAUSE
; THE FILE'S NAME NO LONGER DESCRIBES WHAT IT MEASURES. The §6a peephole lowers
; this FLAT phase region control-in-place: the quintuple
; `alloc(0); cswap; rz(rail); cswap; free(rail)` is one
; `cqrt_rz_i32_controlled(%[[FLAG]], %[[H]], .25)`. So the "strictly-inside route"
; that names this file is not emitted any more, and the clause-(d2) group
; exemption is not consulted (`TaintSet::RestoringRoutes` has no writer at HEAD).
;
; WHAT THE FILE MEASURES NOW, and why it is still worth its name in git history:
; the SAME verdict, from the SAME refusing element, with one MORE thing proven not
; to be it. The controlled Rz sits strictly inside the interval on the borrowed
; parent `%[[H]]`, and it is ADMITTED — `preservesBorrowedParent` clause (1b), a
; diagonal gate on both branches moves no basis label. The flag strip is still
; what refuses the discharge, exactly as the Increment-6 paragraph above records:
; it is after `First`, before `At`, and is neither a diagonal rotation nor a
; forward reassigning producer. If this file ever ACCEPTS, check that it was the
; filed strip widening and not a lost fence — that instruction is unchanged.
;
; DISCRIMINATION: the module LOWERS — the region's own flag mint, controlled arm
; `Rz`, flag strip and flag free are all emitted — so a `CHECK-NOT` sweep here is
; not passing because the pass declined.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEOP < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @interior_route_in_interval(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = mul i32 %q, %q
  %gt = icmp sgt i32 %q, 2
  br i1 %gt, label %arm, label %merge
arm:
  call void @cq_phi(double 2.500000e-01)
  br label %merge
merge:
  %y = mul i32 %x, 3
  %m = call i32 @cq_measure_si32(i32 %y)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m, %m2
  ret i32 %s
}

; The region lowers in full — flag mint, controlled arm Rz IN PLACE, strip, free:
; CHECK-LABEL: define i32 @interior_route_in_interval(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %[[H]], i32 %[[H]])
; CHECK-NEXT: %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 2)
; the gate strictly inside the interval, on the borrowed parent — ADMITTED by
; `preservesBorrowedParent` clause (1b), and NOT what refuses the discharge:
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[FLAG]], i32 %[[H]], double 2.500000e-01)
; the strip, also strictly inside the interval — and this one IS what refuses it:
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[FLAG]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[FLAG]])
; CHECK-NEXT: %[[Y:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[OP]], i32 3)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Y]])

; …and the interior rail whose parent is mutated mid-interval is LEFT ALLOCATED.
; The only free in the module is the emitter's own flag free, already matched
; above (it was two before drbq Inc 2a — the work rail's free went with the
; route), so this window (anchor -> EOF, bd memory
; [filecheck-check-not-window-trap]) must see no data-rail teardown at all:
; NOFREEOP:     %[[OP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; NOFREEOP-NOT: @cq_template_mul_i32_unc(
; NOFREEOP-NOT: @cq_template_mul_i32_hl_unc(
; NOFREEOP-NOT: call void @cqrt_free(i32 %[[OP2]])

; And the route really is gone (drbq Inc 2a) — the ONE `cqrt_alloc` in the module
; is the source wire's, and there is no `cqrt_cswap` anywhere:
; NOROUTE:     define i32 @interior_route_in_interval(
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
