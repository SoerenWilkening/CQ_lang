; A global QRAM with a non-zero initializer (rule 20, 160): the module constructor allocates the bus,
; stores each non-zero element by an _hl store of a seed freed at once, and keeps the handle in the
; global. The entry loads the handle; its store is never popped and the bus never freed.
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)

@tab = internal global [4 x i32] [i32 0, i32 5, i32 0, i32 7], align 16

define i32 @qram_global(i32 %x0, double %t) {
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 3
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds [4 x i32], ptr @tab, i64 0, i64 %iz
  store i32 %x, ptr %p, align 4
  %r = load i32, ptr @tab, align 16
  %m = call i32 @cq_measure_ui32(i32 %r)
  ret i32 %m
}
; CHECK __cq_qram_init_tab: %{{a}} = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK __cq_qram_init_tab: %{{h}} = call i32 @cqrt_alloc_i32(i32 5)
; CHECK __cq_qram_init_tab: call void @cqrt_qram_store_i32_hl(i32 %{{a}}, i32 1, i32 %{{h}})
; CHECK __cq_qram_init_tab: call void @cqrt_qram_store_i32_hl(i32 %{{a}}, i32 3, i32 %{{h}})
; CHECK-COUNT __cq_qram_init_tab: call void @cqrt_free( 2
; CHECK __cq_qram_init_tab: store i32 %{{a}}, ptr @tab, align 4
; CHECK qram_global: %{{a}} = load i32, ptr @tab, align 4
; CHECK qram_global: call void @cqrt_qram_store_i32(i32 %{{a}}, i32 %{{i}}, i32 %{{x}})
; CHECK qram_global: call i32 @cqrt_qram_load_i32_hl(i32 %{{a}}, i32 0)
; CHECK-COUNT qram_global: cqrt_qram_store_i32_unc 0
; CHECK-COUNT qram_global: cqrt_qram_free 0
