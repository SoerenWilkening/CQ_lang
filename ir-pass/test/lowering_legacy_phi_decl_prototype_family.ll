; lowering_legacy_phi_decl_prototype_family.ll — ACCEPT, and it records a
; DECISION rather than a capability: a DECLARE-ONLY retired `@cq_phi_<sfx>` with
; no use is DELIBERATELY not a decline (bd test_C_libtooling-3qlq Inc 1 part A,
; Rule-13 round-1 finding F-L6-1, reproducer C).
;
; `resolveSources`' own header states the reserved-name rule for the other 33
; front-end names: they are validated "even for a decl with NO call sites — the
; 42 names are RESERVED by convention … and gating on 'has calls' would make the
; diagnostic depend on DCE happenstance". The F-L6-1 clause beside it does the
; opposite and gates on `!use_empty()`. This file exists so that asymmetry is a
; recorded choice with a reason, not an oversight for a later reader to "fix".
;
; THE REASON, and both halves are measured:
;   * A declare-only retired symbol is provably INERT. With quantum elsewhere in
;     the module the dead declaration is swept by `eraseDeadDecls`; with none,
;     the pass is byte-identical passthrough. There is no path from it to a
;     wrong unitary, so the Prime Directive has nothing to protect.
;   * A decl-only decline would redden roughly 490 fixtures that still carry the
;     retired family MID-MIGRATION, for zero correctness gain. The set that CAN
;     reach a wrong unitary is exactly the set with a USE, and that set declines.
;
; It also records what was LOST relative to the pre-3qlq oracle and is not being
; restored here: the oracle PROTOTYPE-VALIDATED this family, so
; `declare i32 @cq_phi_si32(i32, float)` (a wrong angle type) declined
; `cq rotation lowering: unsupported declared prototype for cq_phi_si32` even
; with no call site. At HEAD it does not, because the family is no longer
; resolved at all. That is an over-ACCEPT of a declaration, not of a program —
; the moment such a declaration is CALLED, the F-L6-1 clause declines it before
; any operand is read.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=SWEPT < %t.cqd0.ll

; The module lowers normally.
; CHECK: call i32 @cqrt_alloc_i32(
; CHECK: call void @cqrt_ry_i32(

; WHOLE-FILE PURE-NEGATIVE: the unused retired declaration is SWEPT, so it does
; not reach stage 3 as an unresolved extern either.
; SWEPT-NOT: @cq_phi_
; SWEPT-NOT: cqrt_rz


; ── Rule-13 ROUND-2 finding F-R2-1, the assertion repair ────────────────────
; Round 1 repaired three assertion families (the 8-width Rz negative, the
; `cqrt_x` negative, the `cqrt_free` count) in the corpus IT could see, and the
; merge brought in a set that had never been asked the same question. Measured by
; injection at `c4bd888`: `cqrt_rz_f80`/`f16` NOT CAUGHT in 18 accepts, an
; UNPAIRED `cqrt_x` (a wrong-branch phase) NOT CAUGHT in 21, an EXTRA
; `cqrt_free` (a hidden measurement, Rule 6) NOT CAUGHT in 20. Every accept in
; the branch now carries all three, and each is validated by injecting the line
; into this fixture's OWN output.
; SWEPT-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; A SURVIVING register-free `cq_phi` CALL is the P7 postcondition this file
; is about, and it was the ONE injection this fixture MISSED (round 2): the
; blanket `cq_phi_` negative below catches the RETIRED family and not the
; void one, whose DECLARATION this module legitimately keeps.
; SWEPT-NOT: call void @cq_phi(
; SWEPT-NOT: call void @cqrt_x(i32
; SWEPT-NOT: call void @cqrt_free(
; SWEPT-NOT: call void @cqrt_cswap(


target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_phi_f64(double, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
