; railwindow_reject_init_memcpy_after_q.ll — DECLINE (bd 01po.19 S4, addendum
; note 2): a whole-object copy FROM a constant global AFTER the quantization
; point. Before Q such a copy (clang's `T q[N] = {5, 6, 7}`) is classical memory
; and accepted (railwindow_accept_initializers.ll, @chars); after Q it would be
; a rebind of every cell from the global's bytes, which is not split yet — so it
; is refused loudly rather than guessed (follow-up filed under bd 01po.19).
; Hand IR.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq rail window: quantum-array initializer is not a per-cell classical value

@k = private unnamed_addr constant [3 x i8] c"\01\00\01", align 1

declare signext i8 @cq_theta_si8(i8 signext, double)
declare signext i8 @cq_measure_si8(i8 signext)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

define i32 @main() {
entry:
  %q = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr %q, i8 0, i64 3, i1 false)
  br label %walk

walk:
  %i = phi i64 [ 0, %entry ], [ %in, %walk ]
  %g = getelementptr inbounds [3 x i8], ptr %q, i64 0, i64 %i
  %l = load i8, ptr %g, align 1
  %r = call signext i8 @cq_theta_si8(i8 signext %l, double 5.000000e-01)
  store i8 %r, ptr %g, align 1
  %in = add nuw nsw i64 %i, 1
  %d = icmp eq i64 %in, 3
  br i1 %d, label %after, label %walk

after:
  call void @llvm.memcpy.p0.p0.i64(ptr %q, ptr @k, i64 3, i1 false)
  %l0 = load i8, ptr %q, align 1
  %m = call signext i8 @cq_measure_si8(i8 signext %l0)
  %e = sext i8 %m to i32
  ret i32 %e
}

declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
