; lowering_reject_fp80_union_padding.ll — bd 3c6m.51 DECLINE (the CENTRAL §4.1
; fence): the promoteFp80Union peephole models the x86_fp80 padding bytes [10,16)
; (bits [80,128)) as 0. That is sound ONLY where the body masks the padding off.
; Here the offset-8 exponent word (meaningful bits [64,80) → 16 bits) is masked
; with `and 131071` (0x1FFFF, 17 bits) which KEEPS bit 16 = storage bit 80 = the
; first PADDING bit. Modelling that undefined byte as 0 would give a definite
; answer the real program never commits to — a verify-clean silent miscompile. The
; peephole LOUD-declines instead of promoting (it does NOT fall to the generic
; kMsgStore: the shape IS the target idiom, so a silent skip would read as
; "covered" while a future looser matcher could promote it unsoundly).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i64 @cq_measure_sll(i64)

define i64 @padding() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca { x86_fp80 }, align 16
  store x86_fp80 %q, ptr %u, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %hi = load i64, ptr %p8, align 8              ; offset 8: meaningful bits [64,80)
  %bad = and i64 %hi, 131071                    ; 0x1FFFF KEEPS bit 16 = a padding bit
  %m = call i64 @cq_measure_sll(i64 %bad)
  ret i64 %m
}

; CHECK: error{{.*}}cq fp80 union: padding byte observed without a mask
; CHECK-NOT: cq_template_bitcast_f80_to_i80
