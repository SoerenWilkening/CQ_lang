; cq-06bi: handle 0 is reserved (CR §1.1, CQ_spec f684858): a gate handed it is a bad_handle
target triple = "x86_64-apple-macosx16.0.0"
define i32 @v(i32 %x0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %x0)
  call void @cqrt_free(i32 0)
  %m = call i32 @cqrt_measure_i32(i32 %x)
  ret i32 %m
}
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
