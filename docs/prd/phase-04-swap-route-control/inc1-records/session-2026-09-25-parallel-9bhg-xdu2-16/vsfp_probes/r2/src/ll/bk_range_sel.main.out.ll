; ModuleID = 'bk_range_sel.ll'
source_filename = "bk_range_sel.ll"

define i32 @h(i32 range(i32 1, 100) %a, i32 %k) {
  %r = add i32 %k, 1
  ret i32 %r
}

define i32 @main(i32 %m) {
  %lo = trunc i32 %m to i1
  %h = call i32 @cqrt_alloc_i1(i1 %lo)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 9)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %bf)
  %selop1 = call i32 @cqrt_alloc_i32(i32 4)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %t = call i32 @__cq_q_h_01(i32 %out, i32 %m)
  call void @cqrt_ry_i1(i32 %h, double 0x3FE6666666666666)
  %m2 = call i1 @cqrt_measure_i1(i32 %h)
  %mz = zext i1 %m2 to i32
  %s = add i32 %t, %mz
  ret i32 %s
}

declare void @cqrt_copy_i32(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_h_01(i32 range(i32 1, 100) %a, i32 %k) #0 {
  %r = add i32 %k, 1
  ret i32 %r
}

declare void @cqrt_ry_i1(i32, double)

declare i1 @cqrt_measure_i1(i32)

attributes #0 = { memory(readwrite) }
