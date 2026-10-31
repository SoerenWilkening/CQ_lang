define i32 @f(ptr %p, i32 %x) {
  %c = load i32, ptr %p, align 4
  %h = call i32 @cqrt_alloc_i32(i32 0)
  %fl = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_xorc_i32_controlled(i32 %fl, i32 %h, i32 %c)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}
define i32 @g(ptr %p) {
  %hh = load i32, ptr %p, align 4
  %fl = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_xorc_i32_controlled(i32 %fl, i32 %hh, i32 5)
  ret i32 0
}
define i32 @k(ptr %p) {
  %w = load i32, ptr %p, align 4
  call void @cqrt_push(i32 %w)
  %h = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_xorc_i32(i32 %h, i32 %w)
  ret i32 0
}
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_xorc_i32_controlled(i32, i32, i32)
declare void @cqrt_xorc_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_measure_i32(i32)
