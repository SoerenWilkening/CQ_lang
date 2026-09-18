; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d9542657-7eae-4089-ae6b-77dc3ed77cc3/scratchpad/rev/dead/straightline_deadtheta.ll'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d9542657-7eae-4089-ae6b-77dc3ed77cc3/scratchpad/rev/dead/straightline_deadtheta.ll"

define i32 @probe(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h1, double 5.000000e-01)
  call void @cqrt_ry_i1(i32 %h1, double -5.000000e-01)
  call void @cqrt_free(i32 %h1)
  %m2 = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m2
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cqrt_measure_i32(i32)

declare void @cqrt_free(i32)
