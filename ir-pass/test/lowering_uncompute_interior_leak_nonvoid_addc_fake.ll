; lowering_uncompute_interior_leak_nonvoid_addc_fake.ll — LEAK PROBE (M-B
; Increment 5a, bd test_C_libtooling-6uqc). VOID IS THE LOAD-BEARING TEST, NOT THE
; ARITY — the bd test_C_libtooling-1fim lesson, re-proved on the interior surface.
;
; `@cqrt_addc_i32` is declared here returning `i32` at the frozen arity 2. The
; real ABI symbol is VOID and mints no rail; a non-void same-named call MINTS one,
; and "this gate mints no rail" is the entire reason an in-place gate may be
; adjointed by re-emitting itself with a negated immediate. Admitting it would
; give a rail-MINTING call a same-args "adjoint" that zeroes nothing, and then
; free the register it read.
;
; `ChainWalk::isInPlaceGateOn` tests void-ness, so the fake is not an in-place
; gate; `isTemplateProducer` rejects it on the name; so it is not an interior
; consumer at all and `%h_op` is left allocated. The compare rail above it is
; still discharged — the same per-rail discrimination as the `cqrt_x` sibling.
;
; This mirrors the three reviewers who reproduced the ORIGINAL 1fim defect at the
; frozen arity by flipping only the return type. Do not re-spell the void test.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cqrt_addc_i32(i32, i32)

define i32 @leak_nonvoid_fake(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %fake = call i32 @cqrt_addc_i32(i32 %a, i32 7)
  %c = icmp slt i32 %a, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}

; CHECK-LABEL: define i32 @leak_nonvoid_fake(
; CHECK: %[[A:.*]] = call i32 @cq_template_mul_i32_hl
; CHECK-NEXT: call i32 @cqrt_addc_i32(i32 %[[A]], i32 7)
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[A]], i32 10)
; CHECK-NEXT: call i32 @cq_template_zext_i1_to_i32(i32 %[[C]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[C]], i32 %[[A]], i32 10)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call i32 @cqrt_measure_i32
; CHECK-NOT: cq_template_mul_i32_hl_unc
; CHECK-NOT: call void @cqrt_free(i32 %[[A]])
