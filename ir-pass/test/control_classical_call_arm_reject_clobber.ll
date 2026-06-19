; control_classical_call_arm_reject_clobber.ll — §3c reject (DD-7 / WI-5.3): a
; classical call inside a tainted-condition diamond arm whose result then
; VALUE-CHANGES the condition's own register feeds the condition's lineage.
;
; `if (q > 5) { r = pure_f(7); q2 = q + r; }` — the merge contribution is `q2 =
; add q, r`, a value-changing redefinition of `q`, and `q` is the diamond's
; straight-through (Pred-edge) incoming AND the icmp's tainted operand. Because
; the arm's merge incoming is NOT a direct call result (it is the `add`), the 6.5
; `classifyClassicalCallArm` recognizer DECLINES to claim it (its disjointness
; obligation: the call result must reach the merge directly, never through a
; rewrite of a condition operand). It falls to `classifyArms`, whose value-arm §3c
; closure (`diagonalAliasHit`/`condProvenance`) fires the PERMANENT clobber
; diagnostic: once `q`'s computational-basis value is overwritten, the flag
; `icmp(q0)` references a value no longer in any live register (conservation of
; information — SCOPING §3c). NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @pure_f(i32) #0

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pure_f(i32 7)
  %q2 = add i32 %q, %r        ; VALUE-changes %q (the condition operand) — clobber
  br label %merge
merge:
  %y = phi i32 [ %q2, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
