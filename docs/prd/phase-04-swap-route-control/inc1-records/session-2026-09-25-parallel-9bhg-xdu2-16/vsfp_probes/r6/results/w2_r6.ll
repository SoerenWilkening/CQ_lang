; ModuleID = 'r6/w2probe.ll'
source_filename = "r6/w2probe.ll"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @atoi(ptr nocapture noundef)

define i32 @g(i32 noundef "cq.probe.opaque" %a, i32 noundef %k) {
  %c = icmp sgt i32 %a, 3
  br i1 %c, label %t, label %m

t:                                                ; preds = %0
  br label %m

m:                                                ; preds = %t, %0
  %r = add nsw i32 %k, 1
  ret i32 %r
}

define i32 @h(i32 noundef %a, i32 noundef %k) {
  %p = mul nsw i32 %a, 3
  %t = call i32 @g(i32 noundef %p, i32 noundef %k)
  %u = add nsw i32 %p, %t
  ret i32 %u
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %h = call i32 @cqrt_alloc_i32(i32 %6)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = tail call i32 @__cq_q_h_01(i32 noundef %h, i32 noundef %5)
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m = call i32 @cqrt_measure_i32(i32 %r)
  %m3 = call i32 @cqrt_measure_i32(i32 %h)
  %s = add nsw i32 %m, %m3
  ret i32 %s
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_h_01(i32 noundef %a, i32 noundef %k) #0 {
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %a, i32 3)
  %t = call i32 @__cq_q_g_01(i32 noundef %h_op, i32 noundef %k)
  %h_op1 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 %t)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op1, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op1, i32 %h_op, i32 %t)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %a, i32 3)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  ret i32 %cqq.out
}

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_g_01(i32 noundef "cq.probe.opaque" %a, i32 noundef %k) #0 {
m:
  %r = add nsw i32 %k, 1
  ret i32 %r
}

declare void @cqrt_free(i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { memory(readwrite) }
