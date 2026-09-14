; FIX-round probe a2 — DOES THE GENUINE PAIRING HAZARD STILL FIRE AFTER z9t1?
;
; `lowering_reject_undef_literal_paired_rz_angle.ll` VERBATIM, with ONE token
; changed: the FIRST theta's seed `%x` becomes `undef`, so the z9t1 rule FIRES on
; this module and deletes the alloc's undef slot. The question is whether the
; REMAINING pair -- the poison ANGLE of `%p`, which `EmitInverse` re-emits as
; `cqrt_ry_si32(h, fneg poison)` = the same poison, giving TWO slots that are
; COPIES OF ONE OPERAND -- still trips GUARD 1.
;
; That is the distinction the owner's ruling turns on. If this still declines,
; then z9t1 silences ONLY the case where the two slots are two INDEPENDENT source
; operands (a seed and an angle, the same `Constant` merely because `undef` is
; uniqued per type), and leaves every genuine forward/adjoint pairing intact.
target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)

define void @slice() {
entry:
  %q = call i32 @cq_theta_si32(i32 undef, double 2.500000e-01)
  %d = add i32 %q, 7
  %p = call i32 @cq_theta_si32(i32 %d, double poison)   ; classical angle, undefined
  ret void
}
