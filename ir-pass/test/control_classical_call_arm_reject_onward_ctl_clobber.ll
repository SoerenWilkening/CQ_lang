; control_classical_call_arm_reject_onward_ctl_clobber.ll — DECLINE (yn71, Phase 4×6,
; the CONTROL case): a 6.5 classical-call arm whose UNTAINTED merge `%out` feeds a NEW
; TAINTED-condition diamond whose VALUE arm REWRITES the very register the condition
; reads — `int y = 5; if (q>3) y = f(a); if (y > 7) y = y * 3; measure y`. The onward
; `if (y > 7) y = y*3` is a §3c CLOBBER: the value arm rewrites `%out` while the flag is
; minted from `icmp(%out, 7)`, so the `icmp_inv` strip would read the POST-mul basis and
; fail to un-mint the flag (a dirty entangled rail).
;
; This proves yn71 preserves the DECLINE AUTHORITY: `detectAndLowerOnwardControl` RE-RUNS
; the full `detectControlRegions`/`classifyArms` ladder on the newly-tainted condition,
; so a re-detected onward control the emitter cannot prove declines with the SAME precise
; per-shape message (`arm rewrites a condition operand under quantum control`, §3c) it
; would fire on a first-round region — not a blanket decline, and NEVER a silent accept
; (the one unforgivable bug, Prime Directive). Over-decline is safe.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatableTotalCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_reject_partial_callee.ll (a VISIBLE partial body,
; also declined). Nothing else in this fixture changes; the body is inert.
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]          ; UNTAINTED ccarm merge -> %out
  %c2 = icmp sgt i32 %y, 7                            ; tainted only AFTER the re-seed
  br i1 %c2, label %vw, label %m2                     ; NEW tainted control on %out
vw:
  %v = mul i32 %y, 3                                  ; value arm REWRITES %y the condition reads (§3c)
  br label %m2
m2:
  %z = phi i32 [ %v, %vw ], [ %y, %merge ]
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
