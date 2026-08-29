; lowering_uncompute_interior_int_chain.ll — ACCEPT (M-B Increment 5a, bd
; test_C_libtooling-6uqc). The INTEGER opcode family of the interior partition:
; an out-of-place `mul` rail, an M-C IN-PLACE `cqrt_addc` on that same rail, a
; data-position `icmp` rail, and the `zext` copy that is measured.
;
; WHAT IT ADDS OVER lowering_uncompute_interior_straightline.ll (which covers the
; fp cast/arith/intrinsic/compare families): an owned rail that carries an
; IN-PLACE gate of its own. `%h1` is minted by the `mul` template and then
; relabelled in place by `cqrt_addc_i32(%h1, 7)`, so its DAG link has two gates
; and the reversal must undo them in LIFO — `cqrt_addc_i32(%h1, -7)` BEFORE
; `cq_template_mul_i32_hl_unc(%h1, %h0, 3)`, because the `_unc` recomputes the
; mul and needs `%h1` back at its producer-time label. Emitting them the other
; way round leaves `%h1` at `-7` and the following `cqrt_free` is a hidden
; measurement (Rule 6) that `opt -verify` cannot see.
;
; `cqrt_addc` is admitted as an interior consumer precisely because it IS a basis
; permutation (`ChainWalk::preservesBasisUnderRecord`, the M-C row): `R := R + imm
; (mod 2^W)` is a bijection whose only other operand is a classical immediate. A
; `cqrt_ry_` on the same rail is NOT, and the leak fixtures pin that boundary.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @interior_int(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %b = add i32 %a, 7
  %c = icmp slt i32 %b, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}

; CHECK-LABEL: define i32 @interior_int(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[A:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[A]], i32 7)
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[A]], i32 10)
; CHECK-NEXT: %[[Z:.*]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[C]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[C]], i32 %[[A]], i32 10)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[A]], i32 -7)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[A]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: %[[M:.*]] = call i32 @cqrt_measure_i32(i32 %[[Z]])
