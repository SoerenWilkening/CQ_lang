; lowering_classical_mux_phi_lift_diaghop_before_sibling.ll — ACCEPT: the
; don't-over-decline twin of lowering_reject_classical_mux_phi_lift_diaghop_stale.ll
; (test_C_libtooling-2qyz).
;
; Same lift + intervening diagonal hop `%qphi = cq_phi(%p, ·)` + sibling chained
; theta `%q2` on the base wire — but the arithmetic op `%v = add %qphi, 3` is
; scheduled BEFORE the sibling Ry. The post-lift re-sweep is POSITION-AWARE: the
; add's template fires PRE-Ry, capturing exactly the record `%v` denotes onto
; its own rail (DT->dominates(%v, %q2) && !reachable(%q2, %v)), so the later Ry
; on `%q`'s wire cannot touch it. The lift still fires and the add lowers — a
; legitimate use-then-re-rotate program through a diagonal alias. Confirms the
; complete re-sweep does not over-decline the transitive-consumer accept.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:      call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[D:.*]] = call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])
; CHECK-NOT:  phi i32
; CHECK-NOT:  cq_theta_si32
; CHECK-NOT:  cq_phi_si32
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c, double %g, double %t2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  br i1 %c, label %arm, label %merge            ; CLASSICAL condition
arm:
  br label %merge
merge:
  %p    = phi i32 [ %q, %arm ], [ %q, %entry ]
  %v    = add i32 %p, 3                                    ; BEFORE the sibling Ry — pre-Ry on its own rail
  %q2   = call i32 @cq_theta_si32(i32 %q, double %t2)         ; SIBLING chained Ry, AFTER the add
  %m    = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
