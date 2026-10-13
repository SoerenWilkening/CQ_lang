; spec_intermediate_unc_leak_escape.ll — ACCEPT, KEPT (bd test_C_libtooling-p3kd.13):
; a clone result that is MEASURED, RETURNED or handed to `cq_invert_*` is never
; uncomputed and never freed (R5), even though another op consumes it too. The
; R5 twins of spec_intermediate_unc_user_helper.ll's @consumer.
;
;   @measured — `r = inner(q); s = r * 5; cq_measure(s) + cq_measure(r)`: `r` is the
;     program's own observed record. Freeing it would be a hidden reset of a
;     measured register; the interior predicate refuses a measured rail (a
;     `cqrt_measure_*` user is not an interior consumer).
;   @returned — `... return r;` (hand IR): a `ret` user is an escape — the caller
;     owns the rail.
;   @inverted — `cq_invert_begin(r)` (hand IR, the shape of
;     lowering_uncompute_escape_invert.ll): Phase 7 owns a handle in an inversion
;     region.
; In all three the consumer `s` is measured and `r` stays exactly as main
; db4cf60a left it: no twin call, no free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOTWIN < %t.ll

; SILENT-NOT: {{.}}

; CHECK-LABEL: define i32 @measured(
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call fastcc i32 @__cq_q_inner_1(
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R]], i32 5)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

; CHECK-LABEL: define i32 @returned(
; CHECK:      %[[R2:[a-zA-Z0-9_.]+]] = call fastcc i32 @__cq_q_inner_1(
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R2]], i32 5)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S2]])
; CHECK-NEXT: ret i32 %[[R2]]

; CHECK-LABEL: define i32 @inverted(
; CHECK:      %[[R3:[a-zA-Z0-9_.]+]] = call fastcc i32 @__cq_q_inner_1(
; CHECK-NEXT: %[[S3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R3]], i32 5)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S3]])
; CHECK-NEXT: call void @cq_invert_begin(i32 %[[R3]])

; Nothing in the module adjoints or frees a clone result.
; NOTWIN-NOT: __cq_q_inner_1_unc
; NOTWIN-NOT: call void @cqrt_free(i32 %r)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_invert_begin(i32)

define internal fastcc i32 @inner(i32 %x) #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}

define i32 @measured(i32 %u) {
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call fastcc i32 @inner(i32 %q)
  %s = mul nsw i32 %r, 5
  %m = call i32 @cq_measure_si32(i32 %s)
  %m2 = call i32 @cq_measure_si32(i32 %r)
  %t = add nsw i32 %m2, %m
  ret i32 %t
}

define i32 @returned(i32 %u) {
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call fastcc i32 @inner(i32 %q)
  %s = mul nsw i32 %r, 5
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %r
}

define i32 @inverted(i32 %u) {
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call fastcc i32 @inner(i32 %q)
  %s = mul nsw i32 %r, 5
  %m = call i32 @cq_measure_si32(i32 %s)
  call void @cq_invert_begin(i32 %r)
  ret i32 %m
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
