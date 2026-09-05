; control_tainted_diag.ll — transitional guard for the `swap-route-control` branch.
;
; The old controlled-op lowering was removed so the RSSA swap-route control
; emitter can be built without it. A tainted-condition `br i1` (a quantum-
; controlled region) that the compiler cannot PROVE must DIAGNOSE loudly
; ("… under quantum control") and fail (non-zero exit) — it must NEVER silently
; pass through as classical control over quantum state (a verify-clean silent
; miscompile). That is what this file asserts, and its CHECK is deliberately
; LOOSE — the tail `under quantum control`, not a particular clause — because the
; property is "some loud control decline fires", not "this one does".
;
; A classical-condition branch stays byte-untouched (detection keys strictly on
; condition taint) — covered by the passthrough fixtures, not here.
;
; ===========================================================================
; 3qlq(prep_a2): HAND DECISION — RE-SPELLED with `cq_theta`, and the header's
; STATED GROUND is corrected rather than left standing.
;
; WHAT IT USED TO BE: the arm was `%y1 = cq_phi_si32(%y0, θ)` — an Rz rotating
; the CLASSICAL argument `%y0` — and the old header said it "fails
; accept-criterion 3 (quantum base)". Under D1 a `cq_phi` has no base at all: it
; phases the BRANCH, so "the arm rotates a classical register" is not a shape the
; phase stem can express any more. Migrating it mechanically produced
; `cq_measure_si32(i32 %y0)` — a CLASSICAL value at a quantum sink — so the
; module stopped being a well-formed CQ program and the decline became a
; WELL-FORMEDNESS error rather than a control one. That would have been a green
; fixture pinning nothing it claims.
;
; RE-SPELLING: the arm rotates the classical `%y0` with `cq_theta`, which is the
; stem that still HAS an arg-0, so the classical-base shape is expressible again
; and the module is well-formed.
;
; ⚠ THE CLAUSE THAT FIRES HAS MOVED, and the header must not pretend otherwise.
; MEASURED on `build/ir-pass/cq-opt`: it is now
; `state prep seed does not match the merge incoming under quantum control` —
; bd drbq Inc 4's F1, which looks at this shape FIRST because a classical arg-0
; theta in a tainted arm IS the state-prep pattern. The file still asserts only
; the loose tail, so the assertion is unchanged and true; the ground is not, and
; is restated here instead of being quietly inherited.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %y0) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %y1 = call i32 @cq_theta_si32(i32 %y0, double 2.500000e-01)  ; rotates the CLASSICAL %y0
  br label %merge
merge:
  %y = phi i32 [ %y1, %arm ], [ %y0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
