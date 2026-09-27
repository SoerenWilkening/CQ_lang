; ModuleID = 'bk_sweep.ll'
source_filename = "bk_sweep.ll"

define i32 @h(i32 %a, i32 %k) {
entry:
  %c = icmp sgt i32 %a, 3
  br i1 %c, label %t, label %e

t:                                                ; preds = %entry
  br label %e

e:                                                ; preds = %t, %entry
  %r = add i32 %k, 1
  ret i32 %r
}

define i32 @main(i32 %m) {
  %lo = trunc i32 %m to i1
  %h = call i32 @cqrt_alloc_i1(i1 %lo)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h)
  call void @cqrt_addc_i32(i32 %h_cast, i32 1)
  %t = call i32 @__cq_q_h_01(i32 %h_cast, i32 %m)
  call void @cqrt_ry_i1(i32 %h, double 0x3FE6666666666666)
  %m1 = call i1 @cqrt_measure_i1(i32 %h)
  %mz = zext i1 %m1 to i32
  %s = add i32 %t, %mz
  ret i32 %s
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: memory(readwrite)
define internal i32 @__cq_q_h_01(i32 %a, i32 %k) #0 {
entry:
  %r = add i32 %k, 1
  ret i32 %r
}

declare void @cqrt_free(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_addc_i32(i32, i32)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i1 @cqrt_measure_i1(i32)

attributes #0 = { memory(readwrite) }
