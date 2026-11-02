; Rule 22: a memset of 6 bytes over i32 cells covers a cell only partly. The seed form routes it to rule 22's
; per-cell write path (M6), whose byte-masked merge of a partly covered slot cell is not built yet.
; EXPECT-ERROR: mem-qram: a memory intrinsic into a slot array over a part of a cell
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
