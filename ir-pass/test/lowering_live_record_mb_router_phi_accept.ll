; lowering_live_record_mb_router_phi_accept.ll — ACCEPT (M-B Increment 5, bd
; test_C_libtooling-4p7j Rule-13 round, finding F4h). The un-fenced twin of
; lowering_reject_live_record_router_phi.ll: that fixture MINUS its one
; `call void @cqrt_x`.
;
; THE WALK IT PINS. The chained theta reaches its wire through a one-register
; ROUTER PHI (the bd tayx spelling): `declineClassicalMuxes`'s merge-phi LIFT
; proves `%p` a pure SSA renaming of `%q` and RAUWs it to the wire base ~90 run
; lines before `lowerRotations`, so the late M-A guard sees the `cqrt_ry` on the
; base. What M-B adds is that the record `%d` is gone by then: it is discharged
; in `entry`, BEFORE the classical diamond, so the guard's clause 2 exempts it.
;
; NOTE WHERE THE DISCHARGE LANDS, because it is the interesting part. `%d`'s only
; consumer `%e` is in `entry`, so `At` is in `entry` too — the reversal never
; enters the diamond, and the arm's diagonal `cqrt_rz` on `%h` is simply after
; it. Had the consumer been inside one arm, the per-gate `PDT.dominates(At, G)`
; re-proof would have refused the placement (invariant 7,
; lowering_uncompute_interior_leak_divergent_placement.ll). A one-armed reversal
; is exactly what that proof exists to prevent.
;
; THE ANALYTIC ARGUMENT for the discharge: `%d = a + 3` is a `cq_template_add_i32_hl`,
; a basis permutation of the borrowed wire `%h`; its only consumer `%e` has
; executed and is measured afterwards (so `%e` keeps its record and is never
; touched). `add_unc(%d, %h, 3)` recomputes `a + 3` from a wire holding what it
; held at the forward gate — the only later writes to `%h` are the arm's DIAGONAL
; `cqrt_rz` (no basis relabelling) and the chained `cqrt_ry`, both AFTER `At`
; (clause (d) RIGHT). The rail is |0> at its free.
;
; MEASURED BOTH WAYS by the Rule-13 reviewer (REVIEW lens C): DECLINES at
; c36934a, LOWERS here, stream read by hand and sound.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = add i32 %q, 3                                           ; the record — discharged
  %e = mul i32 %d, 3                                           ; measured => keeps its record
  %m = call i32 @cq_measure_si32(i32 %e)
  br i1 %c, label %arm, label %merge                           ; CLASSICAL condition

arm:
  br label %merge

merge:
  %p  = phi i32 [ %q, %arm ], [ %q, %entry ]                  ; the one-register router
  %q2 = call i32 @cq_theta_si32(i32 %p, double 1.250000e-01)   ; chained Ry THROUGH the phi
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %r  = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK-LABEL: define i32 @example(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[E:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[D]], i32 3)
; the discharge lands in `entry`, before the diamond:
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[E]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 1.250000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; The measured record %[[E]] is exempt; the BORROWED wire is never adjointed and
; never freed (one anchor, one prefix ⇒ window anchor -> EOF; bd memory
; [filecheck-check-not-window-trap]):
; NOFREEH:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; NOFREEH-NOT: @cq_template_mul_i32_hl_unc(
; NOFREEH-NOT: call void @cqrt_free(i32 %[[H2]])

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
