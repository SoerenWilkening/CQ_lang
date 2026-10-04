; lowering_live_record_mb_discharged_accept.ll — ACCEPT (M-B Increment 5b, bd
; test_C_libtooling-6uqc). THE TWIN the four preserved guard fixtures point at.
;
; This is lowering_reject_live_record_two_hop.ll MINUS its one added
; `call void @cqrt_x` — i.e. the program a user actually writes:
;
;     cq_theta(&a, 0.5);
;     int d = a << 1;  int e = d * 3;  m = cq_measure(e);
;     cq_theta(&a, 0.5);   m2 = cq_measure(a);
;
; At Increment 3 it DECLINED with "cq rotation lowering: non-diagonal gate over a
; live derived record", and the decline was correct physics: `%d` was an
; undischarged basis record of the wire, dead at the gate (its only consumer `%e`
; is measured BEFORE the gate, so nothing observes `%d` afterwards), and the
; second Ry was dephased by it. The Increment-3 handoff named exactly this cost —
; "every information-losing op between two thetas on a register whose parent is
; not observed afterwards now declines … M-B is the fix."
;
; This is that fix, in one file: `%d` is an INTERIOR rail (its only consumer, the
; `mul`, has executed and never reads it again), so the interior partition
; uncomputes it with `cq_template_shl_i32_hl_unc(%d, %h, 1)` and frees it BEFORE
; the chained Ry. The record is no longer standing, and the guard accepts on
; clause 2 without one of its clauses being touched.
;
; WHAT IT DOES NOT LIFT, and this is why the twin fixtures keep their `cqrt_x`:
; a record M-B cannot own — one with an unaccounted consumer, one behind a
; mutation of its borrowed parent, one in a loop, one on the QRAM surface, one a
; region strip still reads — is STILL standing at the gate and STILL declines.
; The guard did not get weaker; the compiler got better at not creating the
; situation.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = shl i32 %q, 1                                          ; INTERIOR record
  %e  = mul i32 %d, 3                                          ; measured => exempt
  %m  = call i32 @cq_measure_si32(i32 %e)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 5.000000e-01)   ; the chained Ry
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %r  = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK-LABEL: define i32 @slice(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_shl_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[E:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[D]], i32 3)
; CHECK-NEXT: call void @cq_template_shl_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[E]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
; the terminal record %[[E]] is MEASURED, so it is exempt and never discharged
; CHECK-NOT: cq_template_mul_i32_hl_unc

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
