; ModuleID = 'p7_fp_classical_slot_nn.ll'
source_filename = "p7_fp_classical_slot_nn.ll"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @atoi(ptr nocapture noundef)

define i32 @main(i32 noundef %argc, ptr noundef %argv) {
e:
  %a1p = getelementptr inbounds ptr, ptr %argv, i64 1
  %a1 = load ptr, ptr %a1p, align 8
  %m = call i32 @atoi(ptr noundef %a1)
  %m7 = and i32 %m, 7
  %md = sitofp i32 %m to double
  %h = call i32 @cqrt_alloc_i32(i32 %m7)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @__cq_q_h_001(i32 noundef %h, double noundef 0.000000e+00, i32 noundef %m)
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m1 = call i32 @cqrt_measure_i32(i32 %h)
  %m2 = call i32 @cqrt_measure_i32(i32 %r)
  %s = add nsw i32 %m1, %m2
  ret i32 %s
}

define i32 @h(i32 noundef %a, double noundef nofpclass(zero) %c, i32 noundef %k) {
e:
  %r = tail call i32 @h2(i32 noundef %a, double noundef nofpclass(zero) %c, i32 noundef %k)
  ret i32 %r
}

; Function Attrs: noinline
define i32 @h2(i32 noundef %x, double noundef nofpclass(zero) "cq.probe.opaque" %y, i32 noundef %k) #0 {
e:
  %r = add nsw i32 %x, %k
  ret i32 %r
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_h_001(i32 noundef %a, double noundef %c, i32 noundef %k) #1 {
e:
  %r = tail call i32 @__cq_q_h2_001(i32 noundef %a, double noundef %c, i32 noundef %k)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %r, i32 %cqq.out)
  call void @__cq_q_h2_001_unc(i32 %r, i32 %a, double %c, i32 %k)
  call void @cqrt_free(i32 %r)
  ret i32 %cqq.out
}

; Function Attrs: noinline memory(readwrite)
define internal i32 @__cq_q_h2_001(i32 noundef %x, double noundef "cq.probe.opaque" %y, i32 noundef %k) #2 {
e:
  %h_op = call i32 @cq_template_add_i32_hl(i32 %x, i32 %k)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %x, i32 %k)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

; Function Attrs: noinline memory(readwrite)
define internal void @__cq_q_h2_001_unc(i32 %out, i32 noundef %x, double noundef nofpclass(zero) "cq.probe.opaque" %y, i32 noundef %k) #2 {
e:
  %h_op = call i32 @cq_template_add_i32_hl(i32 %x, i32 %k)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %x, i32 %k)
  call void @cqrt_free(i32 %h_op)
  ret void
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { noinline }
attributes #1 = { memory(readwrite) }
attributes #2 = { noinline memory(readwrite) }
