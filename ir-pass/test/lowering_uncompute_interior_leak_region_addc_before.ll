; lowering_uncompute_interior_leak_region_addc_before.ll — LEAK PROBE (M-B
; Increment 6, clause (d2); bd test_C_libtooling-160a Rule-13 round, finding
; F1e). "Clause (d2) exempts the ROUTE and nothing else" — the REGION-shaped
; statement of it, first of three (before / inside / after).
;
; The straight-line twins already exist (lowering_uncompute_interior_leak_
; parent_addc_between.ll and siblings). What was unpinned is the case where an
; in-place WRITE on the routed base shares an interval with a RECORDED route
; group: there the group is exempted, and a reader could conclude the interval is
; therefore clean. It is not. `routeGroupFullyInside` exempts exactly the cswaps
; of one recorded group; every OTHER user of the borrowed parent still has to
; clear LEFT (`provablyBefore(M, First)`) or RIGHT (`provablyBefore(At, M)`) on
; its own.
;
; HERE: `cqrt_addc_i32(%h, 5)` sits BETWEEN the chain's forward `mul` (which
; reads `%h`) and the region. It is neither LEFT of the first recovered gate nor
; RIGHT of the discharge point, and it is not a route member, so the whole
; component LEAKS: `%h_op`/`%h_op1` are left allocated, never `_unc`'d, never
; freed (Rule 6's fallback). That is correct — the `mul_unc` would recompute
; `37*(h+5)` and XOR it onto a rail holding `37*h`, leaving a non-zero rail that
; `cqrt_free` would then reset: a hidden measurement, verify-clean.
;
; NO RED STATE EXISTS on any earlier plugin, and that is worth saying plainly:
; the chain leaks on `439dae3`, on `f27c7fd` and here, for three DIFFERENT
; reasons (no interior partition for `_unc` readers / no clause (d2) / clause (d)
; refusing the addc). Its discriminator is a MUTATION, and it was MEASURED, not
; asserted: turning clause (d)'s final `return false;  // unprovable => this
; component leaks` into a `continue` (i.e. admitting an unprovable write on a
; borrowed parent) turns this fixture AND its `_inside` sibling red, while the
; accept twin (lowering_uncompute_interior_region_addc_after_readers.ll) and
; both recorded-strip accepts stay green. Run: patch, `cmake --build build -j8`,
; `lit ir-pass/test --filter 'region_addc'`, revert.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCHAIN < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cqrt_addc_i32(i32, i32)

define i32 @addc_before_region(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = mul nsw i32 %q, 37
  call void @cqrt_addc_i32(i32 %q, i32 5)
  %k = and i32 %d, -8
  %c = icmp eq i32 %k, 40
  br i1 %c, label %arm, label %merge
arm:
  %g = call i32 @cq_phi_si32(i32 %q, double 0x400921FB54442D18)
  br label %merge
merge:
  %p = phi i32 [ %g, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; The region lowers normally — flag mint, the controlled arm Rz IN PLACE (drbq
; Inc 2a; the route quintuple this used to show is gone), strip, flag free — and
; the write on the base is emitted verbatim:
; CHECK-LABEL: define i32 @addc_before_region(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 37)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[K:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[D]], i32 -8)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K]], i32 40)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[K]], i32 40)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; …and the chain is NEVER reversed and NEVER freed. Window: from the strip (the
; last line that names the chain) to EOF, with only the flag's own free allowed
; (bd memory [filecheck-check-not-window-trap]):
; NOCHAIN:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2:[a-zA-Z0-9_.]+]], i32 %[[K2:[a-zA-Z0-9_.]+]], i32 40)
; NOCHAIN-NEXT: call void @cqrt_free(i32 %[[F2]])
; NOCHAIN-NOT:  call void @cq_template
; NOCHAIN-NOT:  call void @cqrt_free(
