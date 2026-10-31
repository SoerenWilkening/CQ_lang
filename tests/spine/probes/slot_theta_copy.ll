; cq-xu07: s = cq_theta(q[j]) on a slot load rotates a copy of the cell's rail when the cell (or the
; value q[i] stored into the array) is read after it: q[i] = cq_theta(q[i]); s = cq_theta(q[j]);
; measure(q[i]) + 2 * measure(s). With i == j the cell and %10 hold one rail; rotating it in place made
; measure(q[i]) read the twice-rotated value (cqcheck user failed at i == j). The second Ry hits the
; copy (alloc 0 + copy_i32 just before it); the first (load, cq_theta, store back) stays in place.
define i32 @pr(i32 noundef %0, i32 noundef %1, double noundef %2) {
  %4 = alloca [4 x i32], align 16
  %5 = and i32 %0, 3
  %6 = and i32 %1, 3
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  %7 = zext nneg i32 %5 to i64
  %8 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %7
  %9 = load i32, ptr %8, align 4
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef %2)
  store i32 %10, ptr %8, align 4
  %11 = zext nneg i32 %6 to i64
  %12 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef %2)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %10)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %14)
  %17 = shl nsw i32 %16, 1
  %18 = add nsw i32 %17, %15
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  ret i32 %18
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
; CHECK-COUNT pr: call void @cqrt_ry_i32( 2
; CHECK-COUNT pr: call void @cqrt_copy_i32( 1
