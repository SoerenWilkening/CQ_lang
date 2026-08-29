; lowering_uncompute_interior_component_isolation.ll — ACCEPT + LEAK IN ONE
; MODULE (bd test_C_libtooling-if1e, M-B Increment 6). A component that CANNOT
; be proven no longer poisons the components that can.
;
;     int q  = cq_theta(u, 0.5);
;     int a  = q * 5;   int m1 = cq_measure(a & 12);   /* component 1 */
;     int b  = q * 7;                                  /* component 2 opens */
;     q      = cq_theta(q, 0.25);                      /* Ry INSIDE its interval */
;     int m2 = cq_measure(b & 20);                     /* component 2 closes */
;
; This is the C spelling verbatim (`clang -O1` keeps `b`'s `mul` before the
; chained theta and its `and` after — measured, not assumed).
;
; COMPONENT 1 (`a`) is provable: its whole interval is before the Ry, which is
; therefore to its RIGHT. It discharges.
;
; COMPONENT 2 (`b`) is NOT: the chained `cqrt_ry` on the borrowed source wire
; sits STRICTLY BETWEEN `b`'s forward `mul` and the point after its `and` where
; the discharge would go. `cqrt_ry` is not basis-preserving (it is the gate that
; MINTS the superposition), so an `_unc` placed after it would recompute `5*q`
; from a post-Ry wire and neither zero the rail nor invert the forward — freeing
; it would be a hidden measurement (Rules 6/8). Neither clause-(d) disjunct
; holds and the component LEAKS, exactly as designed.
;
; AT 439dae3 BOTH LEAKED — one `At` per function put component 1 in the same
; unprovable interval — and the program then DECLINED at the M-A guard. Per
; component the leak is contained: `b` stays allocated (a Rule-6 safe leak) and
; the M-A guard still accepts, because `b`'s lineage reaches an OBSERVING SINK
; after the gate (the `cq_measure` of `b & 20`), which is the ruled clause-3
; exemption — `b` is live user data at the Ry, not a dead record.
;
; DISCRIMINATION: the module LOWERS and component 1's `_unc`+free ARE emitted,
; so the CHECK-NOTs below are not passing on a decline or on an empty partition.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEB < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @component_isolation(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a  = mul nsw i32 %q, 5
  %a2 = and i32 %a, 12
  %m1 = call i32 @cq_measure_si32(i32 %a2)
  %b  = mul nsw i32 %q, 7
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)
  %b2 = and i32 %b, 20
  %m2 = call i32 @cq_measure_si32(i32 %b2)
  %s  = add i32 %m1, %m2
  ret i32 %s
}

; CHECK-LABEL: define i32 @component_isolation(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[A]], i32 12)
; the PROVABLE component discharges — this is the discrimination:
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[A]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[A2]])
; CHECK-NEXT: %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: %[[B2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[B]], i32 20)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[B2]])

; …and the UNPROVABLE component is left allocated: no adjoint of `b`'s `mul`
; and no free of its rail anywhere after it is minted (window = the anchor to
; EOF, bd memory [filecheck-check-not-window-trap]):
; NOFREEB:     %[[B3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; NOFREEB-NOT: call void @cqrt_free(i32 %[[B3]])
