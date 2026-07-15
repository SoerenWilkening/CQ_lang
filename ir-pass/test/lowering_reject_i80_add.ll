; lowering_reject_i80_add.ll — bd 3c6m.51 DECLINE (the i80 binary fence): i80 is an
; INTERMEDIATE x86_fp80 bit-pattern EXTRACTION width shipping ONLY `and` (mask) and
; `lshr` (word offset shift) — the two ops the union idiom and SROA's within-value
; promotion emit. Every other binary op at i80 (add/sub/mul/or/xor/shl/ashr/div/rem)
; has NO generated template; without the rewriteBinary fence a tainted `add i80`
; would `getOrInsertFunction` a phantom `cq_template_add_i80` extern (verify-clean,
; exit 0, LINK-FAILS at Stage 3) — the n0ui i128 phantom-mint lesson at a narrower
; surface. Decline LOUDLY, mint nothing (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i64 @cq_measure_sll(i64)

define i64 @add_i80() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %bc = bitcast x86_fp80 %q to i80
  %s = add i80 %bc, 7                            ; OUT OF SCOPE: only and/lshr at i80
  %t = trunc i80 %s to i64
  %m = call i64 @cq_measure_sll(i64 %t)
  ret i64 %m
}

; CHECK: error{{.*}}no template for opcode 'add i80' in tainted context
; CHECK-NOT: cq_template_add_i80
