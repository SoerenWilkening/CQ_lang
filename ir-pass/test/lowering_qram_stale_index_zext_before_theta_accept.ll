; lowering_qram_stale_index_zext_before_theta_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.2): an `unsigned` index widened by `zext` and read
; BEFORE the in-place `cq_theta` on its source — the accept boundary of
; lowering_qram_reject_stale_index_zext_hoisted.ll. The stale sweep asks about
; the register `qramIndexRegister` strips the `zext` to, at the load, and the
; later Ry is provably after it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: error
; CHECK: call void @cqrt_ry_i32(i32 [[H:%[^,]+]], double 5.000000e-01)
; CHECK: call i32 @cqrt_qram_load_i32(i32 %{{[^,]+}}, i32 [[H]])
; CHECK: call void @cqrt_ry_i32(i32 [[H]], double 3.000000e-01)

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cq_measure_ui32(i32)

define i32 @main() {
entry:
  %q = call i32 @cq_theta_ui32(i32 0, double 5.000000e-01)
  %w = zext i32 %q to i64
  %p = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %w
  %v = load i32, ptr %p, align 4
  %q2 = call i32 @cq_theta_ui32(i32 %q, double 3.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %v)
  %n = call i32 @cq_measure_ui32(i32 %q2)
  %s = add i32 %n, %m
  ret i32 %s
}
