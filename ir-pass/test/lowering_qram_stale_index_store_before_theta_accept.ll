; lowering_qram_stale_index_store_before_theta_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.2): a Shadow store whose bare i64 index AND stored value
; are both rotated in place only AFTER the store. The store reads both registers
; before the Ry, i.e. exactly the records the SSA names denote, so the later gates
; are harmless and the module must keep lowering (the accept boundary of the two
; decline twins lowering_qram_reject_stale_index_shadow_store.ll and
; lowering_qram_reject_stale_store_value.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: error
; CHECK: call void @cqrt_qram_store_i32(
; CHECK: call void @cqrt_ry_i64(
; CHECK: call void @cqrt_ry_i32(
; CHECK: call i32 @cqrt_qram_load_i32(

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
  %x = call i32 @cq_theta_si32(i32 0, double 6.000000e-01)
  %j0 = call i64 @cq_theta_sl(i64 0, double 9.000000e-01)
  %j = and i64 %j0, 7
  %ps = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %q
  store i32 %x, ptr %ps, align 4
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)
  %x2 = call i32 @cq_theta_si32(i32 %x, double 2.000000e-01)
  %pl = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %j
  %v = load i32, ptr %pl, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i64 @cq_measure_sl(i64 %q2)
  %nt = trunc i64 %n to i32
  %o = call i32 @cq_measure_si32(i32 %x2)
  %s = add nsw i32 %m, %nt
  %s2 = add nsw i32 %s, %o
  ret i32 %s2
}
