; ModuleID = 'n3_ns_top.ll'
source_filename = "n3_ns_top.ll"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @atoi(ptr nocapture noundef)

define i32 @main(i32 noundef %argc, ptr noundef %argv) {
e:
  %a1p = getelementptr inbounds ptr, ptr %argv, i64 1
  %a1 = load ptr, ptr %a1p, align 8
  %m = call i32 @atoi(ptr noundef %a1)
  %m7 = and i32 %m, 7
  %m3 = and i32 %m, 3
  %h = call i32 @cqrt_alloc_i32(i32 %m7)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i32(i32 %m3)
  call void @cqrt_ry_i32(i32 %h1, double 3.000000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %r = call i32 @__cq_q_h_11(i32 noundef 0, i32 noundef %h1)
  %r9 = call i32 @__cq_q_h2_11(i32 noundef 0, i32 noundef %h1)
  %m4 = call i32 @cqrt_measure_i32(i32 %r9)
  %h_op2 = call i32 @cq_template_xor_i32(i32 %h, i32 %h_op)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op2, i32 10)
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase !0
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op2, i32 10)
  call void @cq_template_xor_i32_unc(i32 %h_op2, i32 %h, i32 %h_op)
  call void @cqrt_free(i32 %h_op2)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m5 = call i32 @cqrt_measure_i32(i32 %h)
  %m6 = call i32 @cqrt_measure_i32(i32 %r)
  %s = add nsw i32 %m5, %m6
  ret i32 %s
}

define i32 @h(i32 noundef range(i32 1, 100) %a, i32 noundef %k) {
e:
  %r = tail call i32 @h1(i32 noundef range(i32 1, 100) %a, i32 noundef %k)
  ret i32 %r
}

; Function Attrs: noinline
define i32 @h1(i32 noundef range(i32 1, 100) %a, i32 noundef %k) #0 {
e:
  %r = call i32 @h2(i32 noundef range(i32 1, 100) %a, i32 noundef %k)
  %r2 = add nsw i32 %r, 2
  ret i32 %r2
}

; Function Attrs: noinline
define i32 @h2(i32 noundef range(i32 1, 100) %x, i32 noundef %k) #0 {
e:
  %c = icmp sgt i32 %x, 3
  br i1 %c, label %t, label %f

t:                                                ; preds = %e
  br label %f

f:                                                ; preds = %t, %e
  %r = add nsw i32 %k, 1
  ret i32 %r
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_h_11(i32 noundef %a, i32 noundef %k) #1 {
e:
  %r = tail call i32 @__cq_q_h1_11(i32 noundef 0, i32 noundef %k)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %r, i32 %cqq.out)
  call void @__cq_q_h1_11_unc(i32 %r, i32 0, i32 %k)
  call void @cqrt_free(i32 %r)
  ret i32 %cqq.out
}

; Function Attrs: noinline memory(readwrite)
define internal i32 @__cq_q_h1_11(i32 noundef %a, i32 noundef %k) #2 {
e:
  %r = call i32 @__cq_q_h2_11(i32 noundef 0, i32 noundef %k)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %r, i32 2)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %r, i32 2)
  call void @__cq_q_h2_11_unc(i32 %r, i32 0, i32 %k)
  call void @cqrt_free(i32 %r)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

; Function Attrs: noinline memory(readwrite)
define internal i32 @__cq_q_h2_11(i32 noundef %x, i32 noundef %k) #2 {
e:
  %h_op = call i32 @cq_template_add_i32_hl(i32 %k, i32 1)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %k, i32 1)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

; Function Attrs: noinline memory(readwrite)
define internal void @__cq_q_h2_11_unc(i32 %out, i32 noundef %x, i32 noundef %k) #2 {
e:
  %h_op = call i32 @cq_template_add_i32_hl(i32 %k, i32 1)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %k, i32 1)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; Function Attrs: noinline memory(readwrite)
define internal void @__cq_q_h1_11_unc(i32 %out, i32 noundef %a, i32 noundef %k) #2 {
e:
  %r = call i32 @__cq_q_h2_11(i32 noundef 0, i32 noundef %k)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %r, i32 2)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %r, i32 2)
  call void @__cq_q_h2_11_unc(i32 %r, i32 0, i32 %k)
  call void @cqrt_free(i32 %r)
  call void @cqrt_free(i32 %h_op)
  ret void
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_xor_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_xor_i32_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

attributes #0 = { noinline }
attributes #1 = { memory(readwrite) }
attributes #2 = { noinline memory(readwrite) }

!0 = !{}
