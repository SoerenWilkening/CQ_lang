; lowering_qram_reject_stale_index_nested_outer.ll — DECLINE (bd
; test_C_libtooling-r2j3.2): the OUTER read of a nested access takes the inner
; read's i64 result as a bare index, and that result's register is rotated in
; place before the outer read:
;
;     long w = tbl64[q];  long w2 = w; cq_theta(&w2, .3);  v = tbl2[w];  // `w`: PRE-Ry
;
; The inner load result is a fresh copy-out rail, and the chained `cq_theta` is an
; in-place Ry on it; the outer `cqrt_qram_load` is minted at its own load, after.
; Accept twin (the widened copy is what was rotated, the strip reads the
; unrotated source): lowering_qram_stale_index_widened_copy_rotated_accept.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

@tbl64 = internal unnamed_addr constant [8 x i64] [i64 3, i64 1, i64 4, i64 1, i64 5, i64 7, i64 2, i64 6], align 16
@tbl2 = internal unnamed_addr constant [8 x i32] [i32 7, i32 7, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6], align 16

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sl(i64)

define i32 @main() {
entry:
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  %p1 = getelementptr inbounds [8 x i64], ptr @tbl64, i64 0, i64 %q
  %w = load i64, ptr %p1, align 8
  %w2 = call i64 @cq_theta_sl(i64 %w, double 3.000000e-01)
  %p2 = getelementptr inbounds [8 x i32], ptr @tbl2, i64 0, i64 %w
  %v = load i32, ptr %p2, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i64 @cq_measure_sl(i64 %w2)
  %nt = trunc i64 %n to i32
  %s = add nsw i32 %m, %nt
  ret i32 %s
}
