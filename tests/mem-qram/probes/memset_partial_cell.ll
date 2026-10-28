; Rule 22: a memset of 6 bytes over i32 cells covers a cell only partly: a bit view (63), not built.
; EXPECT-ERROR: mem-qram: a memset of a slot object over a length that is not a whole number of cells
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @memset_partial_cell(i32 %i, double %t) {
  %a = alloca [4 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %a, i8 0, i64 6, i1 false)
  %ii = sext i32 %i to i64
  %p = getelementptr inbounds [4 x i32], ptr %a, i64 0, i64 %ii
  %v = load i32, ptr %p, align 4
  %x = call i32 @cq_theta_si32(i32 %v, double %t)
  store i32 %x, ptr %p, align 4
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
