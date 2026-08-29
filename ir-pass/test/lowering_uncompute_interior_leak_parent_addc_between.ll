; lowering_uncompute_interior_leak_parent_addc_between.ll — LEAK PROBE (M-B
; Increment 5a, bd test_C_libtooling-6uqc). CLAUSE (d): a BORROWED PARENT MUTATED
; BETWEEN THE FORWARD GATE AND THE DISCHARGE.
;
; This is the invariant the whole increment turns on, and it is the one the
; whole-DAG spine never has to state: that spine adjoints EVERY gate it walked,
; so reverse program order delivers "every register an adjoint reads holds the
; value it held when the forward gate ran" for free. A BORROWED parent is
; deliberately NOT walked and NOT adjointed, so the property must be PROVEN.
;
; Here `cqrt_addc_i32(%h, 5)` relabels the source wire AFTER
; `cq_template_mul_i32_hl(%h, 3)` has read it. Emitting
; `cq_template_mul_i32_hl_unc(%h_op, %h, 3)` at the end would recompute `3*(x+5)`
; and XOR it into a rail holding `3*x`: the rail is NOT zeroed, and the
; `cqrt_free` that follows is a hidden measurement. `opt -verify` is clean either
; way, and stage 2b would report the pair as "verified" because the pairing is
; structurally perfect — only the VALUES differ. That is why the scan is
; positional and not structural.
;
; THE DISPOSITION IS PER-GROUP, NOT PER-RAIL, and that is deliberate over-
; declining: `%h_cmp` never reads `%h` and could in principle still be discharged.
; One unprovable borrowed parent leaks the whole interior group, which is the
; cheap conservative reading; narrowing it is a scope decision, not a bug fix.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cqrt_addc_i32(i32, i32)

define i32 @leak_parent_mutated(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  call void @cqrt_addc_i32(i32 %q, i32 5)
  %c = icmp slt i32 %a, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}

; CHECK-LABEL: define i32 @leak_parent_mutated(
; CHECK: %[[A:.*]] = call i32 @cq_template_mul_i32_hl
; CHECK-NEXT: call void @cqrt_addc_i32
; CHECK-NEXT: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[A]]
; CHECK-NEXT: call i32 @cq_template_zext_i1_to_i32
; CHECK-NEXT: call i32 @cqrt_measure_i32
; CHECK-NOT: _unc
; CHECK-NOT: call void @cqrt_free
