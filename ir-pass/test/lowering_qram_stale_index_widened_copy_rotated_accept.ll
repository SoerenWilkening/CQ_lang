; lowering_qram_stale_index_widened_copy_rotated_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.2, the exactness boundary of the QRAM stale question):
; the index is a widening `sext` and the in-place `cq_theta` rotates THAT widened
; copy, not its source. clang -O1 of the natural nested read
;
;     long w = tbl[q];               // i32 cell, widened to long: sext
;     long w2 = cq_theta(w, .3);     // rotates the sext's own rail
;     int v = tbl2[w];               // `w` names the PRE-Ry record
;
; `resolveQramIndex` strips the `sext`, so the outer QRAM call reads the inner
; load's register, which no gate touched: `v` is exactly tbl2[w_pre]. Correct
; today, and it must stay accepted — a sweep that also seeded the `sext` would
; decline it (an over-decline, CLAUDE.md R1/L5). Decline twin (a native i64 cell,
; no cast, the rotated rail IS the index): lowering_qram_reject_stale_index_nested_outer.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: error
; CHECK: [[IN:%[^ ]+]] = call i32 @cqrt_qram_load_i32(
; CHECK: [[WX:%[^ ]+]] = call i32 @cq_template_sext_i32_to_i64(i32 [[IN]])
; CHECK: call void @cqrt_ry_i64(i32 [[WX]],
; CHECK: call i32 @cqrt_qram_load_i32(i32 %{{[^,]+}}, i32 [[IN]])

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 7, i32 2, i32 6], align 16
@tbl2 = internal unnamed_addr constant [8 x i32] [i32 7, i32 7, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6], align 16

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sl(i64)

define i32 @main() {
entry:
  %q = call i64 @cq_theta_sl(i64 0, double 5.000000e-01)
  %p1 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %q
  %in = load i32, ptr %p1, align 4
  %w = sext i32 %in to i64
  %w2 = call i64 @cq_theta_sl(i64 %w, double 3.000000e-01)
  %p2 = getelementptr inbounds [8 x i32], ptr @tbl2, i64 0, i64 %w
  %v = load i32, ptr %p2, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i64 @cq_measure_sl(i64 %w2)
  %nt = trunc i64 %n to i32
  %s = add nsw i32 %m, %nt
  ret i32 %s
}
