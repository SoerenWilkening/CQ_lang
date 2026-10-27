; HAND-WRITTEN. Rules: 20 (non-escaping union is a value, bit-field views), 3, 4, 5, 2, 25.
; Checked: u.e after the exponent write-back (the result rail %17 -> %18).
; Clean: every view and arithmetic rail (%5..%16: the bitcast, shift, trunc, zext, the exponent arithmetic, the masks, the
; recomposed word and object bits), all uncomputed in LIFO order and freed.
; Kept: x (%4, the rotated register) and the result u.e (%17, measured).
; Rotations: (Ry, x, th, 1).
; The union is a non-escaping alloca, so it is a VALUE, not memory: the slot holds the handle of the long double rail, and a
; load/store of a narrower word at a byte offset is a bit-field VIEW of that value. The i32 word at byte 8 is bits 64..95 of
; the 10-byte object: bits 64..79 are the exponent and sign of the x86_fp80, bits 80..95 are padding and read as 0 (zext).
; Reading the view is bitcast -> lshr -> trunc; writing it back composes a new long double from the untouched low 64 bits
; and the new word (or of the two disjoint parts), then bitcast; the result rail is the new u.e. Nothing is in place.
source_filename = "f80_union_slot.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define x86_fp80 @f80_union_slot(x86_fp80 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_f80(x86_fp80 %0)    ; IR: %5 = cq_theta_f80(%0, %1)  [register x; store x86_fp80 %5, ptr %4 puts this handle in the slot]
  call void @cqrt_ry_f80(i32 %4, double %1)    ; IR: %5 = cq_theta_f80(%0, %1)  [Ry]
  %5 = call i32 @cq_template_bitcast_f80_to_i80(i32 %4)    ; IR: %7 = load i32, ptr %6: the bit view of the stored x86_fp80
  %6 = call i32 @cq_template_lshr_i80_hl(i32 %5, i80 64)    ; IR: %7: bits 64.. of the object (byte offset 8)
  %7 = call i32 @cq_template_trunc_i80_to_i16(i32 %6)    ; IR: %7: the 16 value bits of that word (exp:15 | sign:1)
  %8 = call i32 @cq_template_zext_i16_to_i32(i32 %7)    ; IR: %7: the i32 word; bits 80..95 are padding and read as 0
  %9 = call i32 @cq_template_sub_i32_hl(i32 %8, i32 %2)    ; IR: %8 = sub i32 %7, %2
  %10 = call i32 @cq_template_and_i32_hl(i32 %9, i32 32767)    ; IR: %9 = and i32 %8, 32767
  %11 = call i32 @cq_template_and_i32_hl(i32 %8, i32 -32768)    ; IR: %10 = and i32 %7, -32768
  %12 = call i32 @cq_template_or_i32(i32 %10, i32 %11)    ; IR: %11 = or disjoint i32 %9, %10  [the new word]
  %13 = call i32 @cq_template_and_i80_hl(i32 %5, i80 18446744073709551615)    ; IR: store i32 %11, ptr %12: the untouched low 64 bits of the object
  %14 = call i32 @cq_template_zext_i32_to_i80(i32 %12)    ; IR: store i32 %11, ptr %12: the new word widened to the object
  %15 = call i32 @cq_template_shl_i80_hl(i32 %14, i80 64)    ; IR: store i32 %11, ptr %12: placed at bit 64 (bits beyond 80 fall off)
  %16 = call i32 @cq_template_or_i80(i32 %13, i32 %15)    ; IR: store i32 %11, ptr %12: the new object bits
  %17 = call i32 @cq_template_bitcast_i80_to_f80(i32 %16)    ; IR: %13 = load x86_fp80, ptr %4  [result rail: the new u.e]
  call void @cq_template_or_i80_unc(i32 %16, i32 %13, i32 %15)    ; IR: uncompute the new object bits
  call void @cqrt_free(i32 %16)    ; IR: release (|0>)
  call void @cq_template_shl_i80_hl_unc(i32 %15, i32 %14, i80 64)    ; IR: uncompute the placed word
  call void @cqrt_free(i32 %15)    ; IR: release (|0>)
  call void @cq_template_zext_i32_to_i80_unc(i32 %14, i32 %12)    ; IR: uncompute the widened word
  call void @cqrt_free(i32 %14)    ; IR: release (|0>)
  call void @cq_template_and_i80_hl_unc(i32 %13, i32 %5, i80 18446744073709551615)    ; IR: uncompute the low 64 bits
  call void @cqrt_free(i32 %13)    ; IR: release (|0>)
  call void @cq_template_or_i32_unc(i32 %12, i32 %10, i32 %11)    ; IR: uncompute %11
  call void @cqrt_free(i32 %12)    ; IR: release the %11 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %8, i32 -32768)    ; IR: uncompute %10
  call void @cqrt_free(i32 %11)    ; IR: release the %10 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %9, i32 32767)    ; IR: uncompute %9
  call void @cqrt_free(i32 %10)    ; IR: release the %9 rail (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %9, i32 %8, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %9)    ; IR: release the %8 rail (|0>)
  call void @cq_template_zext_i16_to_i32_unc(i32 %8, i32 %7)    ; IR: uncompute the %7 word
  call void @cqrt_free(i32 %8)    ; IR: release (|0>)
  call void @cq_template_trunc_i80_to_i16_unc(i32 %7, i32 %6)    ; IR: uncompute the 16 value bits
  call void @cqrt_free(i32 %7)    ; IR: release (|0>)
  call void @cq_template_lshr_i80_hl_unc(i32 %6, i32 %5, i80 64)    ; IR: uncompute the shifted view
  call void @cqrt_free(i32 %6)    ; IR: release (|0>)
  call void @cq_template_bitcast_f80_to_i80_unc(i32 %5, i32 %4)    ; IR: uncompute the bit view
  call void @cqrt_free(i32 %5)    ; IR: release (|0>)
  %18 = call x86_fp80 @cqrt_measure_f80(i32 %17)    ; IR: %14 = cq_measure_f80(%13)
  ret x86_fp80 %18    ; IR: ret x86_fp80 %14
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare void @cqrt_ry_f80(i32, double)

declare i32 @cqrt_alloc_f80(x86_fp80)

declare i32 @cq_template_bitcast_f80_to_i80(i32)

declare i32 @cq_template_lshr_i80_hl(i32, i80)

declare i32 @cq_template_trunc_i80_to_i16(i32)

declare i32 @cq_template_zext_i16_to_i32(i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_or_i32(i32, i32)

declare i32 @cq_template_and_i80_hl(i32, i80)

declare i32 @cq_template_zext_i32_to_i80(i32)

declare i32 @cq_template_shl_i80_hl(i32, i80)

declare i32 @cq_template_or_i80(i32, i32)

declare i32 @cq_template_bitcast_i80_to_f80(i32)

declare x86_fp80 @cqrt_measure_f80(i32)

declare void @cq_template_or_i80_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_shl_i80_hl_unc(i32, i32, i80)

declare void @cq_template_zext_i32_to_i80_unc(i32, i32)

declare void @cq_template_and_i80_hl_unc(i32, i32, i80)

declare void @cq_template_or_i32_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare void @cq_template_zext_i16_to_i32_unc(i32, i32)

declare void @cq_template_trunc_i80_to_i16_unc(i32, i32)

declare void @cq_template_lshr_i80_hl_unc(i32, i32, i80)

declare void @cq_template_bitcast_f80_to_i80_unc(i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
