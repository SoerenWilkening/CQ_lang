; lowering_live_record_mb_sibling_alias_accept.ll — ACCEPT (M-B Increment 5, bd
; test_C_libtooling-4p7j Rule-13 round, finding F4h). The un-fenced twin of
; lowering_reject_live_record_sibling_alias.ll: that fixture MINUS its one
; `call void @cqrt_x`.
;
; THE WALK IT PINS. The chained theta is written on `%qd = cq_phi(%q, ·)` — the
; DIAGONAL ALIAS of the wire the record was built from — so a guard comparing SSA
; names would see two wires. It is structural rather than a special case:
; `lowerRotations` RAUWs a `cq_phi` result to its own operand, so by the late M-A
; slot `%qd` and `%q` ARE the same i32 handle.
;
; WHAT M-B ADDS, and it is the one discharge in this family that reads the wire
; ACROSS a gate: `%d = a + 3` is minted AFTER `cqrt_rz_i32(%h, 1.0)`, and its
; `add_unc(%d, %h, 3)` reads `%h` after that same Rz. Sound because Rz is
; DIAGONAL — it writes a phase, never a basis label — so the register the adjoint
; recomputes from carries exactly the label the forward gate read. That is the
; same property the region flag-strip relies on (bd memory
; [rz-diag-flag-strip-invariant]) and the reason `preservesBorrowedParent`'s
; first row admits `cqrt_rz_<W>` on the parent at all. Swap the `cq_phi` for a
; second `cq_theta` and the rail leaks instead
; (lowering_uncompute_interior_leak_parent_ry_between.ll).
;
; The record is therefore discharged before the chained `cqrt_ry`, the guard
; exempts it on clause 2, and nothing dead is standing at the gate.
;
; MEASURED BOTH WAYS by the Rule-13 reviewer (REVIEW lens C): DECLINES at
; c36934a, LOWERS here, stream read by hand and sound.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 1.000000e+00)     ; diagonal alias — SAME wire
  %d  = add i32 %q, 3                                          ; record off the SIBLING name
  %e  = mul i32 %d, 3                                          ; measured => keeps its record
  %m  = call i32 @cq_measure_si32(i32 %e)
  %q2 = call i32 @cq_theta_si32(i32 %qd, double 2.500000e-01)  ; chained Ry written on %qd
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %r  = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK-LABEL: define i32 @example(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[H]], double 1.000000e+00)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[E:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[D]], i32 3)
; the adjoint reads %[[H]] across the DIAGONAL gate — label unchanged:
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[E]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; The measured record %[[E]] is exempt; the BORROWED wire is never adjointed and
; never freed — in particular no `cqrt_rz_i32(%h, -1.0)` (one anchor, one prefix
; ⇒ window anchor -> EOF; bd memory [filecheck-check-not-window-trap]):
; NOFREEH:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; NOFREEH-NOT: @cq_template_mul_i32_hl_unc(
; NOFREEH-NOT: call void @cqrt_rz_i32(i32 %[[H2]], double -1.000000e+00)
; NOFREEH-NOT: call void @cqrt_free(i32 %[[H2]])

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
