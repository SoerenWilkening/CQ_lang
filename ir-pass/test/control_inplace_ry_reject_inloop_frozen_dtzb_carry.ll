; control_inplace_ry_reject_inloop_frozen_dtzb_carry.ll — DECLINE (in-loop): a
; FROZEN identity-carry record on the rotated register's own wire, whose only
; other in-body mover is a dtzb in-place `add`.
;
;     for (…) { x = x;                       <-- %x = phi [%r0, pre], [%x, latch]
;               cq_measure(x);               <-- read of the PRE-LOOP register
;               if (q > 5) r = cq_theta(r, 0.9);
;               r = r + 3; }                 <-- dtzb in-place VALUE gate
;
; WHY THIS SHAPE WAS BUILT (bd test_C_libtooling-drbq Inc 3, round-1 lens L5 Q3).
; R6's per-activation certificate is `D REFRESHES ∧ every path BI → p(U)
; re-executes D`, and the REFRESH half is `WireWalk::phiTracksWire`, which is
; spelled over `thetaOnPathTo` — i.e. it counts a `cq_theta` as a staler and does
; NOT count the dtzb in-place `add`/`xor` that `LoopLowering::collectRailGates`
; DOES count as a rail-relabelling gate. In the fence's OLD caller `false` was
; the conservative answer (a barrier that refuses); in `recordLivePerActivation`
; the polarity is INVERTED — `true` GRANTS. So a φ whose wire was moved only by a
; dtzb `add` between its incoming and its edge would be granted a refresh it did
; not earn. That is one gate-family over from bd
; [[identity-carry-phi-does-not-refresh]], which was a CONFIRMED silent
; miscompile, so it was worth building rather than arguing.
;
; MEASURED ANSWER: REFUTED — the fence is not the decider, and it cannot be for
; this class. Five probes, HEAD, 2026-09-04:
;   * this file, and the same file with the `add` replaced by a `cq_phi` hop:
;     BOTH decline `stale rail record read past a controlled Ry`.
;   * the same file with the frozen φ DELETED: ACCEPTS. So the φ is the cause.
;   * the same file with the frozen φ present but NEVER READ: still DECLINES —
;     which is the discriminator. The refusal does not need the read at all.
;   * the same file with the frozen φ seeded from a SEPARATE mint (off `r`'s
;     wire): ACCEPTS. So the refusal is wire-scoped and not a blanket φ ban.
;
; WHAT ACTUALLY REFUSES IT, and why the fence can never be reached this way. A
; frozen carry is ITS OWN USER on the latch edge, so R6 asks the mirrored pair
; (M = %x, U = %x) and takes the PHI-EDGE READ POSITION — the terminator of the
; incoming block, here the merge — at which point `everyPathReExecutes(BI,
; merge-terminator, %x)` is FALSE, because `BI → merge` never re-enters the
; header. The path conjunct refuses before the refresh conjunct is consulted.
; And the fence cannot become the decider by removing the identity carry either:
; any OTHER φ on this wire has an incoming whose `collectWireValues` closure
; REACHES the region's own arm `cq_theta` (it is an in-place gate on `%r`), so
; `thetaOnPathTo` finds a theta and the fence answers `false` anyway. The
; dtzb-only wire the finding needs would have to exclude the arm's theta while
; including the add — and the add's operand chain runs back through the very
; value the theta writes.
;
; ⚠ RETIREMENT TRIGGER, THREE WAYS, because "refuted today" is not "impossible":
; this argument dies the moment the PHI-EDGE READ POSITION rule is relaxed, or
; `recordLivePerActivation` admits a non-φ `D` that can be frozen, or
; `LoopLowering::collapseRailPhisIn` step (1)'s LOOP-CARRIED guard is relaxed
; (`kMsgCrossIter` — "cq loop lowering: loop-carried tainted value crosses
; iterations"). Any of the three makes `phiTracksWire` the only wall, and its
; `cq_theta`-only vocabulary becomes live in the GRANTING direction.
;
; THE THIRD LEG IS A ROUND-2 CORRECTION, and it is the honest part of this
; header. Round 2 built the shape the two paragraphs above do NOT cover — a
; NON-frozen carry seeded from the region's MERGE value (M-β's hoisted `T`), with
; the dtzb `add` placed AFTER the region on the sibling chain and the carry read
; IN THE BODY, so that R6's path conjunct is satisfiable rather than failing as
; leg (1) assumes. It DECLINES (`cq loop lowering: loop-carried tainted value
; crosses iterations` on HEAD; the pre-Inc-3 oracle refuses it one stage earlier
; with `control flow inside a loop body under quantum control`), so there is no
; defect — but NEITHER of the two legs above is what refused it. A refutation
; that names only the fences it happened to meet is a refutation with an unknown
; boundary. The same trigger is written at the call site
; (`ArmClassify::recordLivePerActivation`) and at the export
; (`WireWalk.h::phiTracksWire`); all three must move together.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rn, %merge ]
  %x = phi i32 [ %r0, %entry ], [ %x, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %mm = call i32 @cq_measure_si32(i32 %x)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %rn = add i32 %rm, 3
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rn)
  %s = add i32 %m, %mm
  ret i32 %s
}
