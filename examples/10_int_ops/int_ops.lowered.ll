; HAND-WRITTEN. Rules: 4, 2, 6.
; Checked: the result of each function (measured): x - c, x * y, x << c, x >> y (logical), x >> c (arithmetic), x & c,
; x | y, x ^ y.
; Clean: rule 6 in sub_qc (the old x rail %4 and t = r + c %6) and xor_qq (the old y rail %6, operand 0 of the IR xor,
; and t = r ^ x %8), all freed; nothing else (each result rail is measured).
; Kept: the user registers x (and y) of the other functions (their op has no inverse in them), xor_qq's x, and the
; measured result rails.
; Rotations: Ry(th) on x in sub_qc, shl_qc, ashr_qc, and_qc; Ry(tx) on x and Ry(ty) on y in mul_qq, lshr_qq, or_qq,
; xor_qq.
; Eight integer opcodes, each out of place into a fresh rail (rule 4). A quantum-classical op takes the classical
; operand as a literal (_hl); a quantum-quantum op takes two handles. A commutative op (mul, or, xor) puts the handle
; order as the template spells it; sub, shl, ashr, and take the literal on the right. sub (in x for fixed c) and xor (in
; either operand) are bijections of a dead register, so rule 6 cleans the old rail right after the op; mul, shifts, and,
; or have no inverse and keep their registers.
source_filename = "int_ops.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @sub_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_sub_i32_hl(i32 %4, i32 %2)    ; IR: %5 = sub nsw i32 %4, %2
  %6 = call i32 @cq_template_add_i32_hl(i32 %5, i32 %2)    ; IR: rule 6: t = r + c recomputes the old x (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %6, i32 %4)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_add_i32_hl_unc(i32 %6, i32 %5, i32 %2)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %6)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the old x rail (|0> after the copy)
  %7 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %7    ; IR: ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @mul_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %2)  [register]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_si32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_si32(%1, %3)  [register]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_si32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_mul_i32(i32 %5, i32 %6)    ; IR: %7 = mul nsw i32 %6, %5
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %8    ; IR: ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @shl_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_shl_i32_hl(i32 %4, i32 %2)    ; IR: %5 = shl i32 %4, %2
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @lshr_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %2)  [register]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_ui32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_ui32(%1, %3)  [register]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_ui32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_lshr_i32(i32 %5, i32 %6)    ; IR: %7 = lshr i32 %5, %6
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_ui32(%7)
  ret i32 %8    ; IR: ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @ashr_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_ashr_i32_hl(i32 %4, i32 %2)    ; IR: %5 = ashr i32 %4, %2
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @and_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 %2)    ; IR: %5 = and i32 %4, %2
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @or_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %2)  [register]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_si32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_si32(%1, %3)  [register]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_si32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_or_i32(i32 %5, i32 %6)    ; IR: %7 = or i32 %6, %5
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %8    ; IR: ret i32 %8
}

define i32 @xor_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %2)  [register]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_si32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_si32(%1, %3)  [register]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_si32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_xor_i32(i32 %6, i32 %5)    ; IR: %7 = xor i32 %6, %5
  %8 = call i32 @cq_template_xor_i32(i32 %7, i32 %5)    ; IR: rule 6: t = r ^ x recomputes the old y (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %8, i32 %6)    ; IR: rule 6: y ^= t: the dead y rail is now |0>
  call void @cq_template_xor_i32_unc(i32 %8, i32 %7, i32 %5)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %8)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %6)    ; IR: release the old y rail (|0> after the copy)
  %9 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %9    ; IR: ret i32 %8
}

declare void @cq_template_xor_i32_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_xor_i32(i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare i32 @cq_template_mul_i32(i32, i32)

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare i32 @cq_template_lshr_i32(i32, i32)

declare i32 @cq_template_ashr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_or_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
