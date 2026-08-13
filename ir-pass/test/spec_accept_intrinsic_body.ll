; spec_accept_intrinsic_body.ll — Phase 7.1-E follow-up (test_C_libtooling-mvjc)
; × Phase 6: a classical helper whose body contains a CURATED reversible llvm.*
; idiom intrinsic now SPECIALIZES instead of loud-declining. Pre-follow-up,
; `SpecializeReject::scanBody` saw the `@llvm.ctpop.i32` call as a declaration-
; only nested call and rejected the whole candidate ("non-reversibilizable …
; (nested call)") — a SAFE over-decline, not a miscompile. Accepting it
; (`isCuratedReversibleIntrinsic` whitelist, symmetric with the top-level
; `declineTaintEscapes` acceptance and the BinaryOperator/CastInst data-op
; whitelist) lets the SAME machinery the f16 case rides take over: `seedClone`
; taints the intrinsic, `lowerOps` lowers it to the FROZEN `cq_template_ctpop_i32`
; additive producer (7.1-E ABI, NO new symbol), the Bennett wrap captures it in
; the forward stream, copies out ONLY the i32 result, and `emitInverseChain`
; reverses it via its `_unc` twin. `ctpop` is Class-2 (no `_inv`): its `_unc`
; recomputes from the LIVE source — held here because every scratch rail is freed
; only AFTER the complete reverse (BennettWrap step e). The intrinsic is computed-
; then-uncomputed, never measured, never escaped.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.ctpop.i32(i32)

define i32 @ctpop_helper(i32 %a) {
entry:
  %p = call i32 @llvm.ctpop.i32(i32 %a)
  %r = add i32 %p, 1
  ret i32 %r
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r = call i32 @ctpop_helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; Caller retargets to the mangled clone.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_ctpop_helper_1(i32 %[[H]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])
;
; Clone: internal linkage; forward intrinsic producer feeds the downstream add;
; out copy is the i32 RESULT.
; CHECK:     define internal i32 @__cq_q_ctpop_helper_1(i32 %a)
; CHECK:     %[[INTR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctpop_i32(i32 %a)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[INTR]], i32 1)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[OP]], i32 %[[OUT]])
; LIFO uncompute of the whole clone via the `_unc` twins; the ctpop `_unc` reads
; the still-live source `%a`; every rail freed once, AFTER the complete reverse.
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %[[INTR]], i32 1)
; CHECK:     call void @cq_template_ctpop_i32_unc(i32 %[[INTR]], i32 %a)
; CHECK:     call void @cqrt_free(i32 %[[INTR]])
; CHECK:     call void @cqrt_free(i32 %[[OP]])
; CHECK:     ret i32 %[[OUT]]
;
; The raw intrinsic is gone from the clone; the keep-live `_unc` is used, never a
; dirty-freeing `_inv`; the borrowed input was never copied out.
; CHECK-NOT: call i32 @llvm.ctpop.i32
; CHECK-NOT: cq_template_ctpop_i32_inv
; CHECK-NOT: cq taint escape
