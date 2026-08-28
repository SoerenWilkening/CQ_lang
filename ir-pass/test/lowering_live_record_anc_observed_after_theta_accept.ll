; lowering_live_record_anc_observed_after_theta_accept.ll — ACCEPT: clause 3 (the
; record is LIVE USER DATA) applied to an ANCESTOR record (M-A Increment 3, bd
; test_C_libtooling-6uqc).
;
; SOURCE:
;     a = cq_theta(a, 0.5);
;     int d = a * 3;            // out-of-place: the alloc rail stays live
;     d = cq_theta(d, 0.5);     // T — chained, in-place Ry on the mul rail
;     int m  = cq_measure(d);
;     int m0 = cq_measure(a);   // the parent is OBSERVED AFTER the gate
;     return m + m0;
;
; THE RULED ACCEPT, on the ancestor side. The owner's 2026-08-27 ruling is
; liveness-keyed: a record with an OBSERVING data use after the gate is the
; program's OWN data, and the dephasing it causes at `T` is source semantics, not
; a miscompile — so the module must lower. This is the same principle that keeps
; lowering_stale_record_add_before_theta.ll green for a descendant record; this
; file pins it for an ancestor, so the backward walk cannot be widened into an
; unconditional "any live parent declines" rule.
;
; ONE INSTRUCTION FROM A DECLINE, in each direction:
;   * move `cq_measure(a)` BEFORE the gate and it still lowers, but by clause 4
;     (lowering_live_record_anc_measured_before_theta_accept.ll);
;   * delete it and it DECLINES
;     (lowering_reject_live_record_anc_alloc_parent_mul.ll);
;   * add a dead sibling off the same parent and it DECLINES even though the
;     parent stays exempt (lowering_reject_live_record_anc_dead_sibling.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a  = mul i32 %q, 3                                          ; the WIRE
  %q2 = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)   ; T — lowers
  %m  = call i32 @cq_measure_si32(i32 %q2)
  %m0 = call i32 @cq_measure_si32(i32 %q)                      ; ancestor LIVE after T
  %r  = add nsw i32 %m, %m0
  ret i32 %r
}

; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[D]], double 5.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[D]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
