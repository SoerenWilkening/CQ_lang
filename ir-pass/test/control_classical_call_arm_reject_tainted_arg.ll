; control_classical_call_arm_reject_tainted_arg.ll — tainted-argument reject
; (DD-7 / WI-5.6 / Rule 3 under-taint): a classical call inside a tainted-condition
; diamond arm with a QUANTUM (tainted) argument is the clone × route composition
; (quantum DATA under quantum CONTROL) — OUT of 6.5 (deferred Phase 4×6), NEVER a
; route-merged classical call.
;
; `if (q > 5) y = pure_f(q);` — `pure_f` is a visible pure body, but its argument
; `q` is tainted. `propagate` taints EVERY non-measure / non-angle user of a
; tainted value (the call is a user of `q`), so the call RESULT is itself tainted;
; the 6.5 recognizer's classical-RESULT gate therefore declines to claim it (a
; tainted result is not a classical call — Rule 3). It falls to `classifyArms`,
; which sees a tainted value-changing merge contribution over the condition's own
; register and fires the §3c clobber diagnostic. Either way it is a LOUD decline —
; never a 6.5 accept (which would hoist+run a classical function on the i32 HANDLE
; TAG, computing garbage). NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @pure_f(i32 %a) #0 {
  %t = mul i32 %a, 2
  ret i32 %t
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pure_f(i32 %q)       ; TAINTED arg — clone x route, OUT of 6.5
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
