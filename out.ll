; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/ir-pass/test/lowering_fp80_union_dead_insert.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/ir-pass/test/lowering_fp80_union_dead_insert.ll"
target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

define i64 @dead() {
entry:
  %h = call i32 @cqrt_alloc_f80(x86_fp80 0xK3FFE8000000000000000)
  call void @cqrt_ry_f80(i32 %h, double 5.000000e-01)
  %h_cast = call i32 @cq_template_bitcast_f80_to_i80(i32 %h)
  %h_cast4 = call i32 @cq_template_trunc_i80_to_i64(i32 %h_cast)
  %h_op = call i32 @cq_template_and_i64_hl(i32 %h_cast4, i64 4294967295)
  %h_op5 = call i32 @cq_template_lshr_i80_hl(i32 %h_cast, i80 64)
  %h_cast6 = call i32 @cq_template_trunc_i80_to_i16(i32 %h_op5)
  %h_cast7 = call i32 @cq_template_zext_i16_to_i64(i32 %h_cast6)
  %h_op8 = call i32 @cq_template_and_i64_hl(i32 %h_cast7, i64 32767)
  %h_op9 = call i32 @cq_template_add_i64(i32 %h_op, i32 %h_op8)
  %m10 = call i64 @cqrt_measure_i64(i32 %h_op9)
  ret i64 %m10
}

declare void @cqrt_ry_f80(i32, double)

declare i32 @cqrt_alloc_f80(x86_fp80)

declare i32 @cq_template_bitcast_f80_to_i80(i32)

declare i32 @cq_template_trunc_i80_to_i64(i32)

declare i32 @cq_template_and_i64_hl(i32, i64)

declare i32 @cq_template_lshr_i80_hl(i32, i80)

declare i32 @cq_template_trunc_i80_to_i16(i32)

declare i32 @cq_template_zext_i16_to_i64(i32)

declare i32 @cq_template_add_i64(i32, i32)

declare i64 @cqrt_measure_i64(i32)
