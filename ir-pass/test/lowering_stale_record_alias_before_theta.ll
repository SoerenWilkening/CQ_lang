; lowering_stale_record_alias_before_theta.ll — ACCEPT: the positive twin of
; lowering_reject_stale_record_alias_sibling.ll, pinning that the diagonal-
; alias seed closure stays POSITION-AWARE (test_C_libtooling-6j1).
;
; Same SSA graph as the reject fixture — the add reads the diagonal alias
; `%qd = cq_phi(%q, ·)` and `%q`'s wire later gains a chained, NON-diagonal
; `cq_theta` through the sibling name — but here the add is SCHEDULED BEFORE
; the chained theta. The template is emitted AT the add's position and opaque
; calls keep their order, so the emitted `cq_template_add` fires PRE-Ry,
; capturing exactly the record `%qd` denotes onto its own fresh rail (the
; lowering_stale_record_add_before_theta.ll boundary, one diagonal hop
; removed). The closure must only ADD seeds for the backward wire walk — it
; must not erase the dominance proof that makes this legitimate
; use-then-re-rotate program keep lowering. The CHECK-NEXT order pins the
; load-bearing property: the template between the rz and the second ry.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double %g)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[H]], double 1.000000e+00)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double %t2)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %qd = call i32 @cq_phi_si32(i32 %q, double 1.000000e+00) ; diagonal alias of %q's wire
  %d = add i32 %qd, 3                                      ; BEFORE the chained Ry
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)        ; chained Ry via the SIBLING name
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
