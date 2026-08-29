; lowering_uncompute_interior_leak_route_consumer.ll — LEAK PROBE (M-B Increment
; 5a, bd test_C_libtooling-6uqc). INVARIANT 6: FAN-OUT is a DAG shape only when
; EVERY consumer is one the partition can account for.
;
; `%h_op` has two users: a forward compare template, and a `cqrt_x` — a
; permutation gate `isInPlaceGateOn` deliberately does NOT recognize (see
; `ChainWalk::railOf`'s note: teaching it that row would need its own
; `preservesBasisUnderRecord` argument, which nobody has made). It is therefore
; neither an in-place gate the DAG would adjoint nor a forward producer, so the
; rail is refused and left allocated.
;
; The DISCRIMINATION half is the assertion that matters: `%h_cmp`, which sits on
; top of the refused rail, IS still discharged — reading `%h_op` at a point where
; the `cqrt_x` has provably already run (clause (d)'s left disjunct). One
; unaccounted consumer removes ONE rail from the owned set, not the whole chain.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cqrt_x(i32)

define i32 @leak_route_consumer(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  call void @cqrt_x(i32 %a)
  %c = icmp slt i32 %a, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}

; CHECK-LABEL: define i32 @leak_route_consumer(
; CHECK: %[[A:.*]] = call i32 @cq_template_mul_i32_hl
; CHECK-NEXT: call void @cqrt_x(i32 %[[A]])
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[A]], i32 10)
; CHECK-NEXT: call i32 @cq_template_zext_i1_to_i32(i32 %[[C]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[C]], i32 %[[A]], i32 10)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call i32 @cqrt_measure_i32
; CHECK-NOT: cq_template_mul_i32_hl_unc
; CHECK-NOT: call void @cqrt_free(i32 %[[A]])
