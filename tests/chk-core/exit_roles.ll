; cq-tt2j: exit roles the leak rule reads (CR §6 item 1): a rail whose handle memory holds is nothing special:
; "garbage" like any other; an _exc result and
; a rail written from it are "fenv_flags", an _rmq mode operand "fenv_mode" (rule 23); a seed is known.
target triple = "x86_64-apple-macosx16.0.0"
@g = global i32 0, align 4
define i32 @lk(i32 %x0, double %th, double %y0, i32 %c) {
  %slot = alloca i32, align 4
  %x = call i32 @cqrt_alloc_i32(i32 %x0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %y = call i32 @cqrt_alloc_f64(double %y0)
  call void @cqrt_ry_f64(i32 %y, double %th)
  %a = call i32 @cq_template_add_i32_hl(i32 %x, i32 %c)
  store i32 %a, ptr @g, align 4
  %b = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  store i32 %b, ptr %slot, align 4
  %e = call i32 @cq_template_fadd_f64_hl_rm_exc(i32 %y, double 1.0, i32 0)
  %e2 = call i32 @cq_template_or_i32_hl(i32 %e, i32 0)
  %k = call i32 @cqrt_alloc_i32(i32 5)
  %p = call ptr @malloc(i64 4)
  %h = call i32 @cq_template_add_i32_hl(i32 %x, i32 2)
  store i32 %h, ptr %p, align 4
  call void @free(ptr %p)
  %cnd = call i32 @cq_template_icmp_sgt_i32_hl(i32 %x, i32 0)
  %md = call i32 @cq_template_select_i32_ll(i32 %cnd, i32 1024, i32 2048)
  %z = call i32 @cq_template_fadd_f64_hl_rmq(i32 %y, double 1.0, i32 %md)
  %zm = call double @cqrt_measure_f64(i32 %z)
  ret i32 %c
}
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_f64(i32, double)
declare double @cqrt_measure_f64(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_or_i32_hl(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare i32 @cq_template_fadd_f64_hl_rm_exc(i32, double, i32)
declare i32 @cq_template_fadd_f64_hl_rmq(i32, double, i32)
declare ptr @malloc(i64)
declare void @free(ptr)
