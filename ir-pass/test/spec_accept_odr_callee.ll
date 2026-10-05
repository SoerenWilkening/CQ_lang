; spec_accept_odr_callee.ll — ACCEPT (bd test_C_libtooling-p3kd.2, decline->accept
; flip): a tainted direct call to a callee whose definition is `weak_odr`,
; `linkonce_odr` or `available_externally` is LIFTED like an exact one.
;
; WAS: `cq specialization: callee has a non-link-exact definition ...` at the
; callee's entry. `scanBody` asked `hasExactDefinition()`, which in LLVM 19 is
; `!isDeclaration() && !mayBeDerefined()`, and `mayBeDerefined()` is true for the
; three ODR-equivalent linkages as well as for the interposable ones.
;
; WHY THE FLIP IS SOUND. Specialization does not assume anything of the callee's
; LINKED body: it clones the module-local body into an internal `__cq_q_*` clone
; and RETARGETS the call to it, so the body it analyzed is the body that runs at
; that site. That is LLVM's inlining rule (GlobalValue::isDefinitionExact): across
; a derefinable, non-interposable definition the visible body is *a* correct
; implementation of the source function, though not the only one, so running it
; in place of the call is a refinement. A derefined variant elsewhere (one that
; kept a UB-dependent path this copy optimized out) can only run at the CLASSICAL
; call sites the pass leaves alone. available_externally is decided the same way:
; its body is an inlining copy guaranteed equivalent to the external definition,
; and the clone gets internal linkage, so the clone is emitted even though the
; original never is. The question is `calleeBodyTrusted(F, Execute)`
; (CalleeBody.h); every site that ASSUMES a property of a call that still runs the
; linked body keeps `AssumeOfLinkedCall` (the dead-argument drop, the liveness
; body rule, the PredMux purity walk, ChainWalk's label proof, and scanBody's
; nested callees).
;
; SEMANTIC EVIDENCE (trace argument). The module is the three-site spelling of
; spec_accept_single.ll; with the three linkages replaced by external linkage,
; main 7b4e6359's cq-opt emits exactly the clone stream pinned below (measured).
; Per clone: `h_op = <op>_i32_hl(a, c)` writes a FRESH rail with f(a); `out` is a
; fresh |0> rail; `cqrt_copy_i32(h_op, out)` XOR-copies f(a) into it;
; `<op>_i32_hl_unc(h_op, a, c)` returns `h_op` to |0> (same SSA literal `c` as the
; forward); `cqrt_free(h_op)` frees a provably-|0> rail; `out` is returned and
; measured by the caller. The callers' theta rails are never freed (frozen).
; Decline twins: spec_reject_weak_callee.ll (weak), spec_reject_linkonce_callee.ll
; (linkonce), spec_reject_odr_semantic_interposition.ll (an ODR definition the
; loader may interpose), spec_reject_nested_odr_callee.ll (an ODR callee reached
; as a NESTED classical call, whose linked body would run in a duplicated twin).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define weak_odr i32 @scale_wodr(i32 %a) {
entry:
  %y = mul i32 %a, 7
  ret i32 %y
}

define linkonce_odr i32 @shift_lodr(i32 %a) {
entry:
  %y = add i32 %a, 5
  ret i32 %y
}

define available_externally i32 @mask_ae(i32 %a) {
entry:
  %y = xor i32 %a, 9
  ret i32 %y
}

define void @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r0 = call i32 @scale_wodr(i32 %q0)
  %m0 = call i32 @cq_measure_si32(i32 %r0)
  %q1 = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %r1 = call i32 @shift_lodr(i32 %q1)
  %m1 = call i32 @cq_measure_si32(i32 %r1)
  %q2 = call i32 @cq_theta_si32(i32 %u2, double 7.500000e-01)
  %r2 = call i32 @mask_ae(i32 %q2)
  %m2 = call i32 @cq_measure_si32(i32 %r2)
  ret void
}

; ERR-NOT: error
; ERR-NOT: warning
;
; The originals are left as they are (their classical callers, if any, still
; bind whatever the linker chooses).
; CHECK:     define weak_odr i32 @scale_wodr(i32 %a)
; CHECK:     define linkonce_odr i32 @shift_lodr(i32 %a)
; CHECK:     define available_externally i32 @mask_ae(i32 %a)
;
; Caller: every tainted site is retargeted to its clone.
; CHECK-LABEL: define void @example(
; CHECK:     %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H0]], double 2.500000e-01)
; CHECK:     %[[R0:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_scale_wodr_1(i32 %[[H0]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R0]])
; CHECK:     %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H1]], double 5.000000e-01)
; CHECK:     %[[R1:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_shift_lodr_1(i32 %[[H1]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R1]])
; CHECK:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u2)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H2]], double 7.500000e-01)
; CHECK:     %[[R2:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_mask_ae_1(i32 %[[H2]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R2]])
; CHECK:     ret void
;
; weak_odr clone: internal, Bennett-wrapped `mul`.
; CHECK-LABEL: define internal i32 @__cq_q_scale_wodr_1(i32 %a)
; CHECK:     %[[OP0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %a, i32 7)
; CHECK:     %[[OUT0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[OP0]], i32 %[[OUT0]])
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[OP0]], i32 %a, i32 7)
; CHECK:     call void @cqrt_free(i32 %[[OP0]])
; CHECK:     ret i32 %[[OUT0]]
;
; linkonce_odr clone: internal, Bennett-wrapped `add`.
; CHECK-LABEL: define internal i32 @__cq_q_shift_lodr_1(i32 %a)
; CHECK:     %[[OP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %a, i32 5)
; CHECK:     %[[OUT1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[OP1]], i32 %[[OUT1]])
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP1]], i32 %a, i32 5)
; CHECK:     call void @cqrt_free(i32 %[[OP1]])
; CHECK:     ret i32 %[[OUT1]]
;
; available_externally clone: INTERNAL (so it is emitted), Bennett-wrapped `xor`.
; CHECK-LABEL: define internal i32 @__cq_q_mask_ae_1(i32 %a)
; CHECK:     %[[OP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %a, i32 9)
; CHECK:     %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[OP2]], i32 %[[OUT2]])
; CHECK:     call void @cq_template_xor_i32_hl_unc(i32 %[[OP2]], i32 %a, i32 9)
; CHECK:     call void @cqrt_free(i32 %[[OP2]])
; CHECK:     ret i32 %[[OUT2]]
; CHECK-NOT: cq_theta_si32
