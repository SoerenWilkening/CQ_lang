; lowering_stale_record_alias_producer.ll — ACCEPT: the producer-boundary twin
; of lowering_reject_stale_record_alias_sibling.ll (test_C_libtooling-6j1).
;
; The add reads the diagonal alias `%qd = cq_phi(%q, ·)` of a plain `cq_theta`
; SOURCE, and NO chained theta exists. The backward seed closure walks
; `%qd → %q` and stops there: `%q` is a theta call, and the closure crosses
; DIAGONAL `cq_phi` hops ONLY — never a theta hop. Closing through the theta
; to its classical seed `%u0` would put the PRODUCING `cq_theta(%u0, %g)` on
; the walk's user frontier and flag the very gate that creates the record the
; operand denotes — over-declining every theta consumer in the language (the
; WI-5 analysis' seeding subtlety; bd swap-route-value-stale-base-guard).
; This fixture pins that boundary: the shape must keep lowering, with the
; template reading the wire exactly as `%qd`'s record prescribes (the
; lowering_stale_record_add_after_phi.ll stream, alias-named).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double %g)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[H]], double %t)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 3)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %qd = call i32 @cq_phi_si32(i32 %q, double %t) ; diagonal alias — same wire, same record
  %d = add i32 %qd, 3                            ; reads the alias, not the parent
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
