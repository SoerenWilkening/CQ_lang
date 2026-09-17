; ISOLATING CONTROL for t4_switch_backedge_k1.ll: the SAME module with the back
; edge spelled as a two-target `br i1` on ONE line. (T4f) must refuse it.
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

define i32 @f(i32 %x) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %r = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
  br label %body

body:
  %c = call i32 @cq_template_icmp_eq_i32_hl(i32 %r, i32 0)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %c, i32 %r, i32 0)
  call void @cqrt_free(i32 %c)
  call void @cq_template_and_i32_hl_unc(i32 %r, i32 %h, i32 1)
  call void @cqrt_free(i32 %r)
  %p = icmp eq i32 %x, 0
  br i1 %p, label %body, label %out

out:
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}
