; control_predmux_accept_residue_orphan_rail_survives.ll — ACCEPT, and ⚠ A P1
; REGRESSION PIN (bd test_C_libtooling-cfmv).
;
; THE DEFECT IT PINS: A VANISHING USER GATE, at the SECOND of PredMuxFlatten's four
; instruction erasers. The rail's only surviving use after the flatten is a folded
; residue (`and i1 %rail, false`); `simplifyFlattenResiduesInFunction` folds it and
; called `RecursivelyDeleteTriviallyDeadInstructions` on the cone, which deleted the
; user's own `@cq_theta_i1`. Measured on the defective binary: `opt` **exit 0**, **0
; BYTES of stderr**, and **no `cqrt_alloc_i1` and no `cqrt_ry_i1` anywhere in the
; stream**. `opt -verify` clean. `free_pairing_check.py` `0 violation(s)` — because
; it is structurally blind to a rail that no longer exists.
;
; That is Rule 5 (the compiler NEVER removes a gate the user wrote) and the
; verify-clean silent-miscompile class this project exists to prevent.
;
; ⚠ THE ATTRIBUTED DECLARATION IS THE POINT OF THE FIXTURE, NOT AN ARTEFACT. The
; pre-existing safety ground at that site was *"RecursivelyDelete removes never a
; cq_theta/phi/measure call — those have side effects"*. That is a property of the
; DECLARATION, not of the code: with `memory(none) nounwind willreturn` the call IS
; trivially dead by LLVM's rules and IS deleted. `CQ.h` cannot emit those attributes
; today, which is why this was filed rather than blocking — but a shipped fence must
; not depend on a header's spelling. ⚠ DO NOT "TIDY" THE ATTRIBUTES OFF THIS
; DECLARATION: that converts the fixture into its own control
; (…_residue_orphan_rail_bare_decl_control.ll) and it stops testing anything.
;
; INCREMENT 1's (K5) LESSON, THIRD INSTANCE: the question was never the name or the
; attribute — it is *does a CQ stage OWN this call?*
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: grep "call i32 @cqrt_alloc_i1(" %t.cqd0.ll | count 1
; RUN: grep "call void @cqrt_ry_i1(" %t.cqd0.ll | count 2
;
; The user's rail is MINTED and ROTATED. On the defective binary both counts are 0.
; (Counts are of CALL sites; the `declare` line is deliberately excluded by the
; `call ... @` prefix — a first draft counted it and read 2/3 instead of 1/2.)
; CHECK: cqrt_alloc_i1
; CHECK: cqrt_ry_i1

declare i1 @cq_theta_i1(i1, double) memory(none) nounwind willreturn
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %dead = and i1 %rail, false
  br i1 %rail, label %arm, label %merge
arm:
  br label %merge
merge:
  %p1 = phi i1 [ false, %arm ], [ false, %entry ]
  %p2 = phi i1 [ %dead, %arm ], [ false, %entry ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %m  = call i32 @cq_measure_si32(i32 %q)
  %s  = add i32 %z1, %z2
  %s2 = add i32 %s, %m
  ret i32 %s2
}
