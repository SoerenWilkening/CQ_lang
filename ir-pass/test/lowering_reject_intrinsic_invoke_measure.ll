; lowering_reject_intrinsic_invoke_measure.ll — DECLINE: a front-end @cq_measure
; SINK intrinsic reached via `invoke` (test_C_libtooling-rzs9, family 3/3).
;
; The second named gap: isMeasureSink also used dyn_cast<CallInst>, so an
; invoke'd @cq_measure was never recognized as a taint SINK — propagation would
; run THROUGH it, over-tainting its result. The robustness fix declines the
; invoke loudly at collection (collectAndSeed) AND switches isMeasureSink to
; CallBase, so any host that continues past the decline still stops taint at the
; measure rather than over-propagating (defense in depth — under `opt` the
; collection decline already exited non-zero).
;
; A VALID `call @cq_theta_si32` seeds taint on `%q`; the invoke'd `@cq_measure`
; reads it. isMeasureSink (now CallBase) recognizes the invoke'd measure as a
; sink, so `%m` stays UNtainted (no over-taint); the declined invoke is recorded
; so declineTaintEscapes skips it — the only diagnostic is the intrinsic-invoke
; decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @__gxx_personality_v0(...)

define i32 @slice(i32 %u0) personality ptr @__gxx_personality_v0 {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)   ; valid source — seeds taint
  %m = invoke i32 @cq_measure_si32(i32 %q)
          to label %cont unwind label %lpad   ; SINK via invoke on a TAINTED handle
cont:
  ret i32 %m
lpad:
  %ex = landingpad { ptr, i32 }
          cleanup
  ret i32 0
}

; CHECK: error{{.*}}cq taint propagation: front-end intrinsic cq_measure_si32 reached via invoke; only a direct call is supported
