; ModuleID = '/tmp/p3kd78-review-r1/p5_untainted_constloop.ll'
source_filename = "/tmp/p3kd78-review-r1/p5_untainted_constloop.ll"
target triple = "x86_64-unknown-linux-gnu"

define internal i32 @classloop(i32 noundef %q, i32 noundef %a) {
entry:
  br label %loop

loop:                                             ; preds = %entry
  %vn = mul i32 %a, 3
  %vn.1 = mul i32 %vn, 3
  %vn.2 = mul i32 %vn.1, 3
  %vn.3 = mul i32 %vn.2, 3
  %r = add i32 %q, %vn.3
  ret i32 %r
}

define i32 @probe(i32 %x, i32 %a) {
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @__cq_q_classloop_01(i32 %h, i32 %a)
  %m1 = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m1
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_classloop_01(i32 noundef %q, i32 noundef %a) #0 {
entry:
  %vn = mul i32 %a, 3
  %vn.1 = mul i32 %vn, 3
  %vn.2 = mul i32 %vn.1, 3
  %vn.3 = mul i32 %vn.2, 3
  %h_op = call i32 @cq_template_add_i32_hl(i32 %q, i32 %vn.3)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %q, i32 %vn.3)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { memory(readwrite) }
