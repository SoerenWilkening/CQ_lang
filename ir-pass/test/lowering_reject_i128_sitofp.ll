; lowering_reject_i128_sitofp.ll — Phase 7.1 follow-up n0ui (Tier-1) DECLINE
; probe (Rule 12, mirrors the i128 accept). i128 ships the integer WIDTH casts
; (zext/sext/trunc) ONLY; a CROSS-DOMAIN i128<->fp cast (sitofp/uitofp/fptosi/
; fptoui) is NOT in the frozen surface and must loud-decline, never mint a phantom
; cq_template_sitofp_i128_to_f64. castInScope excludes i128 from the cross-domain
; casts explicitly (intBits now knows i128, so the generic `fi && tf` would
; wrongly accept it without the guard). Over-declining is always safe.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i64 @cq_theta_sll(i64, double)
declare double @cq_measure_f64(double)

define void @ex(i64 %u0) {
  %q = call i64 @cq_theta_sll(i64 %u0, double 0.25)
  %w = zext i64 %q to i128
  %f = sitofp i128 %w to double     ; cross-domain i128 -> fp: NOT shipped
  %z = call double @cq_measure_f64(double %f)
  ret void
}

; CHECK: error{{.*}}no template for opcode 'sitofp double' in tainted context
; CHECK-NOT: cq_template_sitofp_i128
