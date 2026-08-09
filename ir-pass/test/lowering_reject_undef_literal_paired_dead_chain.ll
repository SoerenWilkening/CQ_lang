; lowering_reject_undef_literal_paired_dead_chain.ll — DECLINE (bd xy9n).
; ARM: `declineUnpairedUndefLiterals` (LiteralIntegrity.cpp), the module-wide
; literal-integrity guard.
;
; *** THIS IS THE FIXTURE THAT DECIDED THE SHAPE OF THE FIX. *** bd xy9n was
; filed against the 4.4 select surface, with a fix direction of "refuse a literal
; undef/poison operand at the 4.4 select classify gate". That direction was
; WRONG, and this module is why: there is NO CONTROL FLOW HERE AT ALL. No branch,
; no select, no switch, no region, no cone proof — just a dead tainted `add` with
; a `poison` literal operand, reversed by the plain Phase-5 whole-DAG LIFO spine.
; Measured on the pre-change plugin (`opt` exit 0, `opt -verify` clean):
;
;   %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 poison)
;   call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 poison)
;
; `EmitInverse` builds every adjoint by copying the forward call's operands
; verbatim (`Forward->getArgOperand(i)`), and `poison` lowers to `IMPLICIT_DEF`,
; which LLVM materialises PER USE. So at the shipped -O0 stage 3 the two lines
; read DIFFERENT literals — 73896 vs 1401299752 on the bd u1rp H1 exhibit,
; deterministic and identical across runs (NOT the ASLR artefact bd bu96
; refuted). The adjoint therefore inverts a different function than the forward
; computed: rail `%h_op` is left dirty AND entangled, and the `cqrt_free` that
; the spine emits next is a hardware reset — a hidden measurement that collapses
; the qubit. Rules 6 and 8.
;
; So the channel is `EmitInverse`'s operand copy, which EVERY surface with an
; adjoint shares — not the select, not PredMux, not any control emitter. That is
; why the guard is module-wide and lives after `uncompute` rather than in a
; per-surface classify gate. See LiteralIntegrity.h for the measured surface
; count and `xy9n-7udx-literal-integrity-decision.md` §1.
;
; `free_pairing_check.py` reports STRICT CLEAN on the pre-change output, because
; the forward/`_unc`/free triple is STRUCTURALLY correct — the operands differ
; only at RUN TIME. No static gate in the tree can see this one.
;
; RED-GREEN: the pre-change plugin ACCEPTS this module with `opt` exit 0
; (measured), so the decline below is genuinely new and this fixture is not one
; of the "declined before too, byte-identical message" kind (bd memory
; [[predmux-decline-fixture-discrimination]]).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: undef/poison literal reaches two emitted gate operands

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %d = add i32 %q, poison                    ; dead terminal — the spine reverses it
  ret void
}
