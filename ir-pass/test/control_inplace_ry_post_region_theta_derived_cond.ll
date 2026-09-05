; control_inplace_ry_post_region_theta_derived_cond.ll — ACCEPT (FLAT, no loop):
; the P1 clause (PRD §13.4b) on a DERIVED condition, i.e. the exact shape
; `condWireDisposition`'s own header names as its residual.
;
;     if ((q & 6) == 4) r = cq_theta(r, .9);
;     q = cq_theta(q, .3);              <-- the Ry reflection on the CONDITION
;
; WHY THIS FILE EXISTS (bd test_C_libtooling-drbq Inc 3, round-1 lens L8, finding
; F-L8-2). The P1 widening shipped with exactly ONE flat accept fixture, and its
; condition is a DIRECT `icmp eq` on the rail. L8 measured that the clause
; additionally admits at least seven structurally distinct acyclic classes with no
; fixture anywhere — derived condition, compound condition, negated polarity, a
; gate on a classical branch, a diagonal-alias hop, two sequential rotation-arm
; regions, and an escaping condition record — every one of them SOUND as far as
; the lens could push it. That is a Rule-12 coverage gap, not a correctness
; finding, and this file and `..._post_region_theta_negated.ll` close the two the
; lens named as the minimum.
;
; WHAT THE DERIVED CONDITION ADDS OVER THE DIRECT ONE, and it is the whole reason
; it is the residual: the region no longer emits a bare mint/strip pair. It brings
; the UNCOMPUTE SPINE in — an `and` rail is minted BEFORE the flag and discharged
; AFTER it — so the question P1 answers becomes "does the ENTIRE chain, temps
; included, discharge before the deferred gate fires?" and not merely "does the
; flag?". MEASURED (L8, `p02_derived_and.c`, plain C at `-O1`, linked and run,
; strict stage 2b clean): it does. The `and` rail's `_unc` and both `cqrt_free`s
; precede the reflection, so nothing recomputes on a moved wire and no free is
; dirty. The hypothesis under test was that the chain discharged AFTER the gate,
; which would have been a confirmed miscompile; it is refuted, and the ORDER
; below is the pin.
;
; ORACLE: the same program with `cq_phi` in the arm ACCEPTS on the pre-Inc-3
; binary and its trace is byte-identical apart from `rz`<->`ry` on the controlled
; line (L8 Q1(a)). So this is the phase arm's long-shipped ordering, reached by
; the rotation arm.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; the derived condition's own rail, minted BEFORE the flag:
; CHECK: %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 6)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[OP]], i32 4)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, double 9.0
; the WHOLE chain discharges, LIFO, and both rails are freed ...
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[OP]], i32 4)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[OP]], i32 %[[Q]], i32 6)
; CHECK-NEXT: call void @cqrt_free(i32 %[[OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; ... and only THEN does the deferred reflection fire on the condition handle:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 3.0
;
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: @cq_theta_
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %d  = and i32 %q, 6
  %c  = icmp eq i32 %d, 4
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r0, %entry ]
  %qn = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  %ma = call i32 @cq_measure_si32(i32 %qn)
  %mb = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %ma, %mb
  ret i32 %s
}
