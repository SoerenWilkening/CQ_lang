; lowering_qram_reject_stale_index_nested_inner.ll — DECLINE (bd
; test_C_libtooling-r2j3.2): the INNER read of a nested `tbl2[tbl[q]]` takes a
; bare i64 index whose register was rotated in place before it. clang -O1 of
;
;     long q = cq_theta(0L, .5);  long q2 = cq_theta(q, .3);
;     return cq_measure(tbl2[tbl[q]]) + (int)cq_measure(q2);
;
; MEASURED on the pre-fix binary: exit 0, the inner `cqrt_qram_load_i32(a1,
; trunc(h2))` after both `ry(h2, ·)`, feeding the outer load.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16
@tbl2 = internal unnamed_addr constant [8 x i32] [i32 7, i32 7, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6], align 16

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sl(i64)

define i32 @main() {
entry:
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01)
  %p1 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %q
  %w = load i32, ptr %p1, align 4
  %wx = sext i32 %w to i64
  %p2 = getelementptr inbounds [8 x i32], ptr @tbl2, i64 0, i64 %wx
  %v = load i32, ptr %p2, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i64 @cq_measure_sl(i64 %q2)
  %nt = trunc i64 %n to i32
  %s = add nsw i32 %m, %nt
  ret i32 %s
}
