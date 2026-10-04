; lowering_stale_record_classical_arm_op_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.2, review round 1 F1, the reviewer's p4): the PURE-op twin
; of lowering_qram_stale_index_classical_arm_read_accept.ll. A tainted `add` reads
; `%q` inside a CLASSICAL branch arm; the in-place `cq_theta` on `%q` runs after the
; merge. The template fires before the Ry on every trace that runs it. Declined on
; main and on the first r2j3.2 binary by the position-aware proof's dominance
; precondition (the add does not dominate the gate); the stale sweep now grants a
; gate that post-dominates the read and cannot reach it (`gateFollowsRead`). The
; sibling-arm shape stays declined: lowering_reject_stale_record_exclusive_arms.ll.
;
;     if (argc > 1) r = cq_measure(q + 1);
;     q2 = q; cq_theta(&q2, .3);
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: error
; CHECK: call void @cqrt_ry_i32(i32 [[H:%[^,]+]], double 5.000000e-01)
; CHECK: call i32 @cq_template_add_i32_hl(i32 [[H]], i32 1)
; CHECK: call void @cqrt_ry_i32(i32 [[H]], double 3.000000e-01)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %k = icmp sgt i32 %argc, 1                      ; CLASSICAL condition
  br i1 %k, label %arm, label %merge

arm:
  %d = add i32 %q, 1
  %m = call i32 @cq_measure_si32(i32 %d)
  br label %merge

merge:
  %r = phi i32 [ %m, %arm ], [ 0, %entry ]
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  %n = call i32 @cq_measure_si32(i32 %q2)
  %s = add nsw i32 %n, %r
  ret i32 %s
}
