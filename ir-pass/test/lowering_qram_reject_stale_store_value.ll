; lowering_qram_reject_stale_store_value.ll — DECLINE (bd
; test_C_libtooling-r2j3.2, the same consumer's other read): a Shadow store
; copies its VALUE register into the cell AT THE STORE, so a stored value whose
; register was rotated in place before the store is a stale read too:
;
;     int q = 0; cq_theta(&q, .5);  int q2 = q; cq_theta(&q2, .3);
;     arr[i] = q;                         // `q` names the PRE-Ry record
;
; (`-O1` forwards a C spelling of this to its reader, so this is IR-level.)
; MEASURED on the pre-fix binary: exit 0, `cqrt_qram_store_i32(a0, …, h5)` after
; both `ry(h5, ·)`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @main() {
entry:
  %arr = alloca [4 x i32], align 16
  call void @llvm.memset.p0.i64(ptr %arr, i8 0, i64 16, i1 false)
  %i0 = call i64 @cq_theta_sl(i64 0, double 7.000000e-01)
  %i = and i64 %i0, 3
  %j0 = call i64 @cq_theta_sl(i64 0, double 9.000000e-01)
  %j = and i64 %j0, 3
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  %p = getelementptr inbounds [4 x i32], ptr %arr, i64 0, i64 %i
  store i32 %q, ptr %p, align 4
  %pl = getelementptr inbounds [4 x i32], ptr %arr, i64 0, i64 %j
  %v = load i32, ptr %pl, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i32 @cq_measure_si32(i32 %q2)
  %s = add i32 %m, %n
  ret i32 %s
}
