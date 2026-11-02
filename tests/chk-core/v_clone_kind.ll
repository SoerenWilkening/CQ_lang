; cq-06bi: cqrt_clone_resolve with a kind outside 0..2 is a malformed call
target triple = "x86_64-apple-macosx16.0.0"
define i32 @f(i32 %x) {
  ret i32 %x
}
define i32 @v(i32 %x0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %x0)
  %p = call ptr @cqrt_clone_resolve(ptr @f, i32 3)
  %m = call i32 @cqrt_measure_i32(i32 %x)
  ret i32 %m
}
declare ptr @cqrt_clone_resolve(ptr, i32)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_measure_i32(i32)
