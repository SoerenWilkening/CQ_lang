; ModuleID = 'p2_theta_src_inst_nn.ll'
source_filename = "p2_theta_src_inst_nn.ll"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @atoi(ptr nocapture noundef)

define i32 @main(i32 noundef %argc, ptr noundef %argv) {
e:
  %a1p = getelementptr inbounds ptr, ptr %argv, i64 1
  %a1 = load ptr, ptr %a1p, align 8
  %m = call i32 @atoi(ptr noundef %a1)
  %m7 = and i32 %m, 7
  %h = call i32 @cqrt_alloc_i32(i32 %m7)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @__cq_q_h_01(i32 noundef %h, i32 noundef %m)
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m1 = call i32 @cqrt_measure_i32(i32 %h)
  %s = add nsw i32 %m1, %r
  ret i32 %s
}

define i32 @h(i32 noundef %a, i32 noundef %k) {
e:
  %t = mul nsw i32 %a, 5
  %r = tail call i32 @h2(i32 noundef %t, i32 noundef %k)
  ret i32 %r
}

; Function Attrs: noinline
define i32 @h2(i32 noundef "cq.probe.opaque" %x, i32 noundef %k) #0 {
e:
  %r = add nsw i32 %k, 1
  ret i32 %r
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_h_01(i32 noundef %a, i32 noundef %k) #1 {
e:
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %a, i32 5)
  %r = tail call i32 @__cq_q_h2_01(i32 noundef %h_op, i32 noundef %k)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %a, i32 5)
  call void @cqrt_free(i32 %h_op)
  ret i32 %r
}

; Function Attrs: noinline memory(readwrite)
define internal i32 @__cq_q_h2_01(i32 noundef "cq.probe.opaque" %x, i32 noundef %k) #2 {
e:
  %r = add nsw i32 %k, 1
  ret i32 %r
}

declare void @cqrt_free(i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { noinline }
attributes #1 = { memory(readwrite) }
attributes #2 = { noinline memory(readwrite) }
