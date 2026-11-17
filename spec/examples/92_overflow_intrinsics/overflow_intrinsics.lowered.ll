; HAND-WRITTEN. Rules: 4, 9, 5, 2.
; Checked: mul_overflow: r + o, r = x * c wrapped, o its overflow flag; add_overflow_qq: overflow ? INT_MAX : x + y;
; add_sat: uadd_sat(x, c) (each measured).
; Clean: mul_overflow's overflow flag; add_overflow_qq's wrapped sum and overflow flag.
; Kept: the user registers (x; x and y; x); the measured result rails (mul_overflow: the product and the zext'd flag).
; Rotations: Ry(th) on x (mul_overflow, add_sat); Ry(tx) on x and Ry(ty) on y (add_overflow_qq).
; The with.overflow intrinsics return the aggregate { iN, i1 }: the wrapped result and the overflow flag. The handle
; ABI gives one rail per template, so the aggregate is TWO templates over the same operands (rule 4; the convention of
; 81's op / op_exc twins): the value is the ordinary wrapping opcode template (mul_i32 for umul, add_i32 for sadd:
; that IS the wrapped result) and the flag is cq_template_<u|s><op>_overflow_<W>[_hl|_lh], an i1 rail, each with its
; own _unc. extractvalue selects the rail; zext i1 -> i32 is the cast template. llvm.uadd.sat (clang's fold of
; s = x + c; if (s < x) s = ~0u) is the single saturating template cq_template_uadd_sat_<W> (§1.2).
source_filename = "overflow_intrinsics.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @mul_overflow(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_mul_i32_hl(i32 %4, i32 %2)    ; IR: %5 = umul.with.overflow(%4, %2): element 0, the wrapped product (%7)  [measured]
  %6 = call i32 @cq_template_umul_overflow_i32_hl(i32 %4, i32 %2)    ; IR: %5: element 1, the overflow flag (%6)
  %7 = call i32 @cq_template_zext_i1_to_i32(i32 %6)    ; IR: %8 = zext i1 %6 to i32  [measured]
  call void @cq_template_umul_overflow_i32_hl_unc(i32 %6, i32 %4, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %8 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %9 = cq_measure_ui32(%7)
  %9 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %10 = cq_measure_si32(%8)
  %10 = add i32 %9, %8    ; IR: %11 = add i32 %10, %9  (classical)
  ret i32 %10    ; IR: ret i32 %11
}

define i32 @add_overflow_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_si32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_si32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_si32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_add_i32(i32 %5, i32 %6)    ; IR: %7 = sadd.with.overflow(%5, %6): element 0, the wrapped sum (%9)
  %8 = call i32 @cq_template_sadd_overflow_i32(i32 %5, i32 %6)    ; IR: %7: element 1, the overflow flag (%8)
  %9 = call i32 @cq_template_select_i32_lh(i32 %8, i32 2147483647, i32 %7)    ; IR: %10 = select i1 %8, i32 2147483647, i32 %9  [result rail]
  call void @cq_template_sadd_overflow_i32_unc(i32 %8, i32 %5, i32 %6)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_add_i32_unc(i32 %7, i32 %5, i32 %6)    ; IR: uncompute %9
  call void @cqrt_free(i32 %7)    ; IR: release the %9 rail (|0>)
  %10 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %11 = cq_measure_si32(%10)
  ret i32 %10    ; IR: ret i32 %11
}

define i32 @add_sat(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_uadd_sat_i32_hl(i32 %4, i32 %2)    ; IR: %5 = llvm.uadd.sat.i32(%4, %2)  [result rail]
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_ui32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare i32 @cq_template_umul_overflow_i32_hl(i32, i32)
declare void @cq_template_umul_overflow_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_sadd_overflow_i32(i32, i32)
declare void @cq_template_sadd_overflow_i32_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare i32 @cq_template_uadd_sat_i32_hl(i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
