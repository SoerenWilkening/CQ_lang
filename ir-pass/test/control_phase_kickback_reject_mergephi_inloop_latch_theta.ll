; control_phase_kickback_reject_mergephi_inloop_latch_theta.ll — DECLINE
; (bd `test_C_libtooling-52og`, Track P′). THE BACK-EDGE HALF OF THE CFG-BOUNDED
; SCAN, AND IT IS THE CLAUSE A READER WILL BE TEMPTED TO DELETE.
;
; THE SHAPE: an outside controlled state PREP whose merge φ `%b1` conditions a
; kickback INSIDE a bounded loop (bd `52og`'s customer, whose clean twin is the
; ACCEPT `control_phase_kickback_mergephi_inloop_outside_prep.ll`), with a CHAINED
; `cq_theta_i1(%b0, …)` in the LATCH — i.e. AFTER the kickback's own branch in
; program order, and **on a DIFFERENT wire from the condition**.
;
; ⚠ THE OFF-WIRE OPERAND IS THE WHOLE POINT, AND THE FIRST VERSION OF THIS FILE
; GOT IT WRONG. It was written with `cq_theta_i1(%b1, …)` — a latch theta on the
; condition's OWN provenance wire — and its header claimed *"delete that one `for`
; over `successors(Pred)` and this file goes green"*. **MEASURED BY SOURCE
; MUTATION (S-M1, `trackP/probes/source_mutation.sh`): it did NOT go green.** An
; on-wire latch theta is refused by `wireGainsNonDiagonalGate` on its own —
; `provablyBefore(BI, T)` needs `!isPotentiallyReachable(T, BI)`, and the back edge
; makes the latch reach the branch — so that spelling is DOUBLY COVERED and pins
; the positional clause not at all. The operand is `%b0` here, which
; `condProvenance(%b1) = {%b1, %t}` does not contain and no forward user edge
; reaches, so the wire walk is blind to it and only the positional scan can see it.
; With the back-edge clause removed this file FAILS; with it, it declines.
;
; ⚠ THE LESSON, recorded because it is the general one: a decline fixture reached
; by TWO roads measures neither. Rule 12(c) says validate by MUTATION, and the
; mutation here was of the PASS SOURCE, not of the fixture — because the fixture
; also declined on the pre-change binary (through the old unconditional
; cross-block bail), so its redness on the subject proved only that *something*
; declines. Compare `…_cross_block_theta.ll`, which is deliberately left doubly
; covered and says so, and `…_cross_block_offwire_theta.ll`, which is its
; single-road twin.
;
; WHY A FORWARD SCAN THAT STOPPED AT `Pred` WOULD MISS IT. The theta executes after
; trip 1's mint and BEFORE trip 2's, so from trip 2 on the flag would be minted on a
; register the theta has already moved while `%b1` still denotes the pre-loop value.
; `chainedThetaBetweenDefAndBranch` therefore pushes `Pred`'s successors ON THE SAME
; `isPotentiallyReachable(S, Pred)` test it uses everywhere else: in an acyclic
; region no successor of `Pred` can reach `Pred` and the clause contributes NOTHING,
; while on a cycle it walks the whole body.
;
; ⚠ RETIREMENT TRIGGER / SCOPE. The IN-`Pred` window is deliberately NOT given this
; treatment — a φ or compare in `Pred` with a latch theta keeps the pre-existing
; disposition, which is the documented P5 residual and a DECLINE-direction change
; this track did not make. If that residual is ever closed, this file's argument is
; the one to reuse, and the two windows should then be one.
;
; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br label %header
header:
  %i = phi i32 [ 0, %merge ], [ %inext, %latch ]
  br i1 %b1, label %ph, label %latch
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %latch
latch:
  %c = call i1 @cq_theta_i1(i1 %b0, double 7.000000e-01)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %header
exit:
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}

; ⚠ bd dm7f.53 MOVED THE STRING, NOT THE DISPOSITION. The cross-block phi's
; positional prong is now the WIRE-SCOPED `crossBlockPhiLeafMintable`, which
; does not count the latch Ry on `%b0` (off the phi's rail) against the read of
; `%b1` — physically right: t's rail is untouched. What remains wrong with this
; module is the latch itself: every trip re-reads the SSA name `%b0` after the
; previous trip's Ry relabelled it (a sibling in-place Ry, bd 3d8q), and the
; stale-reader fence owns that, loudly.
; CHECK: cq opcode lowering: rotation/measure operand predates a non-diagonal gate
