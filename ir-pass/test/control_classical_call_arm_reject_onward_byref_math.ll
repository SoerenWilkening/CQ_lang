; control_classical_call_arm_reject_onward_byref_math.ll — DECLINE (dugh, Phase 4×6;
; the by-ref-math frozen-plan crash regression): a 6.5 classical-call arm whose
; UNTAINTED merge `%out` flows (via `sitofp`) into an onward by-ref libm call
; `frexp(double, ptr)`.
;
; THE CRASH THIS PINS (found by the dugh Rule-13 round-2 adversarial sweep, fixed by
; `declineReseedIntoFrozenPlan`): by-ref math (frexp/modf/remquo) is a FROZEN-PLAN
; lowering — `lowerByRefMath` (g387) runs at CQLoweringPass step 2, rewriting only
; TAINTED by-ref math to `@cq_byref_*` markers. In round 1 the `frexp` argument
; (`sitofp %y`) was a classical double, so it was left as a raw `frexp(double, ptr)`.
; dugh re-taints `%out` (= `y`) in round 2, but `lowerByRefMath` already ran and will
; not re-process it; the re-run `declineTaintEscapes` then CARVES the `frexp` via
; `isByRefMathCall` (assuming its owner handled it). The result is an un-lowered
; `frexp` whose `double` arg is the lowered i32 handle (`cq_template_sitofp…(%out)`)
; — a type-mismatched BROKEN MODULE the verifier aborts on (a crash on VALID input,
; Rule 1). The fix declines the frozen-plan call reading a reseed value BEFORE the
; carve. An onward by-ref libm call reading a control-merge register is a classical
; escape (A1) — out of dugh's arith/phase scope. A round-1-untainted (classical)
; frexp still lowers normally. NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0
declare double @frexp(double, ptr)
define i32 @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]      ; UNTAINTED merge -> %out (quantum in round 2)
  %ecell = alloca i32
  %d = sitofp i32 %y to double                   ; %out-derived double (round-2 tainted)
  %fr = call double @frexp(double %d, ptr %ecell) ; frozen-plan by-ref libm on the merge
  %e = load i32, ptr %ecell
  %m = call i32 @cq_measure_si32(i32 %e)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
