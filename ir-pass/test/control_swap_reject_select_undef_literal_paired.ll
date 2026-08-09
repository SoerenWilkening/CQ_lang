; control_swap_reject_select_undef_literal_paired.ll — DECLINE (bd xy9n).
; ARM: `declineUnpairedUndefLiterals`, on the surface the ticket was FILED
; against — the 4.4 tainted-condition select (SelectClassify / SelectMergeEmit).
;
; This is bd xy9n's own exhibit. A plain tainted-condition `select` with a literal
; `poison` in the condition compare's classical operand: NO branch, NO region, NO
; cone proof, and — unlike every other member of the poison family — NO UB
; anywhere in the source. The bd u1rp fence does not reach it, because that fence
; lives in `coneDefinedAfterFlagDrop`, which only runs on a poison-SHIELDED
; select-form inside a CLAIMED PredMux region.
;
; Measured on the pre-change plugin, `opt` exit 0 and verify clean:
;
;   %h_cmp = call i32 @cq_template_icmp_slt_i32_hl(i32 %h, i32 poison)
;   ... the controlled-XOR copy merge ...
;   call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 poison)
;   call void @cqrt_free(i32 %h_cmp)
;
; Two reads of one `IMPLICIT_DEF`, so the compare-`_unc` strip inverts a
; DIFFERENT predicate than the forward computed, `%h_cmp` is left dirty and
; entangled with `%h`, and the `cqrt_free` on the next line is a hidden
; measurement. Rules 6 and 8. `free_pairing_check.py` reports STRICT CLEAN on that
; output — the triple is structurally perfect and the divergence is purely a
; run-time one.
;
; THE FIX IS NOT HERE. The ticket proposed a refusal at the 4.4 select classify
; gate; measurement showed the same break reaches with no control flow at all
; (lowering_reject_undef_literal_paired_dead_chain.ll), so the guard is
; module-wide and this fixture exists to pin that the SELECT surface is covered
; BY it — not to pin a select-local gate. There is deliberately no gate in
; `SelectClassify.cpp` for this.
;
; SCOPE NOTE, and read it before generalising: the sentence in
; control_predmux_reject_selectform_rotation_poison_arg.ll that says "only the
; shielded form is a miscompile" is TRUE FOR THAT SURFACE ONLY. There, a poison
; reaching a plain `and i1` reaches the `br`, so the source is already UB and
; nothing well-defined breaks. Here there is no branch to make UB of, and the
; break is in the adjoint pairing rather than in the flatten.
;
; RED-GREEN: measured ACCEPT (`opt` exit 0) on the pre-change plugin. The
; matching defined-literal control is control_swap_accept_select_int_literal.ll's
; family — every existing 4.4 accept fixture is that control, and all stay green.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: undef/poison literal reaches two emitted gate operands

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp slt i32 %q, poison
  %a = select i1 %c, i32 0, i32 %q
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
