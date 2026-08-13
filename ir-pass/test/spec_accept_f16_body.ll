; spec_accept_f16_body.ll — Phase 7.1 Increment D × Phase 6: a classical helper
; with an f16 INTERMEDIATE specializes correctly. Adding f16 to the recognized
; ABI flips SpecializeReject::unsupportedWidth(half) false, so a pure-classical
; i32->i32 body whose interior touches `half` is now specializable (it was
; rejected pre-D). This fixture pins that the expansion is SOUND, not a silent
; over-accept: the clone forward-computes the f16 intermediates
; (sitofp_i32_to_f16 -> fadd_f16_hl -> fptosi_f16_to_i32), copies out only the
; i32 RESULT (cqrt_copy_i32 — the f16 carriers are NEVER copied, so the
; no-cqrt_copy_f16 angle fence holds), then LIFO-reverses every f16 op via its
; `_unc` twin and frees each rail (whole-clone Bennett uncompute). The f16
; intermediate is computed-then-uncomputed, never measured, never escaped.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @half_helper(i32 %a) {
entry:
  %t = sitofp i32 %a to half
  %u = fadd half %t, 0xH3E00
  %r = fptosi half %u to i32
  ret i32 %r
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r = call i32 @half_helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; Caller retargets to the mangled clone.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_half_helper_1(i32 %[[H]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])
;
; Clone: internal linkage; forward f16-intermediate chain; out copy is i32.
; CHECK:     define internal i32 @__cq_q_half_helper_1(i32 %a)
; CHECK:     %[[C0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f16(i32 %a)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f16_hl(i32 %[[C0]], half 0xH3E00)
; CHECK:     %[[C1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f16_to_i32(i32 %[[OP]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[C1]], i32 %[[OUT]])
; LIFO uncompute of the whole clone via the `_unc` twins; every rail freed once.
; CHECK:     call void @cq_template_fptosi_f16_to_i32_unc(i32 %[[C1]], i32 %[[OP]])
; CHECK:     call void @cq_template_fadd_f16_hl_unc(i32 %[[OP]], i32 %[[C0]], half 0xH3E00)
; CHECK:     call void @cq_template_sitofp_i32_to_f16_unc(i32 %[[C0]], i32 %a)
; CHECK:     call void @cqrt_free(i32 %[[C0]])
; CHECK:     ret i32 %[[OUT]]
;
; The f16 carrier is NEVER copied (no cqrt_copy_f16 — the angle fence holds);
; the original intrinsic is gone; the out-copy is the keep-live `_hl`, not `_inv`.
; CHECK-NOT: cqrt_copy_f16
; CHECK-NOT: cq taint escape
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: cq_template_fadd_f16_hl_inv
