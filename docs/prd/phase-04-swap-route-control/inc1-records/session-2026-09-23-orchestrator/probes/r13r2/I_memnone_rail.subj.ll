; ModuleID = 'I_memnone_rail.ll'
source_filename = "I_memnone_rail.ll"

define i32 @probe(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  br label %merge

merge:                                            ; preds = %entry
  %m1 = call i32 @cqrt_measure_i32(i32 %h)
  %s2 = add i32 0, %m1
  ret i32 %s2
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cqrt_measure_i32(i32)
