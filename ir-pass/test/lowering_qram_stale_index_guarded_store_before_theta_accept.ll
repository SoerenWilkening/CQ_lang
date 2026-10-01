; lowering_qram_stale_index_guarded_store_before_theta_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.2, review round 1 F1, the reviewer's p2): the accept twin
; of lowering_qram_reject_stale_index_guarded_store.ll. Same guarded Shadow store in
; a TAINTED-condition arm, but the in-place `cq_theta` on the index register runs in
; the merge, AFTER the region. The GuardedStoreArm emitter flattens the diamond and
; emits `cqrt_qram_store_<W>_controlled` inside the region's span, so the store reads
; the index before the Ry on every trace. The gate post-dominates the store and
; cannot reach it (`gateFollowsRead`); the first r2j3.2 binary declined this because
; the store does not dominate the gate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: error
; CHECK: call void @cqrt_ry_i64(i32 [[H:%[^,]+]], double 5.000000e-01)
; CHECK: call void @cqrt_qram_store_i32_controlled(
; CHECK: call void @cqrt_ry_i64(i32 [[H]], double 3.000000e-01)

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sl(i64)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @main() {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr %arr, i8 0, i64 32, i1 false)
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  %j0 = call i64 @cq_theta_sl(i64 0, double 9.000000e-01)
  %c = call i32 @cq_theta_si32(i32 0, double 0x3FE6666666666666)
  %cmp = icmp sgt i32 %c, 2
  br i1 %cmp, label %arm, label %merge

arm:
  %ps = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %q
  store i32 5, ptr %ps, align 4
  br label %merge

merge:
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)
  %j = and i64 %j0, 7
  %pl = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %j
  %v = load i32, ptr %pl, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i64 @cq_measure_sl(i64 %q2)
  %nt = trunc i64 %n to i32
  %s = add nsw i32 %m, %nt
  %mc = call i32 @cq_measure_si32(i32 %c)
  %s2 = add nsw i32 %s, %mc
  ret i32 %s2
}
