; lowering_live_record_mb_sibling_alias_accept.ll — ACCEPT (M-B Increment 5, bd
; test_C_libtooling-4p7j Rule-13 round, finding F4h): a record minted, consumed
; and DISCHARGED on a wire that carries a DIAGONAL operation between its root and
; the record, then a chained Ry on that wire.
;
;     int q = u0; cq_theta(&q, 0.5);
;     if (q == 1) cq_phi(1.0);      // a branch phase: diagonal on q's basis
;     int d = q + 3; int e = d * 3; int m = cq_measure(e);
;     cq_theta(&q, 0.25);           // the chained Ry
;     return cq_measure(q) + m;
;
; Hand IR, not `clang -O1` output: clang reassociates `(q + 3) * 3` into
; `q * 3 + 9` and M-C then lowers the `+ 9` in place, which dissolves the
; interior record `%d` this file needs (measured; the same reassociation
; lowering_reject_live_record_two_hop.ll documents).
;
; THE WALK IT PINS. `%d`'s `add_unc(%d, %h, 3)` reads `%h` AFTER the kickback
; region on `%h` (mint, `cqrt_rz_i1` on the flag, strip, free). Sound because the
; region is DIAGONAL on `%h`: the flag's phase lands on the |1> branch of `q`, the
; strip returns the flag to |0>, and `%h`'s basis labels are untouched, so the
; register the adjoint recomputes from carries exactly the label the forward
; `add` read (bd memory [rz-diag-flag-strip-invariant]). The region's own flag
; is ALSO a derived record of `%h`'s wire; it is stripped and freed before the
; chained Ry, so the M-A guard must exempt it on clause 2, exactly like `%d`.
; Nothing dead is standing at the gate, and the guard is silent.
;
; History: pre-3qlq the diagonal operation was the register form
; `%qd = cq_phi(%q, 1.0)` (an in-place Rz on `%h`), the chained theta was written
; on that SIBLING ALIAS `%qd`, and the file was the un-fenced twin of
; lowering_reject_live_record_sibling_alias.ll. The 3qlq migration deleted the
; uncontrolled Rz, which left this file equal to
; lowering_live_record_mb_discharged_accept.ll up to the producing opcode. bd
; jttf (2026-10-05) re-spelled the diagonal operation as the branch phase above
; (a register-free phase creates no sibling SSA name, so the alias half of the
; subject has no register-free spelling) and retired the fenced twin, whose
; remaining property lowering_reject_live_record_two_hop.ll pins.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %k  = icmp eq i32 %q, 1                                      ; tainted condition
  br i1 %k, label %ph, label %join
ph:
  call void @cq_phi(double 1.000000e+00)                       ; branch phase: diagonal on %q
  br label %join
join:
  %d  = add i32 %q, 3                                          ; record off the wire, AFTER the region
  %e  = mul i32 %d, 3                                          ; measured => keeps its record
  %m  = call i32 @cq_measure_si32(i32 %e)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)  ; chained Ry written on %q
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %r  = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK-LABEL: define i32 @example(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; the kickback: flag minted off %[[H]], phase on the FLAG, strip, free:
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 1.000000e+00)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the record, its consumer, and its discharge, which reads %[[H]] after the
; diagonal region; label unchanged, so the rail returns to |0> before its free:
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[E:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[D]], i32 3)
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[E]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; The measured record %[[E]] is exempt; the BORROWED wire is never adjointed and
; never freed (one anchor, one prefix ⇒ window anchor -> EOF; bd memory
; [filecheck-check-not-window-trap]):
; NOFREEH:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; NOFREEH-NOT: @cq_template_mul_i32_hl_unc(
; NOFREEH-NOT: call void @cqrt_ry_i32(i32 %[[H2]], double -
; NOFREEH-NOT: call void @cqrt_free(i32 %[[H2]])

; The one branch phase carries `!cq.branchphase`, or the spine would read it as
; a reclaimable rotation and cancel it (round-1 F-L7-1):
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted. `SILENT` reads the
; pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
