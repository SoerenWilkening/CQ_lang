; control_inplace_ry_stateprep_rail_i1_seed.ll — ACCEPT: a controlled STATE PREP
; of a `_Bool` under a bare `_Bool` (rail-root) condition. `probes/M1.c` of the
; Track-C (bd `drbq.14`) session, verbatim, through `clang -O1`:
;
;     bool b0 = cq_theta(0, 0.5);    // a BARE RAIL condition: `br i1 %1`
;     bool b1 = 0;
;     if (b0) b1 = cq_theta(b1, 0.5);
;
; ⚠ THIS FILE WAS `control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll` AND
; ITS IR IS BYTE-UNCHANGED (`git mv`). It was committed by the F2 narrowing
; EXPLICITLY as a retirement-triggered decline — *"when `l4x4` lands, this file's
; string changes and it becomes an ACCEPT whose emitted stream is
; `cqrt_alloc_i1(false)` + `cqrt_ry_i1_controlled(h_b0, h_new, 0.5)` — with the
; register `h_b0` ITSELF as the control, no mint, no strip, no free. Re-derive it
; then; do not delete it."* That is exactly what is asserted below, re-derived
; from the pass output rather than copied from the prediction.
;
; ⚠ MERGE NOTE (2026-09-11, `MERGE_l4x4_2.md` §2). Track C landed on `main`
; a9cc062 with the file still under its OLD name, and this branch had already
; `git mv`'d it — so `git merge main` RESURRECTED the retired decline beside this
; accept: ONE module, TWO fixtures, CONTRADICTORY verdicts, and `ir-pass-lit`
; went red on the stale one. The resurrected copy was DELETED in the merge commit
; (not re-renamed — the rename target is this file, and it already carries the
; re-derivation the retirement note asked for). MEASURED at the merge on that
; exact module: the merged binary ACCEPTS it emitting `cqrt_alloc_i1` x2 +
; `cqrt_ry_i1` + `cqrt_ry_i1_controlled` and nothing else, and the frozen
; 0c7380c ORACLE declines it `bare i1 register condition`.
;
; TWO FENCES HAD TO MOVE FOR THIS ONE MODULE AND THEY ARE IN DIFFERENT
; INCREMENTS, which is why it is the right file to pin the pair:
;   * WALL 2, l4x4.b (this increment): `classifyArms`' first gate admits the rail
;     leaf and runs the §13.3 ladder instead of declining
;     `bare i1 register condition`.
;   * WALL 3, Track C / bd `drbq.14` (the base this branch sits on): F2's
;     `CondWire` narrowing. An `i1` SEED under an `i1` CONDITION collides on BOTH
;     edges by construction — an `i1` has only two values — so before the
;     narrowing F2 refused it `state prep seed is proven equal to the condition
;     register`. The narrowing excludes values on the CONDITION'S OWN BACKWARD
;     WIRE, and `b0` is the condition, so the collision is gone and the α theorem
;     covers it: the RIVAL reading (`if (b0) b1 = cq_theta(b0, .5)`, an in-place
;     Ry on the condition register) is refused by R4/rung (iii), measured.
;
; ⚠ WALL 1 IS STILL STANDING, AND THIS FILE MUST NOT BE READ AS *"the owner's
; `grover_oracle_uncompute.c` compiles now"*. That program's second and third
; `if`s are FUSED by `-O1` into ONE diamond carrying TWO merge phis, which
; declines `control flow` (bd `b6ap`, the multi-phi peel, on its own branch).
; What is measured here is the SECOND REGION IN ISOLATION — the shape `b6ap` will
; hand to this code.
;
; ---- HISTORY (the decline this file used to pin, kept verbatim) ------------
; control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll — DECLINE, AND NOT
; AT F2. The string this file pins is `bare i1 register condition`, not
; `state prep seed is proven equal to the condition register`.
;
; It exists so that the 2026-09-11 ruling cannot be misread as *"the owner's
; `grover_oracle_uncompute.c` compiles now"*. It does not. F2 was **wall 3 of
; 3**, and this file is wall 2 standing in the same program.
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also
; WE DO NOT WANT ANOTHER cq function. it should just be an application of gates
; … I dont see the need for the over-decline."* (bd `drbq.14`; F2's `CondWire`
; narrowing — a pinned value on the CONDITION'S OWN BACKWARD WIRE is no longer a
; collider.)
;
; `probes/M1.c`, verbatim, through `clang -O1`:
;
;     bool b0 = cq_theta(0, 0.5);    // a BARE RAIL condition: `br i1 %1`
;     bool b1 = 0;
;     if (b0) b1 = cq_theta(b1, 0.5);
;
; With NO compare in front of it, `classifyArms` declines the rail leaf on the
; in-place-Ry / state-prep arm path (bd `l4x4`, Inc 1b-C, OPEN) before F2 is
; ever asked. Its `int`-compare twin —
; `control_inplace_ry_stateprep_bool_seed_int_cond.ll`, one token away —
; ACCEPTS.
;
; ⚠ MEASURED 2026-09-11 ON THE NARROWED BINARY, so this is a statement about the
; shipped tree and not a prediction: `probes/V0.c` (the owner's file, verbatim)
; ⇒ `control flow` (TWO merge phis, bd `b6ap`, wall 1); `probes/C2.c` (V0 minus
; one `cq_measure`, so ONE phi) ⇒ `bare i1 register condition` (wall 2); this
; module ⇒ the same. The narrowing moved exactly one of the three walls.
;
; RETIREMENT: when `l4x4` lands, this file's string changes and it becomes an
; ACCEPT whose emitted stream is `cqrt_alloc_i1(false)` +
; `cqrt_ry_i1_controlled(h_b0, h_new, 0.5)` — with the register `h_b0` ITSELF as
; the control, no mint, no strip, no free. Re-derive it then; do not delete
; it.
;
; kept only as documentation: a `DS_Error` decline writes ZERO bytes to
; stdout, so `2>&1 | FileCheck` sees the diagnostic and nothing else.
; The property they describe — no gate is emitted — is pinned by the
; `not` inversion on the RUN line above, which is what actually fails
; if this module ever lowers.
; (the old RUN line and its decline assertions are dropped from this
;  quotation: lit and FileCheck match their prefixes as substrings
;  anywhere on a line, so quoting one would make it LIVE again.);
; ⚠ SHARED GROUND, TRUE OF EVERY `control_inplace_ry_rail_*` ACCEPT AND STATED
; ONCE PER FILE RATHER THAN GUESSED (bd test_C_libtooling-l4x4, sub-increment
; l4x4.b; SCOPE §2.1 / §2.7):
;   * THE FLAG IS THE REGISTER. `classifyArms` admits a bare `_Bool` condition
;     (`isCondRailLeaf` — a `cq_theta_i1` result) and `emitInPlaceRotationRegion`
;     sets `Flag = Cond`, so NOTHING IS MINTED (`NOMINT`), NOTHING IS STRIPPED,
;     and the register is NEVER FREED (`FCNT`) — after `Ry(θ)|0⟩` it is not `|0⟩`,
;     so a `cqrt_free` would be a hidden measurement (Rule 6). It is LEFT
;     ALLOCATED, which is the REQUIRED direction: the same Rule-6-safe leak the
;     COMPARE form already gives its own condition register (probe `t11c`).
;   * NO `cqrt_x` ON A USER REGISTER, EVER (`NOX`) — bd `3qlq.4`'s invariant.
;   * THE CONTROL IS ONE QUBIT. `isCondRailLeaf` is a `cq_theta_i1` result, hence
;     a `cqrt_alloc_i1` — exactly the width a minted compare flag has. Nothing
;     about `cqrt_ry_<W>_controlled`'s tensored semantics changes; l4x4.b changes
;     WHO arg-0 is and nothing else.
;   * THE ROTATED RAIL IS FROZEN by `ChainWalk::railCarriesControlledRotation`,
;     which derives it from the emitted gate's own ARG-1 use. ARG-0 — the user's
;     register — is NOT frozen by that predicate and must not be: it is not an
;     in-place gate on it (`isInPlaceGateOn` requires arg-1 == H) and the generic
;     `_controlled` bail refuses it, so `isTerminalHandle` says "not a terminal"
;     and `preservesBasisUnderRecord`'s disqualify list keeps it out of the M-B
;     interior. That asymmetry is the whole disposition of `b` (SCOPE §2.7, H-9).
;   * RED ON `main` 0c7380c AND ON the F2 checkpoint 578dbc4, which both decline
;     `bare i1 register condition` at `classifyArms`' first gate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOMINT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CRCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br i1 %1, label %2, label %4

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br label %4

4:                                                ; preds = %2, %0
  %5 = phi i1 [ %3, %2 ], [ false, %0 ]
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %7 = zext i1 %6 to i32
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2
  %9 = zext i1 %8 to i32
  %10 = add nuw nsw i32 %9, %7
  ret i32 %10
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}

; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[B]], i32 %[[R]], double 5.000000e-01)
;
; ---------------------------------------------------------------------------
; THE NEGATIVES ARE WHOLE-FILE AND PURE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 lesson:
; a POSITIVE directive inside a prefix WINDOWS every negative one of that
; prefix, so every count lives in its own CNT prefix and no `-NOT` shares a
; prefix with a positive). `NOX` is THE NON-NEGOTIABLE: bd `3qlq.4`'s invariant
; is "never a `cqrt_x` on a user register", and the rail path has no ancilla to
; put one on either, so the whole-file form is both stronger and true.
; NOX-NOT: call void @cqrt_x(
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: cq_phi
; NOROUTE-NOT: = phi
; NOMINT-NOT: cq_template_icmp
; CRCNT-COUNT-1: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; RYCNT-COUNT-1: call void @cqrt_ry_{{[a-z0-9]+}}(
; RYCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}(
; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-NOT: call void @cqrt_free(
