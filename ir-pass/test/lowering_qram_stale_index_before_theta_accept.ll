; lowering_qram_stale_index_before_theta_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.2, the position-aware boundary): a bare i64 index read
; BEFORE the in-place `cq_theta` on its register. The QRAM call runs before the
; Ry, so it reads exactly the record `q` names; a later gate is harmless. A
; position-free stale rule would decline this valid program (an over-decline,
; CLAUDE.md R1/L5). Also pins that a read-only access with no later gate at all
; (the second table) still lowers.
;
;     long q = cq_theta(0L, .5);
;     int v = tbl[q];               // read first
;     long q2 = cq_theta(q, .3);    // then rotate
;     int u = tbl2[q2];             // read the rotated NAME (fresh record)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: error
; CHECK: call void @cqrt_ry_i64(i32 [[H:%[^,]+]], double 5.000000e-01)
; CHECK: call i32 @cqrt_qram_load_i32(
; CHECK: call void @cqrt_ry_i64(i32 [[H]], double 3.000000e-01)
; CHECK: call i32 @cqrt_qram_load_i32(

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16
@tbl2 = internal unnamed_addr constant [8 x i32] [i32 7, i32 7, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6], align 16

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  %p = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %q
  %v = load i32, ptr %p, align 4
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)
  %p2 = getelementptr inbounds [8 x i32], ptr @tbl2, i64 0, i64 %q2
  %u = load i32, ptr %p2, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i32 @cq_measure_si32(i32 %u)
  %s = add nsw i32 %m, %n
  ret i32 %s
}
