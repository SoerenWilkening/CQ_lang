; spec_reject_multiexit_fp.ll — Phase 6 / issue 5po2 I2 (defensive boundary probe):
; a GENUINE multi-exit (separate `ret` blocks) FP clone whose fp return was rewritten
; to an i32 handle by the fp-ABI (3c6m.54) stays DECLINED. `normalizeReturnMerge`
; would fold the `ret`s into a merge phi, but the phi's type is the clone's declared
; return (i32) while the `ret` values are still x86_fp80 (the RAUW-to-i32-handle only
; resolves later, in `lowerCloneSelect`); building that phi would be a mistyped
; (broken) module. So `normalizeReturnMerge` BAILS on the `retval type != return type`
; mismatch, the multi-exit control survives, and the `lowerCloneControl` backstop
; LOUD-declines it. clang -O1 pre-merges fp early-returns into a single-exit merge
; phi (which DOES lower — see e2e spec_multiexit), so this synthetic separate-`ret`
; fp shape is unreachable from real C; the decline is a safe defensive over-decline
; guarding the mistyped-phi hazard (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @helper(x86_fp80 %x) {
entry:
  %t = fcmp ogt x86_fp80 %x, 0xK40008000000000000000
  br i1 %t, label %a, label %b
a:
  ret x86_fp80 0xK3FFF8000000000000000
b:
  %m = fmul x86_fp80 %x, %x
  ret x86_fp80 %m
}

define x86_fp80 @example(x86_fp80 %u) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u, double 5.000000e-01)
  %r = call x86_fp80 @helper(x86_fp80 %q)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %r)
  ret x86_fp80 %m
}

; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
