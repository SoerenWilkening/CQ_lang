; lowering_stale_record_add_before_theta.ll — ACCEPT: the positive twin of
; lowering_reject_stale_record_add.ll, pinning the stale-record guard's
; DON'T-OVER-DECLINE boundary (test_C_libtooling-uzb).
;
; Same SSA graph as the reject fixture — `%d = add i32 %q, 1` reads `%q`, and
; `%q`'s wire later gains a chained, NON-diagonal `cq_theta` — but here the add
; is SCHEDULED BEFORE the chained theta. The template is emitted AT the add's
; position, and opaque calls keep their order through the backend, so the
; emitted `cq_template_add` fires PRE-Ry, capturing exactly the record the SSA
; value denotes onto the template's own fresh rail; the later Ry on `%q`'s
; wire cannot touch that rail. The emitted stream matches source semantics —
; a legitimate use-then-re-rotate program that must keep lowering. This is why
; the guard is POSITION-AWARE (the op's schedule IS its emission point — NOT
; the MINT_AT_COMPARE.md §4 trap, where the mint's emission point was the
; branch, unrelated to the compare's schedule); a position-free rule would
; over-decline this shape for no soundness gain. The CHECK-NEXT order pins the
; load-bearing property: the template between the two ry calls.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double %g)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double %t2)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %d = add i32 %q, 1                                  ; BEFORE the chained Ry
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained, in-place Ry
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
