; spec_reject_weak_callee.ll — bd gxhi (P2, found by the adia 3c6m.55 Rule-13
; board, skeptic-refutation round 2026-07-17): a PLAIN DIRECT tainted call to a
; callee whose definition is NOT link-exact must DECLINE. Phase-6 specialization
; ANALYZES the callee body and CLONES it into a Bennett twin the tainted path
; calls in place of the callee; if the linker may bind a DIFFERENT body at
; stage 3 the analyzed+cloned unitary diverges from the linked program
; (verify-clean, no diagnostic — the confirmed fence gap). `hasExactDefinition()`
; is FALSE for an INTERPOSABLE definition (weak / linkonce / common / extern_weak
; — the linker may substitute an ARBITRARY body) AND for a DEREFINABLE one
; (weak_odr / linkonce_odr / available_externally — a differently-optimized ODR
; variant may bind), so every non-link-exact definition declines. EXACT mirror of
; the E4 pending-spec fence `isSpeculatablePureCalleeBodyImpl` (PredMuxFlatten.cpp)
; and the ByRefInline `hasLocalLinkage` precedent (Rule 14), so the spec-clone and
; E4-speculation accept-surfaces stay aligned. The body is otherwise the exact
; `spec_accept_single.ll` accept shape — ONLY the `weak` linkage differs — so this
; isolates the interposability decline. NO control: this is the direct-call gap
; the E4 fence (which fires only inside a PredMux control region) never covered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define weak i32 @purefn(i32 %a) {
entry:
  %y = mul i32 %a, 7
  ret i32 %y
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r = call i32 @purefn(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK: error{{.*}}cq specialization: callee has a non-link-exact definition (interposable/derefinable linkage); the linker may bind a different body
; The interposable body is NEVER cloned into a Bennett twin.
; CHECK-NOT: @__cq_q_purefn
