; HAND-WRITTEN. Rules: 1, 2, 4, 6.
; Checked: y = x + c (measured, %5 -> %7).
; Clean: the old x rail (%4, rule 6: |0> after the copy) and the inverse t = y - c (%6), both freed.
; Kept: y (%5, measured: a measured rail stays allocated).
; Rotations: (Ry, x, th, 1).
; cq_theta on the classical x0 mints alloc_i32(x0) and rotates it in place (rule 2). y = x + c is a mixed Q+C add: the
; classical c is a literal operand of the _hl template and the sum lands in a fresh rail (rule 4). The measurement of
; y is the sink. x is dead after the add and the add is a bijection in x for fixed c, so the old x rail is cleaned (rule 6):
; t = y - c recomputes it, copy_i32 zeroes x, t is uncomputed, both are freed.
source_filename = "add_classical_const.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @add_classical(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)    ; IR: %5 = add nsw i32 %4, %2
  %6 = call i32 @cq_template_sub_i32_hl(i32 %5, i32 %2)    ; IR: rule 6: t = y - c recomputes the old x (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %6, i32 %4)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_sub_i32_hl_unc(i32 %6, i32 %5, i32 %2)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %6)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the old x rail (|0> after the copy)
  %7 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %7    ; IR: ret i32 %6
}

declare void @cqrt_free(i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

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
