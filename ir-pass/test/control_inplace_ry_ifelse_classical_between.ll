; control_inplace_ry_ifelse_classical_between.ll — ACCEPT. The IF/ELSE in-place
; rotation region (TWO hoisted gates, the `cqrt_x` bracket around the false arm)
; crossed with the CROSS-REGION VALUE LIFETIME axis (a classical branch between
; two quantum regions), which is round-1 finding M's exact geometry.
;
;     int q = …, p = …, r = …; cq_theta(&q, …); cq_theta(&p, …); cq_theta(&r, …);
;     if (q > 5) cq_theta(&r, .9); else cq_theta(&r, .2);   // region 1
;     if (cc == 0) { } else { g(); }                              // classical
;     if (p == 6) cq_theta(&r, .3);                            // region 2
;     return cq_measure(r) + cq_measure(q) + cq_measure(p);
;
; WHY IT EXISTS (bd test_C_libtooling-drbq round-2 Rule-13 review, lens C §6).
; The two-gate branch of `emitInPlaceRotationRegion`'s hoist loop had exactly ONE
; test in the tree — `control_inplace_ry_ifelse.ll`, a standalone region — and
; NONE in COMPOSITION. That is the axis both round-1 defects lived on: L4 §1/§2
; (`RoutedBase` dangling across emission order) is a cross-region VALUE lifetime
; bug, and here region 2's `RoutedBase` IS region 1's merge φ, which region 1's
; emission RAUWs and erases. The classical branch is what makes it bite: it puts
; region 2's `Pred` in a THIRD block, so the bd `hcrg` pre-flight — which reasons
; about BASIC BLOCKS — correctly finds no alias and orders nothing, while the
; dependency it does not model is a value one. Before the `WeakTrackingVH` fix
; the raw pointer compared a freed address against a live one and this shape
; declined `control flow`, with a verdict that flipped with textual block order.
;
; ⚠ NOT REACHABLE FROM C, and that is measured, not assumed: `clang -O1` sinks
; the two arm thetas of an `if/else` on ONE base into a single unconditional
; `cq_theta` with a `select i1 %c, double 0.9, double 0.2` in the ANGLE slot, so
; the C spelling declines `rotation angle under quantum control` (correct — the
; angle would be quantum-conditioned, R2/Rule 3). Hand IR is the only way to
; reach the two-gate branch, which is why this fixture is hand-written and why
; there is no e2e slice for it. See notes finding D.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @g()

define i32 @example(i32 %u0, i32 %u1, i32 %u2, i32 %cc) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u2, double 6.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armt, label %armf
armt:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
armf:
  %rf = call i32 @cq_theta_si32(i32 %r, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %armt ], [ %rf, %armf ]
  %cz = icmp eq i32 %cc, 0
  br i1 %cz, label %cjoin, label %cbody
cbody:
  call void @g()
  br label %cjoin
cjoin:
  %c2 = icmp eq i32 %p, 6
  br i1 %c2, label %arm2, label %merge2
arm2:
  %r2 = call i32 @cq_theta_si32(i32 %rm, double 3.000000e-01)
  br label %merge2
merge2:
  %rm2 = phi i32 [ %r2, %arm2 ], [ %rm, %cjoin ]
  %m  = call i32 @cq_measure_si32(i32 %rm2)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %m3 = call i32 @cq_measure_si32(i32 %p)
  %s  = add i32 %m, %m2
  %s2 = add i32 %s, %m3
  ret i32 %s2
}

; REGION 1 — if/else: mint the flag once, fire the TRUE arm's gate unbracketed,
; then the FALSE arm's gate inside a self-inverse `cqrt_x` bracket (control on
; ¬flag), then strip and free. BOTH gates name the SAME register %h3 — the whole
; point of control-in-place: no route, no work rail, no reverse-play.
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %h3, double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %h3, double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])

; The classical diamond SURVIVES between the two regions — it is not quantum
; control and nothing flattens it. This is the block chain that defeats the
; `hcrg` block-alias pre-flight.
; CHECK-NEXT: %[[CZ:[a-zA-Z0-9_.]+]] = icmp eq i32 %cc, 0
; CHECK-NEXT: br i1 %[[CZ]], label %cjoin, label %cbody
; CHECK:      cbody:
; CHECK-NEXT: call void @g()
; CHECK:      cjoin:

; REGION 2 — a diamond on a DIFFERENT condition register, rotating the SAME
; register region 1 just relabelled. Its recorded routed base was region 1's
; merge φ; the `WeakTrackingVH` followed that φ's RAUW to %h3, so the gate names
; the live handle and the region emits in SOURCE ORDER after region 1.
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %h2, i32 6)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %h3, double 3.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %h2, i32 6)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %h3)

; No route, no work rail, no reverse-play anywhere; exactly two frees (the two
; flags), and the three source rails are measured, never freed.
; CNT-NOT:     cqrt_cswap
; CNT-NOT:     cqrt_copy_
; CNT-NOT:     double -9.000000e-01
; CNT-NOT:     double -2.000000e-01
; CNT-NOT:     double -3.000000e-01
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
