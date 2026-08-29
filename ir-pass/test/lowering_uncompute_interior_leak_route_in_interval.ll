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
; interior_region_partial). THE STRICTLY-INSIDE CASE HAD NO FIXTURE, which is
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
; NOTE WHAT IS *NOT* THE ARGUMENT. The route pair is self-cancelling — the second
; `cqrt_cswap` restores the basis label, which is exactly why the emitter's own
; flag strip may read `%h` between them and why a chain SUNK past a whole region
; still discharges (`a9b_after_region.c`, LEFT). This partition still refuses,
; because clause (d) is a POSITIONAL proof over the interval and "it comes back
; before anything else looks" is precisely the kind of reasoning bd 6uqc's
; history says not to trust from a data-uncompute driver that does not own the
; route. Over-declining costs one leaked rail.
;
; DISCRIMINATION: the module LOWERS — the region's own flag mint, route, `Rz`,
; route-back, flag strip and flag free are all emitted — so a `CHECK-NOT` sweep
; here is not passing because the pass declined.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEOP < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @interior_route_in_interval(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = mul i32 %q, %q
  %gt = icmp sgt i32 %q, 2
  br i1 %gt, label %arm, label %merge
arm:
  %qz = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)
  br label %merge
merge:
  %p = phi i32 [ %qz, %arm ], [ %q, %entry ]
  %y = mul i32 %x, 3
  %m = call i32 @cq_measure_si32(i32 %y)
  %m2 = call i32 @cq_measure_si32(i32 %p)
  %s = add i32 %m, %m2
  ret i32 %s
}

; The region lowers in full — flag mint, route, arm Rz, route back, free, strip:
; CHECK-LABEL: define i32 @interior_route_in_interval(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %[[H]], i32 %[[H]])
; CHECK-NEXT: %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[RAIL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[FLAG]], i32 %[[H]], i32 %[[RAIL]])
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[RAIL]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[FLAG]], i32 %[[H]], i32 %[[RAIL]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[RAIL]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[FLAG]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[FLAG]])
; CHECK-NEXT: %[[Y:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[OP]], i32 3)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Y]])

; …and the interior rail whose parent was routed mid-interval is LEFT ALLOCATED.
; The only frees in the module are the emitter's own two, already matched above,
; so this window (anchor -> EOF, bd memory [filecheck-check-not-window-trap])
; must see no data-rail teardown at all:
; NOFREEOP:     %[[OP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; NOFREEOP-NOT: @cq_template_mul_i32_unc(
; NOFREEOP-NOT: @cq_template_mul_i32_hl_unc(
; NOFREEOP-NOT: call void @cqrt_free(i32 %[[OP2]])
