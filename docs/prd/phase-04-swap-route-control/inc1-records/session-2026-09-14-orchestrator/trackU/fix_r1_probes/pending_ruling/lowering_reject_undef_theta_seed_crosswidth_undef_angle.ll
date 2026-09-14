; lowering_reject_undef_theta_seed_crosswidth_undef_angle.ll — DECLINE.
; ARM: `normalizeUndefRotationSeed`'s ARG-1 CONJUNCT (bd z9t1, F-U1-1), and this
; is the row that pins WHICH QUESTION THE CONJUNCT ASKS.
;
; *** THIS FILE IS THE ANTI-IDENTITY PIN. *** The natural reading of the finding
; probe r14 is "the SAME `UndefValue` object occupies two slots", and keying the
; conjunct on `Constant` identity is exactly what that reading spells. It
; UNDER-COVERS, at the very boundary the conjunct is about:
;
;     _Bool b; double th; b = cq_theta(b, th);   /* fix probe r21 */
;
; `i1 undef` and `double undef` are TWO DIFFERENT uniqued constants (`undef` is
; uniqued PER TYPE), so an identity test sees no pair — and yet they are still
; TWO emitted gate slots, `cqrt_alloc_i1(i1 undef)` and
; `cqrt_ry_i1(i32 %h, double undef)`, so GUARD 1 declines this module on the
; ORACLE exactly as it declines the f64 twin. Measured 2026-09-14: ORACLE
; (f7b65d8c) exit 1 / 248 B with the string below; SUBJECT-BEFORE-FIX
; (a5773be1) exit 0 / 0 B, emitting `call void @cqrt_ry_i1(i32 %h, double undef)`.
;
; So the conjunct asks GUARD 1's OWN question about the angle slot with GUARD 1's
; OWN predicate (`slotCarriesUndef`, Rule 14 — one spelling, one owner), not a
; proxy. Narrow the conjunct to `Seed == Theta->getArgOperand(1)` and THIS FILE
; GOES RED while its f64 sibling stays green, which is the whole point of having
; both rows: the sibling cannot tell the two predicates apart.
;
; The global-ADDRESS skip in `slotCarriesUndef` is load-bearing in the other
; direction and is deliberate: a slot GUARD 1 would NOT count (the fp80-union
; `ptrtoint (ptr @v to i32)` idiom this project is built on) must not block the
; rewrite either, or the conjunct becomes an over-decline of its own.
;
; RED-GREEN: measured ACCEPT (`opt` exit 0, 0 bytes of stderr) on the pre-fix
; plugin `a5773be142835fb8`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: undef/poison literal reaches two emitted gate operands

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  ; the SEED is `i1 undef`; the ANGLE is `double undef` — a DIFFERENT constant.
  %q = call i1 @cq_theta_i1(i1 undef, double undef)
  %m = call i1 @cq_measure_i1(i1 %q)
  ret i1 %m
}
