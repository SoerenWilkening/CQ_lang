; lowering_reject_undef_literal_paired_rz_angle.ll — DECLINE (bd xy9n).
; ARM: `declineUnpairedUndefLiterals`, the NEGATED-ANGLE RE-EMISSION row.
;
; *** THIS ROW IS WHY THE GUARD COUNTS SLOTS INSTEAD OF LOOKING FOR AN `_unc`
; NAME. *** The obvious spelling of this guard is "refuse a literal undef/poison
; in an `_unc`/`_inv` adjoint". That spelling MISSES this module entirely.
;
; A rotation's adjoint is not a differently-named symbol: `EmitInverse` emits
; `cqrt_rz_<W>(h, fneg θ)` — the SAME symbol with a negated angle
; (EmitInverse.cpp, `CreateFNeg(Forward->getArgOperand(1))`). And `fneg poison`
; constant-folds straight back to `poison`. So the pre-change plugin emits, with
; `opt` exit 0 and verify clean, two lines that are TEXTUALLY IDENTICAL:
;
;   call void @cqrt_rz_i32(i32 %h_op, double poison)
;   call void @cqrt_rz_i32(i32 %h_op, double poison)
;
; At -O0 those are two separate `IMPLICIT_DEF` materialisations, so the second
; `Rz` does not undo the first.
;
; *** THE HARM HERE IS NOT THE SAME AS THE `_unc` ROWS', and an earlier draft of
; this header got it wrong — corrected by the Rule-13 round's trace argument. ***
; `Rz` is DIAGONAL in the computational basis. Writing the pre-pair state as
; Σ_x c_x |x⟩_h |f(x)⟩_rail, the pair multiplies each branch by e^{iδ·g(f(x))} with
; δ = θ1−θ2 and changes NO POPULATION; the following `_unc` is a basis PERMUTATION,
; unaffected by a diagonal phase, so it still restores the rail to |0⟩ on EVERY
; branch and the `cqrt_free` is LEGITIMATE. That is this project's own Rule 5,
; verbatim: "the rail is |0⟩ for free under Rz = diag(1, e^{iθ})".
;
; The residual is nonetheless a real defect: δ·g(f(x)) is x-DEPENDENT, so it is a
; RELATIVE phase across the surviving branch amplitudes, not a harmless global one.
; It migrates onto `h` and corrupts the unitary — invisible to `opt -verify`, to the
; golden trace (which prints the angle it was given), and to
; `free_pairing_check.py` (which is deliberately transparent to `cqrt_rz`, being
; diagonal). Prime Directive / Rule 2, NOT Rules 6 and 8.
;
; So this fixture and the `_unc` fixtures pin TWO DIFFERENT failure modes:
;   * `_unc` rows  — a broken PERMUTATION leaves the rail dirty in POPULATION, so
;                    the `cqrt_free` that follows IS a hidden measurement (6, 8);
;   * this row     — an intact permutation with a wrong x-dependent PHASE, so the
;                    free is fine and the UNITARY is wrong (Rule 2).
; The one guard covers both because it counts slots rather than reasoning about
; either mechanism. Do not "unify" the two rationales.
;
; The slot count is 2, so the guard fires. Any future adjoint form — a
; self-inverse involution, a re-emitted forward, a symbol nobody has invented yet
; — is covered by the same count without editing the guard. That is the whole
; reason the predicate is a count and not a name test.
;
; NOTE `cq_phi` (Rz) is the ANGLE carrier here, and per Rule 3 the arg-1 angle
; operand is CLASSICAL and never propagates taint. That is exactly the point: the
; angle is classical, and a classical literal is precisely what this guard is
; about. `%d` is the tainted handle the rotation acts on, so the module is a real
; tainted-rotation lowering and not a passthrough.
;
; RED-GREEN: measured ACCEPT (`opt` exit 0) on the pre-change plugin.
;
;
; 3qlq(prep_a2): HAND DECISION — the register `cq_phi` here was NEVER the subject.
; This fixture pins an uncompute / mux / measurement-ordering / specialization rule
; and used `%r = cq_phi_<sfx>(%x, θ)` only as "a gate on a handle".  D1 removes that
; spelling, so the gate is re-spelled `cq_theta_<sfx>` — the OTHER in-place rotation
; on the same rail, which is what the corpus uses everywhere else for the same job.
; MEASURED on the Inc-1 binary: the swap reproduces this fixture's ORIGINAL asserted
; diagnostic, so the CHECK lines are UNCHANGED and the property is pinned by exactly
; the text it was pinned by before.  (prep_a measured the same 16 files against the
; pre-3qlq ORACLE; this is the independent re-measurement on the SUBJECT.)
; ⚠ Note what the swap does NOT preserve: Rz is DIAGONAL and Ry is not, so a rule
; that turned on diagonality would move.  None of these 16 do — that is what the
; character-for-character reproduction of the diagnostic establishes.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: undef/poison literal reaches two emitted gate operands

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %d = add i32 %q, 7
  %p = call i32 @cq_theta_si32(i32 %d, double poison)   ; classical angle, undefined
  ret void
}
