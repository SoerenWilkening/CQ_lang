; spec_reject_fpret_classical_tainted_diamond.ll — Phase 6 / issue 5po2 I2 (the
; Rule-12 fixture for buildClone fp-mispredict GUARD 1, predict-TRUE/actual-FALSE).
; A callee with a TAINTED diamond on the quantum param `%x` but a GENUINELY-CLASSICAL
; fp return `%k` (a classical pass-through arg, mask `01`): `predictReturnTainted`'s
; I2 over-approximation predicts the return tainted (a tainted conditional terminator
; exists) → `cloneFor` rewrites the fp return to an i32 handle, but `lowerCloneSelect`
; does NOT mint a tainted out rail (the return `%k` is not the flattened select, it is
; a classical arg) → actual `ReturnTainted=false`. Guard 1 catches the over-prediction
; (`!ReturnTainted && i32-return && fp-orig`) and LOUD-declines rather than emit a
; mistyped `ret x86_fp80 %k` in an i32-declared clone. This shape is DEGENERATE (the
; tainted diamond's result is dead when the return is classical, so `clang -O1` DCEs it
; — unreachable from real C); the decline is a safe defensive over-decline (Prime
; Directive). Pins the guard-1 diagnostic character-for-character.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @helper(x86_fp80 %x, x86_fp80 %k) {
entry:
  %t = fcmp ogt x86_fp80 %x, 0xK4005C700000000000000
  br i1 %t, label %a, label %b
a:
  %r1 = fadd x86_fp80 %k, %x
  br label %m
b:
  %r2 = fmul x86_fp80 %k, %x
  br label %m
m:
  %dead = phi x86_fp80 [ %r1, %a ], [ %r2, %b ]
  ret x86_fp80 %k
}

define x86_fp80 @example(x86_fp80 %u, x86_fp80 %kk) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u, double 5.000000e-01)
  %r = call x86_fp80 @helper(x86_fp80 %q, x86_fp80 %kk)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %r)
  ret x86_fp80 %m
}

; CHECK: error{{.*}}cq specialization: floating-point return-taint could not be proven under quantum lift
