; lowering_reject_undef_literal_paired_alias_unc.ll — DECLINE (bd xy9n).
; ARM: `isEmittedRuntimeCallee` testing the CALLED OPERAND rather than
; `getCalledFunction()`.
;
; *** THE RULE-13 ROUND SHIPPED THE FULL xy9n BREAK THROUGH THIS HOLE. *** The
; first draft asked `CB->getCalledFunction()`, which is a
; `dyn_cast_or_null<Function>(getCalledOperand())` and therefore NULL for a call
; through a `GlobalAlias`. And `EmitInverse` mints every `_unc` twin with
; `Module::getOrInsertFunction(Name, FT)`, which returns
; `FunctionCallee{FT, getNamedValue(Name)}` — whatever `GlobalValue` bears the name,
; not necessarily a `Function`. So an input module that defines
; `@cq_template_add_i32_hl_unc` as an alias makes the ADJOINT invisible to the
; guard: it counted 1 slot instead of 2 and accepted, `opt` exit 0, emitting
;
;   %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 poison)
;   call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 poison)
;
; whose linked -O0 trace read `add_i32_hl(h0, 73896)` against
; `ALIASED_UNC(h1, h0, 1401299752)` — the change's own motivating numbers, shipped
; by the change itself.
;
; The alias is `internal` on purpose: with external linkage it also lowers, but
; stage 3 then reports a duplicate symbol against libcq_templates.a, which would
; mask the point.
;
; DO NOT "simplify" the predicate with `stripPointerCasts()`: that RESOLVES the
; alias to `@real_unc_body`, whose name carries no family prefix, and the hole
; reopens. The operand's OWN name is the test, and it covers `Function`,
; `GlobalAlias` and `GlobalIFunc` uniformly.
;
; RED-GREEN: this module's alias-free twin
; (lowering_reject_undef_literal_paired_dead_chain.ll) declines on this plugin, and
; THIS one accepted on it until the predicate was fixed — so the fixture
; discriminates the predicate, not the poison.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: undef/poison literal reaches two emitted gate operands

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)

; The adjoint symbol the pass is about to mint, pre-defined as an ALIAS.
@cq_template_add_i32_hl_unc = internal alias void (i32, i32, i32), ptr @real_unc_body
define internal void @real_unc_body(i32 %o, i32 %a, i32 %b) {
  ret void
}

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %d = add i32 %q, poison
  ret void
}
