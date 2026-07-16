; lowering_reject_fp80_union_aggregate_array.ll — bd szpr DECLINE PIN (the
; Inc-3 critic's aggregate/nested-union note): an ARRAY of unions
; (`union IEEEl2bits u[2]` — two fp80 seeds, at offsets 0 AND 16) is not the
; bit-pattern idiom (the canonical form models exactly one 80-bit value at
; offset 0; the second element's seed is a full-width fp80 store at a non-zero
; offset, the same off-pattern class lowering_reject_fp80_union_fpstore_off8
; pins at offset 8). The candidate is left byte-untouched; the tainted seed
; then falls to the loud kMsgStore taint-escape decline. Pinned so a future
; structural widening cannot silently stride the promotion across array
; elements without an explicit multi-element model.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @uarray() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca [2 x [2 x i64]], align 16
  store x86_fp80 %q, ptr %u, align 16
  %p16 = getelementptr inbounds i8, ptr %u, i64 16
  store x86_fp80 %q, ptr %p16, align 16       ; element [1] seed at offset 16 — off-pattern
  %pw = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i16, ptr %pw, align 8
  %pw2 = getelementptr inbounds i8, ptr %u, i64 24
  %w2 = load i16, ptr %pw2, align 8
  %z = zext i16 %w to i32
  %z2 = zext i16 %w2 to i32
  %a = add i32 %z, %z2
  %f = sitofp i32 %a to x86_fp80
  %e = load x86_fp80, ptr %u, align 16
  %g = fadd x86_fp80 %e, %f
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %g)
  ret x86_fp80 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
; CHECK-NOT: cq_template_bitcast_f80_to_i80
