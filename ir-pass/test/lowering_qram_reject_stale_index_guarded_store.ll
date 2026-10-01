; lowering_qram_reject_stale_index_guarded_store.ll — DECLINE (bd
; test_C_libtooling-r2j3.2): a GUARDED Shadow store (the iw81.7 GuardedStoreArm,
; lowered to `cqrt_qram_store_<W>_controlled`) whose bare i64 index register was
; rotated in place before the region. clang -O1 of
;
;     long q = cq_theta(0L, .5);  long j = cq_theta(0L, .9) & 7;
;     int c = cq_theta(0, .7);    long q2 = cq_theta(q, .3);
;     if (c > 2) arr[q] = 5;                      // `q`: PRE-Ry record
;
; MEASURED on the pre-fix binary: exit 0,
; `cqrt_qram_store_i32_controlled(h4, a0, trunc(h1), h5)` after both `ry(h1, ·)`.
; The store sits in the arm; it is asked at its own position, before any flatten.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

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
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)
  %cmp = icmp sgt i32 %c, 2
  br i1 %cmp, label %arm, label %merge

arm:
  %ps = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %q
  store i32 5, ptr %ps, align 4
  br label %merge

merge:
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
