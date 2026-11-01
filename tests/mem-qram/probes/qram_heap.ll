; A heap QRAM block (rule 20): malloc(16) of i32 cells is cqrt_qram_alloc_i32(4); the allocator call is
; not emitted (no host block); free emits nothing (the bus's release is Uncompute's).
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)
declare noalias ptr @malloc(i64) allockind("alloc,uninitialized") allocsize(0)
declare void @free(ptr) allockind("free")

define i32 @qram_heap(i32 %x0, double %t, i32 %v) {
  %a = call ptr @malloc(i64 16)
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %i = and i32 %x, 3
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds i32, ptr %a, i64 %iz
  store i32 %v, ptr %p, align 4
  %r = load i32, ptr %a, align 4
  %m = call i32 @cq_measure_ui32(i32 %r)
  call void @free(ptr %a)
  ret i32 %m
}
; CHECK qram_heap: call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK qram_heap: call void @cqrt_qram_store_i32(i32 %{{a}}, i32 %{{i}}, i32 %{{v}})
; CHECK qram_heap: call i32 @cqrt_qram_load_i32_hl(i32 %{{a}}, i32 0)
; CHECK-COUNT qram_heap: @malloc( 0
; CHECK-COUNT qram_heap: @free( 0
; CHECK-COUNT qram_heap: call void @cqrt_qram_free( 1
