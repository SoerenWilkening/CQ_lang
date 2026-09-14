; ModuleID = 'src/L1c_irreducible_invariant.ll'
source_filename = "src/L1c_irreducible_invariant.ll"

define i32 @example(i32 %u1, i1 %c) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u1)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  br i1 %c, label %A, label %B

A:                                                ; preds = %B, %entry
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  br label %B

B:                                                ; preds = %A, %entry
  %t = phi i32 [ 0, %entry ], [ %m, %A ]
  %d = icmp sgt i32 %t, 3
  br i1 %d, label %exit, label %A

exit:                                             ; preds = %B
  ret i32 %t
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cqrt_measure_i32(i32)
