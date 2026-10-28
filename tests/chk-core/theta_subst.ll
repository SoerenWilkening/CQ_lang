; cq_theta substitution (cq-6m2, cq-arch Z4): a minted register, a rotated flag, a controlled Ry on a
; seed, an angle-rail Ry. Each firing Ry takes the $CQE_THETA reach with its width and angle.
target triple = "x86_64-apple-macosx16.0.0"
define i32 @ts(i32 %x0, double %th) {
  %x = call i32 @cqrt_alloc_i8(i8 5)
  call void @cqrt_ry_i8(i32 %x, double %th)
  %c = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %c, double 1.0)
  %g = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_ry_i8_controlled(i32 %c, i32 %g, double 2.0)
  %a = call i32 @cqrt_alloc_f64(double 3.0)
  %q = call i32 @cqrt_alloc_i32(i32 9)
  call void @cqrt_ry_i32_qangle(i32 %q, i32 %a)
  %mx = call i8 @cqrt_measure_i8(i32 %x)
  %mg = call i8 @cqrt_measure_i8(i32 %g)
  %mq = call i32 @cqrt_measure_i32(i32 %q)
  %zx = zext i8 %mx to i32
  %zg = zext i8 %mg to i32
  %s = add i32 %zx, %zg
  %r = add i32 %s, %mq
  ret i32 %r
}
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_ry_i8(i32, double)
declare void @cqrt_ry_i8_controlled(i32, i32, double)
declare void @cqrt_ry_i32_qangle(i32, i32)
declare i8 @cqrt_measure_i8(i32)
declare i32 @cqrt_measure_i32(i32)
