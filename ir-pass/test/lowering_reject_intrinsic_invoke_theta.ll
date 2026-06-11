; lowering_reject_intrinsic_invoke_theta.ll — DECLINE: a front-end @cq_theta
; SOURCE intrinsic reached via `invoke` instead of a direct `call`
; (test_C_libtooling-rzs9, family 1/3).
;
; The 42-name front-end surface is OPAQUE EXTERNS; clang -O1 on exception-free
; C always reaches them with a direct `call`. An `invoke` is a TERMINATOR with
; normal + unwind successors, and every lowering stage (RotationLowering /
; MeasureLowering / Uncomputation) inserts plain CallInsts at the call position
; and RAUWs the result — terminator surgery the pipeline has no story for.
;
; The historical gap (PRE-EXISTING, found during the udw §adversarial review):
; collectAndSeed / isMeasureSink used dyn_cast<CallInst>, which returns null on
; an InvokeInst. So an invoke'd @cq_theta was NEVER seeded as a taint source —
; its result `%q` was treated CLASSICAL (a verify-clean UNDER-taint: a downstream
; tainted control-flow that should decline never even starts), and the @cq_theta
; extern survived to a Stage-3 LINK error. Robustness fix (Prime Directive,
; over-declining is always safe): collectAndSeed walks CallBase and declines an
; invoke of any front-end intrinsic LOUDLY, lowering nothing.
;
; The result `%q` is NOT seeded (the invoke is declined), so the downstream
; `call @cq_measure_si32(%q)` reads an UNtainted value — declineTaintEscapes does
; not (mis-)fire on it; the only diagnostic is the intrinsic-invoke decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @__gxx_personality_v0(...)

define i32 @slice(i32 %u0) personality ptr @__gxx_personality_v0 {
entry:
  %q = invoke i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
          to label %cont unwind label %lpad   ; SOURCE via invoke — unlowerable
cont:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
lpad:
  %ex = landingpad { ptr, i32 }
          cleanup
  ret i32 0
}

; CHECK: error{{.*}}cq taint propagation: front-end intrinsic cq_theta_si32 reached via invoke; only a direct call is supported
