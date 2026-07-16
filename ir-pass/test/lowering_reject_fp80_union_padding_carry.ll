; lowering_reject_fp80_union_padding_carry.ll — bd 3c6m.51 Inc 3 DECLINE (§4.1,
; flow form): the straddle word's diverged bits [16,64) ride an `add` carry into
; an icmp OBSERVABLE without ever being masked. Modelling the padding as 0 would
; give the compare a definite answer the real program never commits to — a
; verify-clean silent miscompile. The widened per-bit padding-taint walk follows
; load → add → icmp and LOUD-declines at the observation.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i64 @cq_measure_sll(i64)

define i64 @carry() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca { x86_fp80 }, align 16
  store x86_fp80 %q, ptr %u, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %hi = load i64, ptr %p8, align 8       ; straddle: diverged bits [16,64)
  %s = add i64 %hi, 1                    ; diverged bits kept (carry)
  %c = icmp eq i64 %s, 0                 ; OBSERVES diverged bits — unsound
  %z = zext i1 %c to i64
  %m = call i64 @cq_measure_sll(i64 %z)
  ret i64 %m
}

; CHECK: error{{.*}}cq fp80 union: padding byte observed without a mask
; CHECK-NOT: cq_template_bitcast_f80_to_i80
