; control_phase_kickback_reject_mergephi_measure_before.ll — DECLINE (bd `3qps`,
; Track P). RUNG (ii), AND IT IS THE LOAD-BEARING HALF OF STEP 5c.
;
; `cq_measure(b1)` before the kickback COLLAPSES the register the branch reads,
; so the gate would fire on a measured rail (Rule 6's loud-reject class).
;
; ⚠ WHY THE CLOSURE, AND NOT THE HOISTED THETA ALONE. The user's measurement
; names the **φ**, while `railWireNamesBackward` `break`s at the first non-call —
; so a closure seeded only from the arm theta is the singleton `{T}` and this
; measurement is INVISIBLE, i.e. an OVER-ACCEPT. Step 5c therefore asks
; `railMeasuredBeforeReadPoint` over `condProvenance(φ) = {φ, T}`, which is ALSO
; exactly the seed set rung (iii) walks: ONE closure, two rungs (CLAUDE.md L2 —
; "when you widen a set, ask what OTHER set was computed over the same closure").
; bd `boi6` H-2 measured this same hole at the 4.4 select; this file is its twin
; at the kickback.
;
; ⚠ ORACLE: `branch phase on a bare i1 condition` at `59ac5b7` — the grammar
; refused the φ before anything was asked. String moves, disposition does not.
; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  %e = call i1 @cq_measure_i1(i1 %b1)
  br i1 %e, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  ret i1 %e
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
