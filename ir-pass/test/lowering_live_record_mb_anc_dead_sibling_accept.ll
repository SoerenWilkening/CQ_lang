; lowering_live_record_mb_anc_dead_sibling_accept.ll — ACCEPT (M-B Increment 5,
; bd test_C_libtooling-4p7j Rule-13 round, finding F4h). The un-fenced twin of
; lowering_reject_live_record_anc_dead_sibling.ll: that fixture MINUS its one
; `call void @cqrt_x`, i.e. the program a user actually writes.
;
;     cq_theta(&a, 0.5);
;     int w = a * 2;   int b = a * 3;   int c = b * 7;
;     int mc = cq_measure(c);
;     cq_theta(&w, 0.5);            /* the chained, non-diagonal gate */
;     return cq_measure(w) + cq_measure(a) + mc;
;
; WHY IT NEEDS ITS OWN PIN. `lowering_live_record_mb_discharged_accept.ll` pins
; the LIFT for the `two_hop` program only, and each of the four fenced fixtures
; exercises a DIFFERENT walk in the M-A guard. This one is the dead SIBLING
; standing under a LIVE (measured-after) ancestor — the descendants-of-every-
; ancestor closure — so if M-B ever stopped discharging that shape the fenced
; fixture would still pass (its `cqrt_x` keeps the record standing) and nothing
; would notice. That is the gap this file closes.
;
; THE ANALYTIC ARGUMENT for the discharge, per the record invariant (bd 261j(a)):
; `%b = 3·a` is minted by an uncontrolled `cq_template_mul_i32_hl` — a basis
; permutation of its only parent `%h`, which is BORROWED and read-only over the
; interval. Its single forward consumer `%c` has executed (and is measured
; afterwards, keeping ITS record — the partition never touches `%c`). So
; `mul_unc(%b, %h, 3)` recomputes `3·a` from a wire holding exactly what it held
; at the forward gate and XORs it away: the rail is |0> on every branch, and the
; `cqrt_free` is Rule-6-legal rather than a hidden measurement.
;
; …AND THE GUARD THEN ACCEPTS WITHOUT A CLAUSE CHANGING. The discharge is
; `provablyBefore` the chained `cqrt_ry`, which is clause 2's exemption exactly.
; The ancestor `%h` is measured after the gate (live user data, clause 3) and the
; wire `%h_op` carries the answer. Nothing dead is standing when the Ry fires.
;
; MEASURED BOTH WAYS by the Rule-13 reviewer (REVIEW lens C): this module
; DECLINES at c36934a with "non-diagonal gate over a live derived record" and
; LOWERS here, and the emitted stream below was read by hand and is sound.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a  = mul i32 %q, 2                                          ; THE WIRE
  %b  = mul i32 %q, 3                                          ; DEAD SIBLING — discharged
  %c  = mul i32 %b, 7                                          ; measured => keeps its record
  %mc = call i32 @cq_measure_si32(i32 %c)
  %q2 = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)   ; T — the chained Ry
  %m  = call i32 @cq_measure_si32(i32 %q2)
  %m0 = call i32 @cq_measure_si32(i32 %q)                      ; ancestor LIVE => exempt
  %r0 = add nsw i32 %m, %m0
  %r  = add nsw i32 %r0, %mc
  ret i32 %r
}

; CHECK-LABEL: define i32 @slice(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[B]], i32 7)
; the dead sibling is discharged BEFORE the chained Ry:
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[B]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[C]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[W]], double 5.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[W]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; The measured record %[[C]] is exempt and never discharged; the BORROWED source
; wire is never adjointed and never freed (one anchor, one prefix ⇒ window
; anchor -> EOF; bd memory [filecheck-check-not-window-trap]):
; NOFREEH:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; NOFREEH-NOT: @cq_template_mul_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; NOFREEH-NOT: call void @cqrt_ry_i32(i32 %[[H2]], double -5.000000e-01)
; NOFREEH-NOT: call void @cqrt_free(i32 %[[H2]])

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
