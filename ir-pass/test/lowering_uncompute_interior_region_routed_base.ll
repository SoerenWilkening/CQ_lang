; lowering_uncompute_interior_region_routed_base.ll — ACCEPT + a structural
; refusal in one module (M-B Increment 6, clause (d2)). THE ROUTED BASE IS
; ITSELF A TEMPLATE RAIL, and it is never an interior candidate; the CONDITION's
; own chain rail, on the other side of the same region, is.
;
;     q = cq_theta(u, 0.5);
;     d = q * 37;                        /* the routed base — a template rail */
;     if ((q & 4096) == 0) d = cq_phi(d, PI);
;     return cq_measure(d);
;
; TWO RAILS, TWO OPPOSITE ANSWERS, ONE REGION.
;
;   * `%[[D]]` (`q * 37`) is the register the region ROUTES: `cqrt_cswap` takes
;     it as arg 1. `isInteriorConsumer` refuses every route gate outright — the
;     rail belongs to Phase 4 for the length of the region and its label is
;     exchanged with a work rail mid-stream — so it is not a candidate at all and
;     is left standing (it is measured here, which is also a refusal).
;   * `%[[K]]` (`q & 4096`) is the CONDITION's chain rail. Its two users are the
;     flag mint and the recorded strip, so clause (d2) admits it and it is
;     discharged right after the strip.
;
; The distinction is the whole point of keeping the admission on the STRIP rather
; than on "any `_unc`": one is a rail the emitter is still moving, the other is a
; rail the emitter has finished reading.
;
; NOTE THE BORROWED PARENT IS THE WIRE, NOT THE BASE. `%[[K]]`'s producer reads
; `%[[H]]` (`and(q, 4096)`), and `%[[H]]` is never routed in this region — the
; cswaps take `%[[D]]`. So clause (d)'s scan over `%[[H]]` sees only the source
; `cqrt_ry` (LEFT) and two forward producers, and never needs clause (d2) at all.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREED < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @routed_base(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = mul nsw i32 %q, 37
  %k = and i32 %q, 4096
  %c = icmp eq i32 %k, 0
  br i1 %c, label %arm, label %merge

arm:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %merge

merge:
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK-LABEL: define i32 @routed_base(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 37)
; CHECK-NEXT: %[[K:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[H]], i32 4096)
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K]], i32 0)
; the ROUTED base is %[[D]], not the wire:
; The region, CONTROL-IN-PLACE since drbq Inc 2a: the routed base %[[D]] is now
; the controlled Rz's own target (arg 1), where the route had it as the cswap's
; arg 1. The base identity this file is about is unchanged.
; CHECK:      call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[D]], double 0x400921FB54442D18)
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[K]], i32 0)
; the CONDITION chain rail discharges; the routed base does not:
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[K]], i32 %[[H]], i32 4096)
; CHECK-NEXT: call void @cqrt_free(i32 %[[K]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[D]])

; No adjoint of the routed base and no free of it anywhere (window = anchor ->
; EOF, bd memory [filecheck-check-not-window-trap]):
; NOFREED:     %[[D2:.*]] = call i32 @cq_template_mul_i32_hl(i32 %{{.*}}, i32 37)
; NOFREED-NOT: @cq_template_mul_i32_hl_unc(
; NOFREED-NOT: call void @cqrt_free(i32 %[[D2]])

; THE ROUTE'S ABSENCE, ON ITS OWN PREFIX ANCHORED AT THE FUNCTION HEADER (bd
; drbq Inc 2a round-1 review, L3 F2). The trailing `CHECK-NOT: cqrt_cswap`
; above scans only PAST the last positive of the `CHECK` prefix, so a route
; re-inserted AT the arm gate lands before its window and the assertion cannot
; fire (bd memory filecheck-check-not-window-trap). Anchoring at `define` makes
; the window the whole function. MUTATION-VERIFIED: re-inserting
; `cqrt_alloc_<W>(0) + cqrt_cswap` before the first controlled gate turns this
; prefix RED.
; NOROUTE:     define{{.*}}@routed_base
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
