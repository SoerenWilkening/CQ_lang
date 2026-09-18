; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/ir-pass/test/control_predmux_accept_rail_leaf_dead_rail_survives.ll'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/ir-pass/test/control_predmux_accept_rail_leaf_dead_rail_survives.ll"

define i32 @probe(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h1, double 5.000000e-01)
  call void @cqrt_ry_i1(i32 %h1, double -5.000000e-01)
  call void @cqrt_free(i32 %h1)
  br label %merge

merge:                                            ; preds = %entry
  %m2 = call i32 @cqrt_measure_i32(i32 %h)
  %s2 = add i32 0, %m2
  call void @cqrt_free(i32 0)
  ret i32 %s2
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cqrt_measure_i32(i32)

declare void @cqrt_free(i32)
