; ModuleID = 'ir-pass/test/control_predmux_accept_rail_leaf_cond.ll'
source_filename = "ir-pass/test/control_predmux_accept_rail_leaf_cond.ll"

define i32 @probe() {
entry:
  %h = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  call void @cqrt_x(i32 %h)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %bf)
  %selop1 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %bf2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf2)
  %out3 = call i32 @cqrt_alloc_i32(i32 0)
  %selop4 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %selop4, i32 %out3)
  call void @cqrt_x(i32 %bf2)
  %selop5 = call i32 @cqrt_alloc_i32(i32 6)
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %selop5, i32 %out3)
  call void @cqrt_x(i32 %bf2)
  call void @cqrt_cnot(i32 %h, i32 %bf2)
  call void @cqrt_free(i32 %bf2)
  %bf6 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf6)
  %out7 = call i32 @cqrt_alloc_i32(i32 0)
  %selop8 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf6, i32 %selop8, i32 %out7)
  call void @cqrt_x(i32 %bf6)
  %selop9 = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_copy_i32_controlled(i32 %bf6, i32 %selop9, i32 %out7)
  call void @cqrt_x(i32 %bf6)
  call void @cqrt_cnot(i32 %h, i32 %bf6)
  call void @cqrt_free(i32 %bf6)
  %bf10 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf10)
  %out11 = call i32 @cqrt_alloc_i32(i32 0)
  %selop12 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf10, i32 %selop12, i32 %out11)
  call void @cqrt_x(i32 %bf10)
  %selop13 = call i32 @cqrt_alloc_i32(i32 8)
  call void @cqrt_copy_i32_controlled(i32 %bf10, i32 %selop13, i32 %out11)
  call void @cqrt_x(i32 %bf10)
  call void @cqrt_cnot(i32 %h, i32 %bf10)
  call void @cqrt_free(i32 %bf10)
  br label %merge

merge:                                            ; preds = %entry
  %m = call i32 @cqrt_measure_i32(i32 %out)
  %m14 = call i32 @cqrt_measure_i32(i32 %out3)
  %m15 = call i32 @cqrt_measure_i32(i32 %out7)
  %m16 = call i32 @cqrt_measure_i32(i32 %out11)
  %m17 = call i1 @cqrt_measure_i1(i32 %h)
  %z = zext i1 %m17 to i32
  %s1 = add i32 %m, %m14
  %s2 = add i32 %s1, %m15
  %s3 = add i32 %s2, %m16
  %s4 = add i32 %s3, %z
  ret i32 %s4
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i1(i32, double)
  call void @cqrt_x(i32 %h)

declare i32 @cqrt_measure_i32(i32)

declare i1 @cqrt_measure_i1(i32)
