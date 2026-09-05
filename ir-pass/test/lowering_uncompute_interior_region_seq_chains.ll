; lowering_uncompute_interior_region_seq_chains.ll — ACCEPT (M-B Increment 6,
; clause (d2) MEETING the per-component anchor of Increment 6a). TWO SEQUENTIAL
; derived-condition phase regions on one wire — the bd hcrg sequential-region
; shape, with a chain in front of each condition.
;
;     q = cq_theta(u, 0.5);
;     if (((q * 37) >> 3) == 5)  q = cq_phi(q, PI);
;     if (((q * 11) >> 2) == 3)  q = cq_phi(q, 0.25);
;     return cq_measure(q);
;
; THIS IS THE SHAPE THAT NEEDS BOTH HALVES OF THE INCREMENT AT ONCE, and it is
; the reduced form of the two-iteration Grover customer.
;
;   * clause (d2) admits each region's flag strip as a consumer of its own chain,
;     so each chain anchors AFTER its strip;
;   * the PER-COMPONENT anchor keeps the two chains apart. They share the wire
;     but have NO producer edge between them, so they are two components. With
;     one `At` per function (Increment 5) the FIRST chain would have been
;     anchored after the SECOND region's strip — putting region 1's whole route
;     INSIDE region 1's own interval alongside region 2's, and, in the Grover
;     spelling, an S-dagger `cqrt_ry` too. Everything leaked.
;
; Each component's clause-(d) scan sees only its OWN region's route as INSIDE;
; the other region's cswaps are LEFT (component 2) or RIGHT (component 1) of its
; interval, which the straight-line disjuncts already admit.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @seq_chains(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = mul nsw i32 %q, 37
  %k  = and i32 %d, -8
  %c  = icmp eq i32 %k, 40
  br i1 %c, label %arm1, label %m1

arm1:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %m1

m1:
  %d2 = mul nsw i32 %q, 11
  %k2 = and i32 %d2, -4
  %c2 = icmp eq i32 %k2, 12
  br i1 %c2, label %arm2, label %m2

arm2:
  call void @cq_phi(double 2.500000e-01)
  br label %m2

m2:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK-LABEL: define i32 @seq_chains(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; REGION 1 — its chain, its route, its strip, then its OWN discharge:
; CHECK-NEXT: %[[D1:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 37)
; CHECK-NEXT: %[[K1:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[D1]], i32 -8)
; CHECK-NEXT: %[[F1:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K1]], i32 40)
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[K1]], i32 40)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[K1]], i32 %[[D1]], i32 -8)
; CHECK-NEXT: call void @cqrt_free(i32 %[[K1]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[D1]], i32 %[[H]], i32 37)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; REGION 2 — a SEPARATE component, anchored at its own strip:
; CHECK-NEXT: %[[D2:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 11)
; CHECK-NEXT: %[[K2:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[D2]], i32 -4)
; CHECK-NEXT: %[[F2:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K2]], i32 12)
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[K2]], i32 12)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[K2]], i32 %[[D2]], i32 -4)
; CHECK-NEXT: call void @cqrt_free(i32 %[[K2]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[D2]], i32 %[[H]], i32 11)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
