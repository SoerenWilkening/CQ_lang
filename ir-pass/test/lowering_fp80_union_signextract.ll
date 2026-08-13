; lowering_fp80_union_signextract.ll — ACCEPT (bd 3c6m.55 Inc 1, Lever A.1c):
; the GET_LDBL80 SIGN-EXTRACT read. openlibm floorl/expl reads the 16-bit
; expsign word as a SIGNED value: `load i64 @8; shl 48; ashr exact 48;
; trunc nsw -> i32`. This is walk-sound WITHOUT any special case: the offset-8
; load straddles the padding (divergence mask [16,64) — storage bits >= 80),
; but the `shl 48` shifts every diverged bit to >= 64 where the 64-bit value
; DROPS them — the `ashr exact` operand carries ZERO divergence, so the §4.1
; walk's zero-divergence short-circuit passes it before the exact-flag guard
; is ever consulted. The seed is TAINTED (theta-derived — the STRICT class),
; the union promotes, and the sign-extract lowers as ordinary tainted i64
; shifts. The discriminating UNSOUND variant (a shl that does NOT clear the
; divergence) is lowering_reject_fp80_union_signextract_partial.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i32 @cq_measure_si32(i32)

define i32 @signextract(x86_fp80 %x0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %x0, double 5.000000e-01)
  %u = alloca %union.IEEEl2bits, align 16
  store x86_fp80 %q, ptr %u, align 16
  %g = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %g, align 8
  %hi = shl i64 %w, 48
  %se = ashr exact i64 %hi, 48
  %t = trunc nsw i64 %se to i32
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}

; the union promotes (no alloca survives) and the sign-extract lowers as
; tainted shift/trunc templates on the extracted expsign word:
; CHECK:     define i32 @signextract(
; CHECK-NOT: alloca
; CHECK:     call i32 @cq_template_bitcast_f80_to_i80(
; CHECK:     call i32 @cq_template_shl_i64_hl(i32 %{{[a-z0-9_]+}}, i64 48)
; CHECK:     call i32 @cq_template_ashr_i64_hl(i32 %{{[a-z0-9_]+}}, i64 48)
; CHECK:     call i32 @cq_template_trunc_i64_to_i32(
; CHECK:     call i32 @cqrt_measure_i32(
