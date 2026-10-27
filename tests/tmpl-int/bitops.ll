; tests/tmpl-int (cq-f69): and, or and xor templates, the i1 data templates included, run through the
; real evaluator core and dispatcher. tmpl-int registers none of them; tmpl-bits serves them.
target triple = "x86_64-apple-macosx16.0.0"

define i32 @v(i32 %x0, i32 %x1) {
  %a = call i32 @cqrt_alloc_i32(i32 %x0)
  %b = call i32 @cqrt_alloc_i32(i32 %x1)
  %r1 = call i32 @cq_template_and_i32(i32 %a, i32 %b)
  %r2 = call i32 @cq_template_or_i32(i32 %a, i32 %b)
  %r3 = call i32 @cq_template_xor_i32(i32 %a, i32 %b)
  %r4 = call i32 @cq_template_and_i32_hl(i32 %a, i32 252645135)
  %u = call i32 @cq_template_xor_i32(i32 %a, i32 %b)
  call void @cq_template_xor_i32_unc(i32 %u, i32 %a, i32 %b)
  call void @cqrt_free(i32 %u)
  %t0 = trunc i32 %x0 to i1
  %t1 = trunc i32 %x1 to i1
  %a1 = call i32 @cqrt_alloc_i1(i1 %t0)
  %b1 = call i32 @cqrt_alloc_i1(i1 %t1)
  %s1 = call i32 @cq_template_and_i1(i32 %a1, i32 %b1)
  %s2 = call i32 @cq_template_or_i1(i32 %a1, i32 %b1)
  %s3 = call i32 @cq_template_xor_i1(i32 %a1, i32 %b1)
  %s4 = call i32 @cq_template_xor_i1_hl(i32 %a1, i1 true)
  %w0 = zext i32 %x0 to i128
  %w1 = shl i128 %w0, 96
  %w = or i128 %w1, %w0
  %aw = call i32 @cqrt_alloc_i128(i128 %w)
  %q1 = call i32 @cq_template_or_i128_hl(i32 %aw, i128 1237940039285380274899124224)
  %m1 = call i32 @cqrt_measure_i32(i32 %r1)
  %m2 = call i32 @cqrt_measure_i32(i32 %r2)
  %m3 = call i32 @cqrt_measure_i32(i32 %r3)
  %m4 = call i32 @cqrt_measure_i32(i32 %r4)
  %n1 = call i1 @cqrt_measure_i1(i32 %s1)
  %n2 = call i1 @cqrt_measure_i1(i32 %s2)
  %n3 = call i1 @cqrt_measure_i1(i32 %s3)
  %n4 = call i1 @cqrt_measure_i1(i32 %s4)
  %mq = call i128 @cqrt_measure_i128(i32 %q1)
  ret i32 %m1
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i128(i128)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i1 @cqrt_measure_i1(i32)
declare i128 @cqrt_measure_i128(i32)
declare i32 @cq_template_and_i32(i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare i32 @cq_template_xor_i32(i32, i32)
declare void @cq_template_xor_i32_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare i32 @cq_template_and_i1(i32, i32)
declare i32 @cq_template_or_i1(i32, i32)
declare i32 @cq_template_xor_i1(i32, i32)
declare i32 @cq_template_xor_i1_hl(i32, i1)
declare i32 @cq_template_or_i128_hl(i32, i128)
