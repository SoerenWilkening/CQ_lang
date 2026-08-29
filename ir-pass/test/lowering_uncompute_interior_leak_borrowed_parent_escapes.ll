; lowering_uncompute_interior_leak_borrowed_parent_escapes.ll — LEAK PROBE (M-B
; Increment 5a, bd test_C_libtooling-6uqc). A DELIBERATE OVER-DECLINE, recorded as
; one: a BORROWED parent with a NON-CALL user leaks the whole interior group.
;
; Here the source wire `%h` is RETURNED. A `ReturnInst` does not mutate a register
; — the clause-(d) obligation is untouched by it — so this group could in
; principle still be discharged. The scan refuses anyway, because the set of
; non-call users that can keep a handle live is open-ended and each one means
; something different: a `ret` escapes it to a caller that may reverse it, a φ or
; `select` ROUTES the SAME physical rail onward (bd tayx — a mutation can hide
; behind either), a `store` puts it in memory. Reasoning about "which of these is
; harmless" is exactly the kind of case analysis this project's history says turns
; into an over-accept, and the cost of refusing is a leak.
;
; RECORDED, NOT HIDDEN: this is C-reachable (`return q;` beside a derived
; compare), it costs real coverage, and narrowing it — most obviously by admitting
; `ReturnInst` outright — is a scope decision for a later increment with its own
; probe family, not a bug fix.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leak_borrowed_escapes(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %c = icmp slt i32 %a, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %q
}

; CHECK-LABEL: define i32 @leak_borrowed_escapes(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK:      call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call i32 @cq_template_icmp_slt_i32_hl
; CHECK-NEXT: call i32 @cq_template_zext_i1_to_i32
; CHECK-NEXT: call i32 @cqrt_measure_i32
; CHECK-NEXT: ret i32 %[[H]]
; CHECK-NOT: _unc
; CHECK-NOT: call void @cqrt_free
