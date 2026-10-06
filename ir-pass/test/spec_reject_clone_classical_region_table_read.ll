; spec_reject_clone_classical_region_table_read.ll — DECLINE, a goal-1 GAP (bd
; p3kd.7.2 review round 1, F3): a classical bounds check guarding a read of a constant
; table at a CLASSICAL index, `(unsigned)k < 8 ? x*(x + tbl[k]) + 1 : x*(3x - 7)`,
; with `x` quantum and `k` classical. Clone-mode PredMux if-converts the classical
; branch (owner ruling 2026-10-06), which would run the load on every path, including
; k >= 8 where it reads out of bounds; the load is not a quantum-index QROM read and
; `classicalTableReadIsSpeculatable` does not admit it, so the region leaves at
; `E4-gep` and the clone's size backstop declines loudly. Lowering it needs a total
; speculation (an index clamped into the table, the chosen arm unchanged) or a
; per-path wrap; it is not physics (bd p3kd.7.3).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function __cq_q_q1_01 i32 (i32, i32): cq specialization: callee contains tainted control flow under quantum lift
@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @q1(i32 noundef %0, i32 noundef %1) {
  %3 = icmp ult i32 %1, 8
  br i1 %3, label %4, label %11

4:
  %5 = zext nneg i32 %1 to i64
  %6 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %5
  %7 = load i32, ptr %6, align 4
  %8 = add i32 %7, %0
  %9 = mul i32 %8, %0
  %10 = add nsw i32 %9, 1
  br label %15

11:
  %12 = mul i32 %0, 3
  %13 = add i32 %12, -7
  %14 = mul i32 %13, %0
  br label %15

15:
  %16 = phi i32 [ %10, %4 ], [ %14, %11 ]
  ret i32 %16
}

define i32 @example(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @q1(i32 %q, i32 %k)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
