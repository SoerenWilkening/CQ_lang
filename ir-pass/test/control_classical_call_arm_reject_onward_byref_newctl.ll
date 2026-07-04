; control_classical_call_arm_reject_onward_byref_newctl.ll — DECLINE (bd 0vvq
; Increment 1, the adversarial nested-control partition): a 6.5 classical-call arm
; whose UNTAINTED merge `%out` feeds a NEW downstream tainted-condition `if (%out > 7)`
; whose arm contains the `frexp`.
;
; The inner `br i1 %cc` was a CLASSICAL branch at detection time (`%out` was untainted
; then), so `detectControlRegions` did NOT flatten it. After the second propagation
; taints `%out`, the `frexp` in that arm is under a LIVE, NON-flattened tainted `br`.
; The 0vvq by-ref re-run's `analyzeCell`/`underTaintedControl` catches the tainted-`br`
; dominator and loud-declines — a `frexp` UNDER quantum control would need a controlled
; reversible lowering we do not do (nested onward control is bd yn71 territory, not
; 0vvq). Confirms the UNFREEZE accepts ONLY a straight-line (post-flatten) by-ref call,
; never one under residual quantum control (Prime Directive). NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}by-ref math out-param under quantum lift (under quantum control)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0
declare double @frexp(double, ptr)
define i32 @example(i32 %u0, i32 %a) {
entry:
  %ecell = alloca i32
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]           ; UNTAINTED merge -> %out
  %cc = icmp sgt i32 %y, 7                            ; NEW condition on %out (round-2 tainted)
  br i1 %cc, label %use, label %skip
use:
  %d = sitofp i32 %y to double
  %fr = call double @frexp(double %d, ptr %ecell)     ; frexp UNDER the new tainted br
  %e = load i32, ptr %ecell
  br label %skip
skip:
  %ee = phi i32 [ %e, %use ], [ 0, %merge ]
  %m = call i32 @cq_measure_si32(i32 %ee)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
