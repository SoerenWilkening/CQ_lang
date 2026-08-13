; lowering_bitint_signed_i40.ll — Phase 7.1 follow-up D5 (test_C_libtooling-m0yi),
; the SIGNED sibling of lowering_bitint_intermediate_masked_i40.ll. A signed
; `_BitInt(40)` add lowers TODAY with NO new ABI.
;
; FINDING (real clang 19.1.7 -O1): a signed `_BitInt(40) z = x + y` does NOT mask
; with `and` — it preserves the i40 value range by SIGN-EXTENDING from bit 40 via
; a shl/ashr pair at the rounded i64 storage width:
;   %s  = add i64 ...
;   %sh = shl i64 %s, 24        ; 24 = 64 - 40
;   %as = ashr i64 %sh, 24      ; arithmetic (sign-propagating) shift back
; All three are stock ops with EXISTING frozen templates (cq_template_add_i64,
; cq_template_shl_i64_hl, cq_template_ashr_i64_hl). No cq_template_mask_<W> family
; is needed for the signed path either — the round-up is clang's, and the
; sign-extend is a plain shl/ashr.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define void @ex(i64 %u0, i64 %u1) {
  %q0 = call i64 @cq_theta_sll(i64 %u0, double 0.25)
  %q1 = call i64 @cq_theta_sll(i64 %u1, double 0.50)
  %s  = add i64 %q1, %q0
  %sh = shl i64 %s, 24
  %as = ashr i64 %sh, 24
  %z  = call i64 @cq_measure_sll(i64 %as)
  ret void
}

; CHECK:     %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i64(
; CHECK:     %[[SHL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i64_hl(i32 %[[ADD]], i64 24)
; CHECK:     %[[ASHR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ashr_i64_hl(i32 %[[SHL]], i64 24)
; CHECK:     call i64 @cqrt_measure_i64(i32 %[[ASHR]])
; CHECK-NOT: cq_template_mask
; CHECK-NOT: cq taint escape
