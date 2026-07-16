; lowering_reject_fp80_union_padding_insert.ll — bd 3c6m.51 Inc 3 DECLINE (§4.1,
; landing form): a field-insert stores the straddle word's diverged bits [16,64)
; at byte offset 0 — they land at storage bits [16,64), INSIDE the 80-bit value
; (not in the dropped >= 80 padding range) — and the fp80 reload then observes a
; value whose mantissa depends on the undefined padding. The per-bit walk tracks
; the landing positions through union content and LOUD-declines at the reload.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @land() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca { x86_fp80 }, align 16
  store x86_fp80 %q, ptr %u, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %hi = load i64, ptr %p8, align 8       ; straddle: diverged bits [16,64)
  store i64 %hi, ptr %u, align 16        ; insert @0: diverged bits land BELOW 80
  %e = load x86_fp80, ptr %u, align 16   ; reload OBSERVES the diverged mantissa
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %e)
  ret x86_fp80 %m
}

; CHECK: error{{.*}}cq fp80 union: padding byte observed without a mask
; CHECK-NOT: cq_template_bitcast_f80_to_i80
