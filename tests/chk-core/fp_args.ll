; tests/chk-core (cq-a4mf): each fp argument is measured as received, so a sample's 0x bit-pattern
; strings can be checked against the value the lowered program sees.
target triple = "x86_64-apple-macosx16.0.0"

define i32 @fpargs(half %h, float %f, double %d, x86_fp80 %x) {
  %a = call i32 @cqrt_alloc_f16(half %h)
  %b = call i32 @cqrt_alloc_f32(float %f)
  %c = call i32 @cqrt_alloc_f64(double %d)
  %e = call i32 @cqrt_alloc_f80(x86_fp80 %x)
  %m1 = call half @cqrt_measure_f16(i32 %a)
  %m2 = call float @cqrt_measure_f32(i32 %b)
  %m3 = call double @cqrt_measure_f64(i32 %c)
  %m4 = call x86_fp80 @cqrt_measure_f80(i32 %e)
  ret i32 0
}

declare i32 @cqrt_alloc_f16(half)
declare i32 @cqrt_alloc_f32(float)
declare i32 @cqrt_alloc_f64(double)
declare i32 @cqrt_alloc_f80(x86_fp80)
declare half @cqrt_measure_f16(i32)
declare float @cqrt_measure_f32(i32)
declare double @cqrt_measure_f64(i32)
declare x86_fp80 @cqrt_measure_f80(i32)
