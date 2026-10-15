; railwindow_reject_init_order.ll — DECLINE (bd 01po.19 S4, addendum notes 1-2).
;
; Every cell ACCESS of this array lies on one arm, so the quantization point is
; the arm's tainted store; the whole-object memset at the join is REACHABLE from
; it without being DOMINATED by it. Before Q it would be classical memory, after
; Q a rebind of every cell — on this CFG it is both, depending on the path, and
; neither reading is exact for the other path. Refused loudly
; (`railWindowSplitInits`), never guessed. Hand IR.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function f i32 (i1): cq rail window: initializer reachable from the quantization point is not dominated by it

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @f(i1 %c) {
entry:
  %q = alloca [2 x i8], align 1
  br i1 %c, label %A, label %J

A:
  %g = getelementptr inbounds [2 x i8], ptr %q, i64 0, i64 1
  %l = load i8, ptr %g, align 1, !range !0
  %t = trunc i8 %l to i1
  %r = call zeroext i1 @cq_theta_i1(i1 zeroext %t, double 5.000000e-01)
  %z = zext i1 %r to i8
  store i8 %z, ptr %g, align 1
  %l2 = load i8, ptr %g, align 1, !range !0
  %t2 = trunc i8 %l2 to i1
  %m = call zeroext i1 @cq_measure_i1(i1 zeroext %t2)
  br label %J

J:
  call void @llvm.memset.p0.i64(ptr %q, i8 0, i64 2, i1 false)
  ret i32 0
}

!0 = !{i8 0, i8 2}
