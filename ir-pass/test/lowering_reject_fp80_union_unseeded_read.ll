; lowering_reject_fp80_union_unseeded_read.ll — bd 3c6m.51 Inc 3 DECLINE (the
; seed-domination gate): a word load NOT dominated by any fp80 seed store reads
; partially-undefined union content (mem2reg would have to thread undef/poison
; into the promoted SSA). The integer-seeded reload packs (lroundl-style
; SET_LDBL_WORDS) are the real-world instance of this shape and stay a DISTINCT,
; unshipped idiom. The candidate is left byte-untouched; the tainted seed store
; then falls to the existing loud kMsgStore taint-escape decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i64 @cq_measure_sll(i64)

define i64 @unseeded() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca { x86_fp80 }, align 16
  %early = load i64, ptr %u, align 16     ; reads the union BEFORE any seed store
  store x86_fp80 %q, ptr %u, align 16
  %lo = load i64, ptr %u, align 16
  %r = and i64 %lo, 4294967295
  %r2 = add i64 %r, %early
  %m = call i64 @cq_measure_sll(i64 %r2)
  ret i64 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
; CHECK-NOT: cq_template_bitcast_f80_to_i80
