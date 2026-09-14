; ModuleID = 'src/L1a_singleblock_selfassign.ll'
source_filename = "src/L1a_singleblock_selfassign.ll"

define i32 @example(i32 %u1) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u1)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  br label %loop

loop:                                             ; preds = %loop, %entry
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %loop
  %m1 = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m1
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cqrt_measure_i32(i32)
