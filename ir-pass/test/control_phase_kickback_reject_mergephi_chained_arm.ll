; control_phase_kickback_reject_mergephi_chained_arm.ll — DECLINE (bd `3qps` /
; bd `drbq.7`, Track P). THE RED-GREEN PIN THAT THE φ ADMISSION DOES NOT BYPASS
; THE WIRE FENCE.
;
; ⚠ RED ON THE ORACLE FOR THE WRONG REASON, GREEN HERE FOR THE RIGHT ONE. At
; `59ac5b7` this declined `branch phase on a bare i1 condition` — the LEAF
; GRAMMAR refused the φ, so the wire was never examined. With the φ admitted,
; step 5c's rung 0 PASSES (the diamond IS claimed as an `InPlaceRotation`) and
; rung (iii) is what must own it. The string MOVES to
; `condition predates a non-diagonal gate`; the disposition does not.
;
; WHY THIS ONE IS GENUINELY DIRTY, AND IT IS THE DISTINCTION THE WHOLE INCREMENT
; RESTS ON. The arm theta is CHAINED — `%armv = cq_theta_i1(i1 %seed, …)` takes
; the SEED as its arg-0 — so it is an IN-PLACE, NON-DIAGONAL Ry sitting on the
; condition's own wire, and the merge φ names two DIFFERENT basis labels of ONE
; register. `findNonDiagonalWireGate` answers DIRTY off-ancestry and the DT prong
; cannot rescue it (the gate is BEFORE the branch, not after).
;
; THE ACCEPTED SHAPE IS THE OPPOSITE CASE: in
; `control_phase_kickback_mergephi_rail.ll` the arm theta is a SOURCE
; (`cq_theta_i1(i1 false, …)`, a CLASSICAL arg-0) and the φ's other incoming is
; the constant seed, so `walkNonDiagonalWireGates`' backward closure stops at the
; classical arg-0 and marks the producing theta ON-ANCESTRY EXEMPT — the wire is
; CLEAN. Read the two files as a PAIR: same construct, opposite verdicts, and the
; discriminator is what the arm theta's arg-0 is. That is why bd `3qps` was filed
; as a LEAF-GRAMMAR over-decline and NOT as this fence.
;
; ⚠ RETIREMENT TRIGGER: this stays a DECLINE until bd `drbq.7` lands. Do not
; "fix" it by narrowing the φ's rung-(iii) seed to the arm theta alone — that
; same cone is what refuses the in-place-ARM φ family (bd `3d8q`), and narrowing
; it first converts an over-decline into an OVER-ACCEPT.
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
  %seed = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %armv = call i1 @cq_theta_i1(i1 %seed, double 2.000000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %armv, %arm ], [ %seed, %entry ]
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 3.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
