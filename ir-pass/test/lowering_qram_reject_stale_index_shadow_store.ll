; lowering_qram_reject_stale_index_shadow_store.ll — DECLINE (bd
; test_C_libtooling-r2j3.2): a Shadow (local-array) STORE whose bare i64 index
; register was rotated in place before the store. clang -O1 of
;
;     long q = 0L; cq_theta(&q, .5);  long s = 0L; cq_theta(&s, .9); long j = s & 7;
;     long q2 = q; cq_theta(&q2, .3);
;     arr[q] = 5;                       // `q` names the PRE-Ry record
;     return cq_measure(arr[j]) + (int)cq_measure(q2);
;
; MEASURED on the pre-fix binary: exit 0, `cqrt_qram_store_i32(a0, trunc(h1), …)`
; after both `ry(h1, ·)`, i.e. the store writes through the rotated register.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sl(i64)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @main() {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr %arr, i8 0, i64 32, i1 false)
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  %j0 = call i64 @cq_theta_sl(i64 0, double 9.000000e-01)
  %j = and i64 %j0, 7
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)
  %ps = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %q
  store i32 5, ptr %ps, align 4
  %pl = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %j
  %v = load i32, ptr %pl, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i64 @cq_measure_sl(i64 %q2)
  %nt = trunc i64 %n to i32
  %s = add nsw i32 %m, %nt
  ret i32 %s
}
