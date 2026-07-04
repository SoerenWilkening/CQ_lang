; control_classical_call_arm_accept_onward_byref_math.ll — ACCEPT (bd 0vvq
; Increment 1, the by-ref UNFREEZE): a 6.5 classical-call arm whose UNTAINTED merge
; `%out` (`int y = 5; if (q>3) y = f(a)`) flows (via `sitofp`) into an onward by-ref
; libm call `frexp(double, ptr)`, whose exponent out-cell is loaded back and measured.
;
; This case DECLINED under dugh (`control flow under quantum control`): by-ref math is
; a FROZEN-PLAN lowering — `lowerByRefMath` (g387) runs at CQLoweringPass step 2 and
; rewrites only TAINTED by-ref math to `@cq_byref_*` markers. In round 1 the `frexp`
; argument (`sitofp %y`) was a classical double, so it was left RAW; dugh re-taints
; `%out` in round 2, but g387 had already run, so `declineReseedIntoFrozenPlan`
; safely over-declined it.
;
; 0vvq Inc 1 UNFREEZES it: after the second propagation, `repropagateControlMerges`
; RE-RUNS `lowerByRefMath` on the now-tainted call. The tainted-condition diamond is
; already FLATTENED (`lowerControlRegions` ran first), so `analyzeCell`'s
; `underTaintedControl` check — which declined at round 1 on the tainted-`br`
; dominator — now passes, and the `frexp` lowers to the `@cq_byref_frexp` /
; `@cq_byref_frexpexp` producer markers exactly as a round-1 tainted `frexp` would
; (then `lowerOps` → `cq_template_frexp_f64` / `cq_template_frexpexp_f64_to_i32`).
; The exponent is a reversible function of `%out` (`x = m·2^e`) — a valid
; onward-QUANTUM producer — and is measured. (The mantissa marker is dead here, an
; inherited g387 property; see the 0vvq PRD §6.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
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
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]        ; UNTAINTED merge -> %out (quantum in round 2)
  %ecell = alloca i32
  %d = sitofp i32 %y to double                     ; %out-derived double (round-2 tainted)
  %fr = call double @frexp(double %d, ptr %ecell)  ; by-ref libm on the merge -> re-run + lowered
  %e = load i32, ptr %ecell
  %m = call i32 @cq_measure_si32(i32 %e)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; the classical-call arm builds %out via the controlled-XOR copy merge:
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(
; the onward sitofp cast + the RE-RUN g387 by-ref markers over %out, then measure:
; CHECK:     %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[OUT]])
; CHECK:     call i32 @cq_template_frexp_f64(i32 %[[CAST]])
; CHECK:     %[[EXP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_frexpexp_f64_to_i32(i32 %[[CAST]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[EXP]])

; no RAW frexp call survives (only the dead decl), and the region ACCEPTS:
; CHECK-NOT: call double @frexp
; ACC-NOT:   under quantum control
