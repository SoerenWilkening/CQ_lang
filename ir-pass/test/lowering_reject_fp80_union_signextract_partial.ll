; lowering_reject_fp80_union_signextract_partial.ll — DECLINE (bd 3c6m.55
; Inc 1, Lever A.1c — the discriminating UNSOUND sign-extract probe): a
; sign-extract whose `shl` does NOT clear the padding divergence. Here the
; offset-8 expsign load (divergence [16,64) — the storage bits >= 80) is
; shifted by only 40: bits [56,64) of the shifted value still carry padding
; divergence, so the following `ashr exact` operates on a DIVERGED operand —
; the model's padding-as-0 could flip the `exact` poison condition relative to
; real padding content, and the §4.1 walk's poison-flag guard LOUD-declines at
; the ashr. The seed is tainted (STRICT class), so the failure surfaces as the
; central kMsgFp80Padding diagnostic — never a silent promotion of an
; observation the real program does not commit to. Mirrors the sound positive
; lowering_fp80_union_signextract.ll (shl 48 → divergence fully cleared).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i32 @cq_measure_si32(i32)

define i32 @signextract_partial(x86_fp80 %x0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %x0, double 5.000000e-01)
  %u = alloca %union.IEEEl2bits, align 16
  store x86_fp80 %q, ptr %u, align 16
  %g = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %g, align 8
  %hi = shl i64 %w, 40
  %se = ashr exact i64 %hi, 40
  %t = trunc i64 %se to i32
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}

; CHECK: error{{.*}}cq fp80 union: padding byte observed without a mask
; CHECK-NOT: cq_template_bitcast_f80_to_i80
