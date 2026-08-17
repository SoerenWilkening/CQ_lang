; control_classical_call_arm_reject_frozen_arg_callee_range.ll — DECLINE (bd 9hea).
; ARM: the CALLEE-SIDE spelling of the poison-conditional parameter attribute, which
; is the spelling the first arm-kill could not witness — and the one the first draft
; of `freezeDischargesHoistedArg` ACCEPTED.
;
; *** WHY THIS ROW EXISTS: THE SIBLING ARM-KILL HAD NO POWER OVER ITS OWN FENCE. ***
; `control_classical_call_arm_reject_frozen_arg_range.ll` writes `range(i32 0, 10)` at
; BOTH the `define` and the call site, so it declines whether the fence reads the call
; site, the callee, or the union — it cannot distinguish a correct fence from a holed
; one. Measured: deleting the token from the CALL SITE alone flipped that module from
; a loud decline to an accept that froze the argument, with the `range` still binding
; on the definition. This file pins the difference.
;
; THE BUG IT PINS. `CallBase::paramHasAttr` FALLS BACK to the callee's `AttributeList`;
; `CallBase::getAttributes()` does NOT — it is the call site alone. The predicate
; triggered off the union and audited the call site, so every callee-side
; `range`/`nonnull`/`align`/`dereferenceable`/`nofpclass` was invisible: the whitelist
; loop saw only `{noundef}` and returned true. The fence now audits BOTH sets, which is
; the invariant to preserve — READ THE SAME SET THE TRIGGER READ.
;
; *** AND CALLEE-SIDE IS THE CANONICAL HOME, NOT THE EXOTIC ONE. *** Real `clang -O1`
; emits parameter attributes on the DEFINITION and often not on the call site, and for
; the `speculatable`-declaration totality route the declaration is the ONLY place a
; parameter attribute can live. The hole was therefore reachable from ordinary legal C
; across two TUs — a gnu attribute on a definition need not appear on another TU's
; prototype — through exactly the `run_slice_multi.sh` llvm-link shape.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; `range` lives ONLY here, on the definition — the call site below is bare `noundef`.
define internal i32 @pf(i32 noundef range(i32 0, 10) %x) #0 {
  %a = add i32 %x, 1
  ret i32 %a
}

define i32 @example(i32 noundef %u0, i32 noundef %n) {
entry:
  %p = shl i32 1, %n                ; poison for %n >= 32
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pf(i32 noundef %p)  ; NOTE: no `range` token at the call site
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; NOTE: no `CHECK-NOT` over the emitted stream — on a `DS_Error` cq-opt writes ZERO
; bytes to stdout, so such an assertion can never match under ANY gate behaviour.
