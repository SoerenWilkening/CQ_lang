; lowering_live_record_anc_measured_before_theta_accept.ll — ACCEPT: clause 4 (the
; COLLAPSE exemption) applied to an ANCESTOR record (M-A Increment 3, bd
; test_C_libtooling-6uqc).
;
; SOURCE:
;     cq_theta(&a, 0.5);
;     int d = a * 3;            // out-of-place: the alloc rail stays live
;     int m0 = cq_measure(a);   // ...but it is MEASURED before the gate
;     cq_theta(&d, 0.5);     // T — chained, in-place Ry on the mul rail
;     return cq_measure(d) + m0;
;
; The DISCRIMINATION TWIN of lowering_reject_live_record_anc_alloc_parent_mul.ll:
; the same three-instruction shape with one measurement moved in front of the
; gate. Measuring the parent classicalizes it — there is no coherence left in
; `%h` for the wire to be entangled WITH — so the Ry acts on a pure state again
; and the module lowers. Clause 4 is stated over the record, and this file pins
; that it reaches an ancestor record and not only a descendant one.
;
; CONTRAST with lowering_live_record_anc_observed_after_theta_accept.ll, which
; also lowers but for the OTHER reason (clause 3, the record is live user data).
; The three files together are the ancestor half's whole exemption story.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a  = mul i32 %q, 3                                          ; the WIRE
  %m0 = call i32 @cq_measure_si32(i32 %q)                      ; ancestor COLLAPSED before T
  %q2 = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)   ; T — lowers
  %m  = call i32 @cq_measure_si32(i32 %q2)
  %r  = add nsw i32 %m, %m0
  ret i32 %r
}

; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[D]], double 5.000000e-01)

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
