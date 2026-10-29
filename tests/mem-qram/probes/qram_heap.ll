; A heap QRAM block. Not built.
; EXPECT-ERROR: mem-qram: a heap QRAM block
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
