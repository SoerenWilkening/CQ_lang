; lowering_live_record_discharged_before_theta.ll — ACCEPT: clause 2 of the
; live-record predicate (M-A Increment 1, bd test_C_libtooling-6uqc). A record
; that is UNCOMPUTED AND FREED before the gate is not there to dephase it.
;
; This is the whole reason the guard runs at the LATE (post-`uncompute`) slot.
; At the early `declineStaleRecordOps` slot the module contains no `_unc` and no
; `cqrt_free` AT ALL, so "discharged before the gate" could only ever be a
; PREDICTION about where Phase 4's strip and Phase 5's free placement will land;
; here it is a fact read off the settled stream (owner ruling 2026-08-27, point
; 2). Nothing else in the fixture set can pin that difference.
;
; ALREADY-LOWERED FORM ON PURPOSE: no `.c` spelling can put the spine's own
; discharge BEFORE a later rotation (the whole-DAG reversal is emitted at the
; post-dominating free point, i.e. after it), so the record and its discharge
; are written as raw runtime calls — the
; lowering_uncompute_sink_move_past_unwalked_gate.ll idiom. The ROTATIONS are
; real `@cq_theta_si32` calls, so the gate is a genuine emitter-recorded site.
;
; THE CONTROL IS MEASURED, not asserted: delete the two discharge lines and this
; exact module DECLINES with the live-record message (that is what makes this an
; accept boundary and not an incidental pass).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = call i32 @cq_template_add_i32_hl(i32 %q, i32 1)        ; DESCENDANT record
  call void @cq_template_add_i32_hl_unc(i32 %d, i32 %q, i32 1) ; zeroed in place...
  call void @cqrt_free(i32 %d)                                 ; ...and freed, BEFORE the gate
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)   ; chained, in-place Ry — LOWERS
  ret i32 %q2
}

; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
