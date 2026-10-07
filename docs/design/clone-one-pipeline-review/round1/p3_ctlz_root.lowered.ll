; ModuleID = '/tmp/p3kd78-review-r1/p3_ctlz_root.ll'
source_filename = "/tmp/p3kd78-review-r1/p3_ctlz_root.ll"
target triple = "x86_64-unknown-linux-gnu"

define internal i32 @countshift(i32 noundef %x) {
entry:
  br label %loop

loop:                                             ; preds = %loop, %entry
  %v = phi i32 [ %x, %entry ], [ %vn, %loop ]
  %c = phi i32 [ 57, %entry ], [ %cn, %loop ]
  %cn = add i32 %c, -1
  %vn = shl i32 %v, 1
  %again = icmp sgt i32 %vn, 0
  br i1 %again, label %loop, label %exit

exit:                                             ; preds = %loop
  ret i32 %cn
}

define i32 @probe(i32 %x) {
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @__cq_q_countshift_1(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m1
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_countshift_1(i32 noundef %x) #0 {
entry:
  %h_op = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)
  %h_intr = call i32 @cq_template_ctlz_i32(i32 %h_op)
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_intr, i32 31)
  %h_op2 = call i32 @cq_template_sub_i32_lh(i32 56, i32 %h_op1)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op2, i32 %cqq.out)
  call void @cq_template_sub_i32_lh_unc(i32 %h_op2, i32 56, i32 %h_op1)
  call void @cq_template_and_i32_hl_unc(i32 %h_op1, i32 %h_intr, i32 31)
  call void @cq_template_ctlz_i32_unc(i32 %h_intr, i32 %h_op)
  call void @cq_template_shl_i32_hl_unc(i32 %h_op, i32 %x, i32 1)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_intr)
  call void @cqrt_free(i32 %h_op1)
  call void @cqrt_free(i32 %h_op2)
  ret i32 %cqq.out
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctlz.i32(i32, i1 immarg) #1

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare i32 @cq_template_ctlz_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_sub_i32_lh(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_sub_i32_lh_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_ctlz_i32_unc(i32, i32)

declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { memory(readwrite) }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
