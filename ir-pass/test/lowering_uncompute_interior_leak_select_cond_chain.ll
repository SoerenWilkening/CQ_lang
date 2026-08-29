; lowering_uncompute_interior_leak_select_cond_chain.ll — LEAK PROBE (M-B
; Increment 5a, bd test_C_libtooling-6uqc; session-review amendment (5)).
; SELECT/SWITCH-DISCHARGED CONDITION CHAINS STAY OUT UNTIL INCREMENT 6.
;
; The 4.4 tainted `select` mints a flag from `%h_cmp`, does its two controlled-XOR
; copies, then STRIPS the flag with `cq_template_icmp_slt_i32_hl_unc(%h_cmp,
; %h_op, 10)` and frees it. That strip is the emitter's own teardown — and it
; READS `%h_op`, the mul rail underneath the compare.
;
; So `%h_op` is refused, and the reason is structural rather than a special case:
; one of its users is an `_unc` twin, which `ChainWalk::isInteriorConsumer` does
; not admit (`isTemplateProducer` excludes every `_inv`/`_unc`). That refusal is
; exactly right — discharging `%h_op` at the anchor its FORWARD consumers imply
; would put `cq_template_mul_i32_hl_unc(%h_op, %h, 3); cqrt_free(%h_op)` BEFORE
; the emitter's strip, i.e. a use-after-free of the register the strip recomputes
; from.
;
; AND IT IS THE SEAM INCREMENT 6 HAS TO WORK ON, stated here so the next agent
; does not rediscover it: the fix is not to relax this predicate but to give the
; interior partition a REGION ANCHOR (clause (d2)) — the point right after the
; emitter's strip-and-free, recorded by the emitter — and place the condition
; chain's discharge there. Until that exists, this whole chain is a Rule-6 safe
; leak, and the identical leak on the `br`-diamond surface is bd 6uqc's P0.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leak_select_cond(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %c = icmp slt i32 %a, 10
  %s = select i1 %c, i32 7, i32 9
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

; CHECK-LABEL: define i32 @leak_select_cond(
; CHECK:      %[[A:.*]] = call i32 @cq_template_mul_i32_hl(i32 %{{.*}}, i32 3)
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[A]], i32 10)
; the 4.4 merge, then the emitter's own strip of the flag — which READS %[[A]]
; CHECK:      call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[C]], i32 %[[A]], i32 10)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call i32 @cqrt_measure_i32
; the mul rail under the condition is LEFT ALLOCATED (Increment 6's customer)
; CHECK-NOT: cq_template_mul_i32_hl_unc
