; lowering_qram_stale_index_classical_arm_read_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.2, review round 1 F1): a QROM read of a bare i64 index
; inside a CLASSICAL branch arm, and the in-place `cq_theta` on the index register
; after the merge. clang -O1 of the reviewer's p1:
;
;     long q = 0L; cq_theta(&q, .5);  long r = 0;
;     if (argc > 1) r = cq_measure(tbl[q]);
;     long q2 = q; cq_theta(&q2, .3);
;
; Every trace that runs the read runs it before the Ry, so the read sees the record
; `q` names. The read does not DOMINATE the gate, which the first r2j3.2 binary
; required and so declined it (main accepted it, trace in the right order). The
; stale sweep now grants a gate that post-dominates the read and cannot reach it
; (`gateFollowsRead`, OpcodeLowering.cpp).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: error
; CHECK: call void @cqrt_ry_i64(i32 [[H:%[^,]+]], double 5.000000e-01)
; CHECK: call i32 @cqrt_qram_load_i64(
; CHECK: call void @cqrt_ry_i64(i32 [[H]], double 3.000000e-01)

@tbl = internal unnamed_addr constant [8 x i64] [i64 3, i64 1, i64 4, i64 1, i64 5, i64 9, i64 2, i64 6], align 16

declare i64 @cq_theta_sl(i64, double)
declare i64 @cq_measure_sl(i64)

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  %k = icmp sgt i32 %argc, 1                      ; CLASSICAL condition
  br i1 %k, label %arm, label %merge

arm:
  %p = getelementptr inbounds [8 x i64], ptr @tbl, i64 0, i64 %q
  %v = load i64, ptr %p, align 8
  %m = call i64 @cq_measure_sl(i64 %v)
  br label %merge

merge:
  %r = phi i64 [ %m, %arm ], [ 0, %entry ]
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)
  %n = call i64 @cq_measure_sl(i64 %q2)
  %s = add nsw i64 %n, %r
  %t = trunc i64 %s to i32
  ret i32 %t
}
