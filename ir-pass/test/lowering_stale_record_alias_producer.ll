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
; M-C NOTE (bd test_C_libtooling-6uqc, Increment 2a): the `q + c` lowers IN PLACE
; to the frozen `cqrt_addc_<W>` (its parent handle has no data use after it), so
; no ancestor rail is minted and the measurement reads the rail itself. Nothing
; else this file pins has moved.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double %g)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 3)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[H]])
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %d = add i32 %q, 3                            ; reads the alias, not the parent
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
