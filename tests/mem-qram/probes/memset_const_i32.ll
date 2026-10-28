; Rule 22, constant length over i32 cells: memset(a, 1, 16) is four cells, each its own seed of the byte
; splat 0x01010101 = 16843009, one ordinary update per cell (116's unrolled shape). Read back at a
; run-time cell: registers, nothing freed. Five handle stores: the four cells and the store of the rotated rail.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @memset_const_i32(i32 %i, double %t) {
  %a = alloca [4 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %a, i8 1, i64 16, i1 false)
  %ii = sext i32 %i to i64
  %p = getelementptr inbounds [4 x i32], ptr %a, i64 0, i64 %ii
  %v = load i32, ptr %p, align 4
  %x = call i32 @cq_theta_si32(i32 %v, double %t)
  store i32 %x, ptr %p, align 4
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
; CHECK-COUNT memset_const_i32: call i32 @cqrt_alloc_i32(i32 16843009) 4
; CHECK-COUNT memset_const_i32: store i32 %{{s}}, ptr 5
; CHECK-COUNT memset_const_i32: call void @cqrt_free( 0
