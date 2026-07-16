; lowering_reject_fp80_union_nested_aggregate.ll — bd szpr DECLINE PIN (the
; Inc-3 critic's aggregate/nested-union note): a union NESTED inside a larger
; aggregate (`struct { union IEEEl2bits u; int tag; }` — 24 data bytes in a
; 32-byte slot) must not promote as if it were the bare 16-byte bit-pattern
; union. The structural pass admits the offset-0 fp80 seed, but the sibling
; `tag` field lives at offset 16 — inside the region the promotion models as
; dropped padding — so the §4.1 per-bit padding-taint walk declines the
; unmasked tag OBSERVATION loudly. (A stored-but-never-read tag would be
; elided as a dead padding insert — semantically exact for a dead field.)
; Pinned so a future analyzeStructure widening cannot silently claim
; multi-field aggregates: the tag read must keep declining until an explicit
; aggregate model exists.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @nested() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %s = alloca { [2 x i64], i32 }, align 16
  store x86_fp80 %q, ptr %s, align 16
  %pw = getelementptr inbounds i8, ptr %s, i64 8
  %w = load i16, ptr %pw, align 8
  %pt = getelementptr inbounds i8, ptr %s, i64 16
  store i32 7, ptr %pt, align 16              ; the sibling struct field...
  %t = load i32, ptr %pt, align 16            ; ...READ back — padding observed
  %z = zext i16 %w to i32
  %a = add i32 %z, %t
  %f = sitofp i32 %a to x86_fp80
  %e = load x86_fp80, ptr %s, align 16
  %g = fadd x86_fp80 %e, %f
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %g)
  ret x86_fp80 %m
}

; CHECK: error{{.*}}cq fp80 union: padding byte observed without a mask
; CHECK-NOT: cq_template_bitcast_f80_to_i80
