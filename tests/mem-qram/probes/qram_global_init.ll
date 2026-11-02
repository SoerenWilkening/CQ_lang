; A global QRAM with a non-zero initializer (rule 20, 160; cq-pf4n 2026-11-02): the module constructor
; allocates the bus with qram_alloc_host_i32(@tab, 4), seeded from the global's own storage (the compiler
; never reads the initializer), and keeps the handle in @tab.qram; @tab keeps its definition. The entry
; loads the handle; its store is never popped and the bus never freed.
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
; CHECK __cq_qram_init_tab: %{{a}} = call i32 @cqrt_qram_alloc_host_i32(ptr @tab, i64 4)
; CHECK __cq_qram_init_tab: store i32 %{{a}}, ptr @tab.qram, align 4
; CHECK-COUNT __cq_qram_init_tab: cqrt_qram_store 0
; CHECK-COUNT __cq_qram_init_tab: cqrt_alloc 0
; CHECK qram_global: %{{a}} = load i32, ptr @tab.qram, align 4
; CHECK qram_global: call void @cqrt_qram_store_i32(i32 %{{a}}, i32 %{{i}}, i32 %{{x}})
; CHECK qram_global: call i32 @cqrt_qram_load_i32_hl(i32 %{{a}}, i32 0)
; CHECK-COUNT qram_global: cqrt_qram_store_i32_unc 0
; CHECK-COUNT qram_global: cqrt_qram_free 0
