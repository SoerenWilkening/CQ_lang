; ModuleID = 'src/L1b_singleblock_invariant.ll'
source_filename = "src/L1b_singleblock_invariant.ll"

define i32 @example(i32 %u1) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u1)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  br label %loop

loop:                                             ; preds = %loop, %entry
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %loop
  ret i32 %m
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cqrt_measure_i32(i32)
