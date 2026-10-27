; tests/chk-core (cq-9ge): bf16 rails, a bf16 fp template and bf16 bitcasts through the real core and
; dispatcher. The low 16 bits of %x0 are the bf16 input. Width token bf16 (bits 16, kind 'f'); a
; bfloat literal resolves to kind 'f' (cqe.h M2).
target triple = "x86_64-apple-macosx16.0.0"

define i32 @v(i32 %x0) {
  %x16 = trunc i32 %x0 to i16
  %xb = bitcast i16 %x16 to bfloat
  %a = call i32 @cqrt_alloc_bf16(bfloat %xb)
  %i = call i32 @cqrt_alloc_i16(i16 %x16)
  %s1 = call i32 @cq_template_fadd_bf16(i32 %a, i32 %a)
  %s2 = call i32 @cq_template_fadd_bf16_hl(i32 %a, bfloat 0xR3F80)
  %c1 = call i32 @cq_template_bitcast_bf16_to_i16(i32 %a)
  %c2 = call i32 @cq_template_bitcast_bf16_to_i16_l(bfloat 0xR4049)
  %c3 = call i32 @cq_template_bitcast_i16_to_bf16(i32 %i)
  %c4 = call i32 @cq_template_bitcast_i16_to_bf16_l(i16 4660)
  %c5 = call i32 @cq_template_bitcast_bf16_to_f16(i32 %a)
  %u = call i32 @cq_template_bitcast_bf16_to_i16(i32 %a)
  call void @cq_template_bitcast_bf16_to_i16_unc(i32 %u, i32 %a)
  call void @cqrt_free(i32 %u)
  %m1 = call bfloat @cqrt_measure_bf16(i32 %s1)
  %m2 = call bfloat @cqrt_measure_bf16(i32 %s2)
  %m3 = call i16 @cqrt_measure_i16(i32 %c1)
  %m4 = call i16 @cqrt_measure_i16(i32 %c2)
  %m5 = call bfloat @cqrt_measure_bf16(i32 %c3)
  %m6 = call bfloat @cqrt_measure_bf16(i32 %c4)
  %m7 = call half @cqrt_measure_f16(i32 %c5)
  ret i32 0
}

declare i32 @cqrt_alloc_bf16(bfloat)
declare i32 @cqrt_alloc_i16(i16)
declare void @cqrt_free(i32)
declare bfloat @cqrt_measure_bf16(i32)
declare i16 @cqrt_measure_i16(i32)
declare half @cqrt_measure_f16(i32)
declare i32 @cq_template_fadd_bf16(i32, i32)
declare i32 @cq_template_fadd_bf16_hl(i32, bfloat)
declare i32 @cq_template_bitcast_bf16_to_i16(i32)
declare i32 @cq_template_bitcast_bf16_to_i16_l(bfloat)
declare i32 @cq_template_bitcast_i16_to_bf16(i32)
declare i32 @cq_template_bitcast_i16_to_bf16_l(i16)
declare i32 @cq_template_bitcast_bf16_to_f16(i32)
declare void @cq_template_bitcast_bf16_to_i16_unc(i32, i32)
