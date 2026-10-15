; lowering_accept_undef_literal_single_slot.ll — ACCEPT (bd xy9n).
; ARM: `declineUnpairedUndefLiterals`'s THRESHOLD. This is the fixture that pins
; the guard's predicate at TWO slots and not ONE.
;
; *** IT EXISTS TO PROTECT A SHIPPED GOLDEN. *** The first draft of the bd xy9n
; guard refused ANY emitted gate operand carrying a literal undef/poison, and
; measurement over 966 fixtures + 257 e2e stage-1 modules + 251 openlibm modules
; found exactly ONE real-code occurrence — `slice_libm_ld80_nexttoward`, whose
; lowered module holds 985 emitted calls and this one slot:
;
;   %selop = call i32 @cqrt_alloc_f64(double undef)
;   call void @cqrt_xorc_f64_controlled(i32 %h_cmp85, i32 %out86, double undef)
;
; That `undef` is `clang -O1`'s OWN output — it emits
; `select i1 %c, double undef, double %v` for the dead early-exit merge edge of
; nexttoward's `x == y` test. The module below is that shape reduced to seven
; lines, and it lowers IDENTICALLY (one `cqrt_alloc_<W>` seeded from `undef`, fed
; to one controlled copy).
;
; WHY ONE SLOT IS SOUND, stated so nobody "fixes" it later. The defect bd xy9n is
; about is a PAIRING break: `poison` lowers to `IMPLICIT_DEF`, which LLVM
; materialises PER USE, so a forward gate and its adjoint reading the same literal
; read two different values and the adjoint stops being the inverse. With exactly
; ONE slot there is no second read to disagree with — the circuit computes SOME
; definite value where the source specified an unspecified one, which is a legal
; refinement. Confirmed structurally on the real slice: `double undef` appears
; exactly ONCE in the whole lowered module, and `%selop` is NEVER freed, so there
; is no Rule-6 hidden measurement either (a rail not provably |0> is left
; allocated, never freed dirty).
;
; This is the same discrimination bd bu96 rests on: a poison-generating
; `ConstantExpr` is uniqued into ONE link-time relocation, so its forward and
; adjoint agree and there is no wrong circuit. Reason from PAIRING, never from
; LangRef refinement — refinement ("poison permits any value") is true of BOTH
; kinds and is therefore not what makes the two-slot case wrong.
;
; THIS IS A CONTROL: it is GREEN ON BOTH the pre-change and post-change plugins,
; by design, so it contributes nothing to the differential. Its discriminating
; power comes from ARM-KILL — raise the guard's threshold from two slots to one
; and this fixture goes red, which is exactly the regression that would have
; broken `tests/e2e/slice_libm_ld80_nexttoward` and its committed golden. Do not
; conclude from its absence in the differential that it pins nothing (bd memory
; [[predmux-decline-fixture-discrimination]] trap 1).
;
; bd dm7f.81 MOVED THE SUBJECT. The select arm above is no longer a slot at all:
; a classical merge arm is a literal operand of `cqrt_xorc_<W>_controlled`, and an
; `undef`/`poison` arm is REFINED to the all-zero pattern and emits NO gate
; (MergeArmWrite.cpp `armWriteIsNoop`; as a literal, the merge-discharge replay
; would clone it into a SECOND slot read as a second value). So @example now pins
; that refinement, and the guard's ONE-slot threshold is carried by @addc_one: an
; M-C in-place `cqrt_addc_i32(h, undef)` whose result is measured, never reversed
; — exactly one literal undef slot in its function.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK-LABEL: define double @example(
; CHECK: %h = call i32 @cqrt_alloc_f64(double %u0)
; CHECK: %h_cmp = call i32 @cq_template_fcmp_uno_f64(i32 %h, i32 %h)
; CHECK-NEXT: %out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_x(i32 %h_cmp)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %h, i32 %out)
; CHECK-NEXT: call void @cqrt_x(i32 %h_cmp)
; The flag is stripped and freed:
; CHECK: call void @cq_template_fcmp_uno_f64_unc(i32 %h_cmp, i32 %h, i32 %h)
; CHECK: call void @cqrt_free(i32 %h_cmp)
; CHECK-LABEL: define i32 @addc_one(
; CHECK: call void @cqrt_addc_i32(i32 %{{[a-z0-9_.]+}}, i32 undef)
;
; Exactly ONE literal undef slot in the whole module (the threshold's subject):
; RUN: grep -c "undef)" %t.cqd0.ll | grep -qx 1

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp uno double %q, %q                 ; the hand-written isnan test
  %a = select i1 %c, double undef, double %q  ; clang's own dead-edge spelling
  %m = call double @cq_measure_f64(double %a)
  ret double %m
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @addc_one(i32 %x) {
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  %d = add i32 %q, undef
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
