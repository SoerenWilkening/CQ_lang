; HAND-WRITTEN. Rules: 1, 2, 4.
; Checked: add_i8's y = x + c (%5 -> %6), add_i16's y (%5 -> %6), add_i64's x + c (%5 -> %6), and_i1's z = x & y
; (%7 -> %8), each the function's measured return.
; Clean: nothing to clean: each function holds only its rotated register(s) and the measured result.
; Kept: each function's rotated register(s) (%4; and_i1's %5 and %6) and its measured result rail.
; Rotations: (Ry, x, th, 1) in add_i8, add_i16 and add_i64; (Ry, x, tx, 1); (Ry, y, ty, 1) in and_i1.
; One width variant per function (rule 1): the alloc, Ry, add template and measure are chosen by width, the classical c is
; the literal operand of the _hl template (rule 4). and_i1's `x & y` is DATA (the measured value), so it is the
; cq_template_and_i1 form of rule 8, not a flag rail.
source_filename = "int_widths.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define signext i8 @add_i8(i8 noundef signext %0, double noundef %1, i8 noundef signext %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %4 = cq_theta_si8(%0, %1)  [register]
  call void @cqrt_ry_i8(i32 %4, double %1)    ; IR: %4 = cq_theta_si8(%0, %1)  [Ry]
  %5 = call i32 @cq_template_add_i8_hl(i32 %4, i8 %2)    ; IR: %5 = add i8 %4, %2
  %6 = call i8 @cqrt_measure_i8(i32 %5)    ; IR: %6 = cq_measure_si8(%5)
  ret i8 %6    ; IR: ret i8 %6
}

; Function Attrs: nounwind ssp uwtable
define signext i16 @add_i16(i16 noundef signext %0, double noundef %1, i16 noundef signext %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i16(i16 %0)    ; IR: %4 = cq_theta_si16(%0, %1)  [register]
  call void @cqrt_ry_i16(i32 %4, double %1)    ; IR: %4 = cq_theta_si16(%0, %1)  [Ry]
  %5 = call i32 @cq_template_add_i16_hl(i32 %4, i16 %2)    ; IR: %5 = add i16 %4, %2
  %6 = call i16 @cqrt_measure_i16(i32 %5)    ; IR: %6 = cq_measure_si16(%5)
  ret i16 %6    ; IR: ret i16 %6
}

; Function Attrs: nounwind ssp uwtable
define i64 @add_i64(i64 noundef %0, double noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %4 = cq_theta_sll(%0, %1)  [register]
  call void @cqrt_ry_i64(i32 %4, double %1)    ; IR: %4 = cq_theta_sll(%0, %1)  [Ry]
  %5 = call i32 @cq_template_add_i64_hl(i32 %4, i64 %2)    ; IR: %5 = add nsw i64 %4, %2
  %6 = call i64 @cqrt_measure_i64(i32 %5)    ; IR: %6 = cq_measure_sll(%5)
  ret i64 %6    ; IR: ret i64 %6
}

; Function Attrs: nounwind ssp uwtable
define zeroext i1 @and_i1(i1 noundef zeroext %0, i1 noundef zeroext %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i1(i1 %0)    ; IR: %5 = cq_theta_i1(%0, %2)  [register]
  call void @cqrt_ry_i1(i32 %5, double %2)    ; IR: %5 = cq_theta_i1(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i1(i1 %1)    ; IR: %6 = cq_theta_i1(%1, %3)  [register]
  call void @cqrt_ry_i1(i32 %6, double %3)    ; IR: %6 = cq_theta_i1(%1, %3)  [Ry]
  %7 = call i32 @cq_template_and_i1(i32 %5, i32 %6)    ; IR: %7 = and i1 %5, %6
  %8 = call i1 @cqrt_measure_i1(i32 %7)    ; IR: %8 = cq_measure_i1(%7)
  ret i1 %8    ; IR: ret i1 %8
}

declare void @cqrt_ry_i8(i32, double)

declare i32 @cqrt_alloc_i8(i8 signext)

declare void @cqrt_ry_i16(i32, double)

declare i32 @cqrt_alloc_i16(i16 signext)

declare void @cqrt_ry_i64(i32, double)

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1 zeroext)

declare i32 @cq_template_add_i8_hl(i32, i8 signext)

declare i32 @cq_template_add_i16_hl(i32, i16 signext)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare i32 @cq_template_and_i1(i32, i32)

declare signext i8 @cqrt_measure_i8(i32)

declare signext i16 @cqrt_measure_i16(i32)

declare i64 @cqrt_measure_i64(i32)

declare zeroext i1 @cqrt_measure_i1(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
