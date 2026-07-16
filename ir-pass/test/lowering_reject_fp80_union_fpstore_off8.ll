; lowering_reject_fp80_union_fpstore_off8.ll — bd 3c6m.51 Inc 3 DECLINE
; (structural accept-broadening boundary): a full-width x86_fp80 store at a
; NON-ZERO byte offset is not the bit-pattern idiom (the canonical form models
; exactly one 80-bit value at offset 0; a shifted fp80 write would alias the
; padding and the value bytes at once). The candidate is left byte-untouched;
; the tainted seed then falls to the loud kMsgStore taint-escape decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @off8_reseed() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca [2 x { x86_fp80 }], align 16
  store x86_fp80 %q, ptr %u, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  store x86_fp80 %q, ptr %p8, align 8       ; fp80 store at offset 8 — off-pattern
  %lo = load i64, ptr %u, align 16
  %r = and i64 %lo, 4294967295
  %e = load x86_fp80, ptr %u, align 16
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %e)
  ret x86_fp80 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
; CHECK-NOT: cq_template_bitcast_f80_to_i80
