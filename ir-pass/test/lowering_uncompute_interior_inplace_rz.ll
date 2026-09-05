; lowering_uncompute_interior_inplace_rz.ll — ACCEPT (M-B Increment 5a, bd
; test_C_libtooling-6uqc). AN INTERIOR RAIL CARRYING A USER `cq_phi` (Rz).
;
; `%h_op` is a `mul` rail the user then phases with `cq_phi` — an in-place
; DIAGONAL gate. It is admitted as an interior consumer because Rz IS a basis
; permutation in the sense the freeze needs (`preservesBasisUnderRecord`: trivial
; on |0>, g = identity, and the label-diagonal phase commutes with and cancels
; against a basis-label record). Its adjoint is the negated-angle re-emit, which
; must land BEFORE the producer's `_unc`: `mul_unc` recomputes `3*%h` and needs
; `%h_op` back at its producer-time label, and while Rz does not change that
; label it DOES leave a phase that the free would otherwise reset away.
;
; THE CONTRAST THAT MAKES THE ROW MEAN SOMETHING is
; lowering_uncompute_interior_leak_parent_ry_between.ll and
; lowering_uncompute_interior_leak_ry_on_rail.ll: an Ry on the same rail is NOT a
; basis permutation, and the rail is then left allocated instead. Diagonal in,
; non-diagonal out — the same line Rules 5/7 draw for the phase arm.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @interior_rz(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %c = icmp slt i32 %a, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}

; CHECK-LABEL: define i32 @interior_rz(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[A:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[A]], i32 10)
; CHECK-NEXT: %[[Z:.*]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[C]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[C]], i32 %[[A]], i32 10)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[A]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: %[[M:.*]] = call i32 @cqrt_measure_i32(i32 %[[Z]])
