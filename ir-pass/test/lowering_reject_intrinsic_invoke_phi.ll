; lowering_reject_intrinsic_invoke_phi.ll — DECLINE: a front-end @cq_phi
; (Rz, taint-propagator) intrinsic reached via `invoke` (test_C_libtooling-rzs9,
; family 2/3).
;
; Same root cause as the theta family (collectAndSeed used dyn_cast<CallInst>,
; null on an InvokeInst), the same loud decline. This fixture pins the
; REALISTIC tainted-operand variant AND the double-diagnostic suppression:
;
;   * A VALID `call @cq_theta_si32` seeds taint on `%q`; the invoke'd `@cq_phi`
;     reads that TAINTED handle as its arg-0. So the pipeline runs PAST the
;     propagate early-out (a collected source + sink exist) and reaches
;     declineTaintEscapes — which would otherwise re-flag the phi invoke as an
;     "unknown callee" (it reads a tainted value), a MISLEADING second error
;     for a callee that is in fact KNOWN. collectAndSeed records the declined
;     invoke so declineTaintEscapes skips it by EXACT membership (never by name
;     prefix — a user function named cq_phi_evil must still escape). The only
;     diagnostic is the intrinsic-invoke decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @__gxx_personality_v0(...)

define i32 @slice(i32 %u0) personality ptr @__gxx_personality_v0 {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)   ; valid source — seeds taint
  %p = invoke i32 @cq_phi_si32(i32 %q, double 2.500000e-01)
          to label %cont unwind label %lpad   ; Rz via invoke on a TAINTED handle
cont:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
lpad:
  %ex = landingpad { ptr, i32 }
          cleanup
  ret i32 0
}

; CHECK: error{{.*}}cq taint propagation: front-end intrinsic cq_phi_si32 reached via invoke; only a direct call is supported
