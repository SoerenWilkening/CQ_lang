; lowering_uncompute_interior_leak_unreachable_consumer.ll — LEAK PROBE (M-B
; Increment 5, bd test_C_libtooling-6uqc). REACHABILITY IS PART OF THE POSITIONAL
; PROOF, and forgetting it is a VACUOUS-TRUTH hole, not an omission.
;
; `%h_op` has two users: the compare in `entry`, and a `mul` in `%dead`, a block
; with NO PREDECESSORS. The interior partition's whole positional argument is
; `provablyBefore(consumer, At)` = `DT.dominates(consumer, At) &&
; !isPotentiallyReachable(At, consumer)` — and BOTH halves are VACUOUSLY TRUE for
; an instruction in an unreachable block (LLVM's dominator tree treats such a
; block as dominated by everything, and nothing is reachable from it). Worse, the
; anchor set is built from `consumer->getNextNode()`, so an unreachable consumer
; can drag the nearest common POST-dominator into a block that never executes:
; the reversal would then be emitted where it can never run, silently dropping
; every adjoint and every `cqrt_free` the group was supposed to emit while `opt`
; exits 0 and the IR verifies.
;
; This is the SAME trap the M-A guard's Rule-13 round found (its F3 finding,
; pinned by lowering_reject_live_record_unreachable_use.ll) reached from the
; other side, so it is fenced the same way: any owned rail with an unreachable
; consumer leaks the whole group.
;
; NOTE THE ASYMMETRY, because the two uses of reachability in this driver point
; in OPPOSITE directions and reading them as one rule is how the second one gets
; deleted. In the anchor scan, vacuous truth hides a missing proof and must be
; refused. In the BORROWED-PARENT clause-(d) scan it is the safe direction — a
; mutation that can never execute cannot move the parent — and is skipped
; explicitly rather than left to fall out of the dominance query.
;
; DISCRIMINATION: `%h_cmp`, whose only consumer is the reachable `zext`, is still
; discharged. The refusal is per rail.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leak_unreachable_consumer(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %c = icmp slt i32 %a, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m

dead:                                             ; no predecessors
  %d = mul i32 %a, 5
  ret i32 %d
}

; CHECK-LABEL: define i32 @leak_unreachable_consumer(
; CHECK:      %[[A:.*]] = call i32 @cq_template_mul_i32_hl(i32 %{{.*}}, i32 3)
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[A]], i32 10)
; CHECK-NEXT: call i32 @cq_template_zext_i1_to_i32(i32 %[[C]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[C]], i32 %[[A]], i32 10)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call i32 @cqrt_measure_i32
; the rail with the unreachable consumer is LEFT ALLOCATED
; CHECK-NOT: cq_template_mul_i32_hl_unc
; CHECK-NOT: call void @cqrt_free(i32 %[[A]])
