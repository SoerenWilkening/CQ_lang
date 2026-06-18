; spec_accept_single.ll — Phase 6.1 WI-1.1: the canonical single-function
; clone-on-taint accept. A tainted-arg direct call to a 1-arg pure-classical
; in-module body is detected (pre-pass), cloned + mangled `__cq_q_<callee>_<mask>`
; with internal linkage, seeded on its tainted param, lowered under a disjoint
; `cloneTaint`, and Bennett-wrapped (compute → copy-out → uncompute → free),
; then the call is retargeted via `setCalledFunction`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @scale(i32 %a) {
entry:
  %y = mul i32 %a, 7
  ret i32 %y
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r = call i32 @scale(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; Caller: theta lowered to alloc+ry; the call retargets to the mangled clone.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_scale_1(i32 %[[H]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])
;
; Clone: internal linkage; forward `mul` template; Bennett alloc/copy/_unc/free.
; CHECK:     define internal i32 @__cq_q_scale_1(i32 %a)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %a, i32 7)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[OP]], i32 %[[OUT]])
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[OP]], i32 %a, i32 7)
; CHECK:     call void @cqrt_free(i32 %[[OP]])
; CHECK:     ret i32 %[[OUT]]
;
; No escape decline; the original intrinsic is gone; copy is `_hl`, not `_inv`.
; CHECK-NOT: cq taint escape
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: cq_template_mul_i32_hl_inv
