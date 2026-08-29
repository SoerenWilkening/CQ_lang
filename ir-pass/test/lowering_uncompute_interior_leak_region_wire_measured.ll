; lowering_uncompute_interior_leak_region_wire_measured.ll — LEAK PROBE (M-B
; Increment 6, clause (d2)). ADMITTING THE STRIP DOES NOT ADMIT EVERYTHING ELSE:
; a COLLAPSE of the borrowed wire strictly inside the interval still leaks the
; whole component.
;
;     q = cq_theta(u, 0.5);
;     d = q * 37;
;     if ((d >> 3) == 5) q = cq_phi(q, PI);
;     return cq_measure(q) + cq_measure(d & 7);
;
; The chain rail `d` is read AGAIN after the region (`d & 7`, measured), so the
; component's anchor is after THAT read — and `cqrt_measure_i32` on the wire sits
; between the chain's first gate and the anchor. A measurement is a projective
; collapse: after it the wire no longer holds the basis label the forward `mul`
; read, so `cq_template_mul_i32_hl_unc(d, q, 37)` would neither zero `d` nor
; invert its forward, and the `cqrt_free` would be a hidden measurement of an
; entangled rail (Rules 6/8).
;
; `preservesBorrowedParent` refuses `cqrt_measure_*` (it is not one of the two
; proven-read-only shapes), and neither positional disjunct saves it: the measure
; is after the interval opens (not LEFT) and before the discharge (not RIGHT). It
; is not a `cqrt_cswap` at all, so clause (d2) never looks at it. The component
; leaks — both rails left allocated, Rule 6's fallback.
;
; CONTRAST, deliberately, with lowering_uncompute_interior_qram_parent_measured_
; after.ll: a measure AFTER the anchor is admitted by the RIGHT disjunct and is
; sound, because every path to the collapse runs through the discharge. Position
; is the whole difference.
;
; DISCRIMINATION: the region lowers in full — flag mint, route, arm Rz, route
; back, rail free, strip, flag free are all emitted — so the CHECK-NOTs are not
; passing on a decline.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @wire_measured_in_interval(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = mul nsw i32 %q, 37
  %k = and i32 %d, -8
  %c = icmp eq i32 %k, 40
  br i1 %c, label %arm, label %merge

arm:
  %g = call i32 @cq_phi_si32(i32 %q, double 0x400921FB54442D18)
  br label %merge

merge:
  %p  = phi i32 [ %g, %arm ], [ %q, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %p)
  %t  = and i32 %d, 7
  %m2 = call i32 @cq_measure_si32(i32 %t)
  %s  = add i32 %m1, %m2
  ret i32 %s
}

; the region lowers in full — this is the discrimination:
; CHECK-LABEL: define i32 @wire_measured_in_interval(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 37)
; CHECK-NEXT: %[[K:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[D]], i32 -8)
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K]], i32 40)
; CHECK:      call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %{{.*}})
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[K]], i32 40)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; …and NEITHER chain rail is uncomputed or freed (window = the `and` -> EOF):
; NOFREE:     %[[K2:.*]] = call i32 @cq_template_and_i32_hl(i32 %{{.*}}, i32 -8)
; NOFREE-NOT: @cq_template_and_i32_hl_unc(i32 %[[K2]],
; NOFREE-NOT: @cq_template_mul_i32_hl_unc(
; NOFREE-NOT: call void @cqrt_free(i32 %[[K2]])
