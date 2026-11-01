; A run-time-length memset into a QRAM: its per-cell stores would need a loop popped by a reverse loop:
; not built.
; EXPECT-ERROR: mem-qram: a run-time-length memory intrinsic into a QRAM
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @rtm(i32 %x0, double %t, i32 %v, i64 %n) {
  %a = alloca [4 x i32], align 16
  %n4 = and i64 %n, 12
  call void @llvm.memset.p0.i64(ptr align 16 %a, i8 0, i64 %n4, i1 false)
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 3
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds [4 x i32], ptr %a, i64 0, i64 %iz
  store i32 %v, ptr %p, align 4
  %r = load i32, ptr %a, align 4
  %m = call i32 @cq_measure_ui32(i32 %r)
  ret i32 %m
}
