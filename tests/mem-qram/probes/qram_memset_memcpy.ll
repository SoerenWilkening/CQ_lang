; Rule 22 into a QRAM, classical length: memset is one _hl store per cell all reading ONE shared seed
; (30, 55); memcpy from host memory one seed per cell from a classical load (73), from a constant
; global folded (168); memcpy from another QRAM a _hl load of each source cell (all loads first).
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
@k = private unnamed_addr constant [2 x i32] [i32 7, i32 9]

define i32 @msets(i32 %x0, double %t, i32 %v) {
  %a = alloca [4 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %a, i8 1, i64 16, i1 false)
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 3
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds [4 x i32], ptr %a, i64 0, i64 %iz
  store i32 %v, ptr %p, align 4
  %r = load i32, ptr %a, align 4
  %m = call i32 @cq_measure_ui32(i32 %r)
  ret i32 %m
}
; CHECK msets: call i32 @cqrt_alloc_i32(i32 16843009)
; CHECK-COUNT msets: @cqrt_alloc_i32( 3
; CHECK msets: call void @cqrt_qram_store_i32_hl(i32 %{{a}}, i32 3, i32 %{{s}})
; CHECK-COUNT msets: call void @cqrt_qram_store_i32_hl( 4

define i32 @mcpys(i32 %x0, double %t, ptr %src) {
  %a = alloca [2 x i32], align 8
  %b = alloca [2 x i32], align 8
  %c = alloca [2 x i32], align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %a, ptr align 4 %src, i64 8, i1 false)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %c, ptr align 4 @k, i64 8, i1 false)
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 1
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds [2 x i32], ptr %a, i64 0, i64 %iz
  store i32 %x, ptr %p, align 4
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %b, ptr align 8 %a, i64 8, i1 false)
  %q = getelementptr inbounds [2 x i32], ptr %b, i64 0, i64 %iz
  store i32 %x, ptr %q, align 4
  %s = getelementptr inbounds [2 x i32], ptr %c, i64 0, i64 %iz
  store i32 %x, ptr %s, align 4
  %r = load i32, ptr %b, align 4
  %r2 = load i32, ptr %c, align 4
  %r3 = add i32 %r, %r2
  %m = call i32 @cq_measure_ui32(i32 %r3)
  ret i32 %m
}
; CHECK mcpys: load i32, ptr %{{src}}, align 4
; CHECK mcpys: getelementptr inbounds i8, ptr %{{src}}, i64 4
; CHECK mcpys: call i32 @cqrt_alloc_i32(i32 7)
; CHECK mcpys: call i32 @cqrt_alloc_i32(i32 9)
; CHECK-COUNT mcpys: call i32 @cqrt_qram_load_i32_hl( 4
