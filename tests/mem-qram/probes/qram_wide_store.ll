; A classical i64 store over two i32 QRAM cells (84): one _hl store per cell of its bytes, little
; endian, each a fresh seed.
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)

define i32 @wide(i32 %x0, double %t, i64 %w) {
  %a = alloca [2 x i32], align 8
  store i64 %w, ptr %a, align 8
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 1
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds [2 x i32], ptr %a, i64 0, i64 %iz
  %r = load i32, ptr %p, align 4
  store i32 %r, ptr %a, align 4
  %m = call i32 @cq_measure_ui32(i32 %r)
  ret i32 %m
}
; CHECK wide: lshr i64 %{{w}}, 32
; CHECK wide: call void @cqrt_qram_store_i32_hl(i32 %{{a}}, i32 0, i32 %{{s}})
; CHECK wide: call void @cqrt_qram_store_i32_hl(i32 %{{a}}, i32 1, i32 %{{s}})
