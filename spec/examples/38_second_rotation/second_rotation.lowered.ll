; HAND-WRITTEN. Rules: 2, 4, 6.
; Checked: second_rotation: x (%4, measured as %5); rotate_derived: y = x + c (%5, the x rail; measured as %6);
; rotate_double: x (%4, measured as %5).
; Clean: nothing to free in any of the three: every rail is a user register.
; Kept: second_rotation: x (%4, measured); rotate_derived: y (%5, rotated then measured); rotate_double: x (%4, measured).
; Rotations: second_rotation: (Ry, x, t1, 1); (Ry, x, t2, 1). rotate_derived: (Ry, x, t1, 1); (Ry, y = x + c, t2, 1).
; rotate_double: (Ry_f64, x, t1, 1); (Ry_f64, x, t2, 1).
; A second cq_theta on a register that is already a handle is a second Ry on the same rail (rule 2: a rotation of an
; existing handle is in place). A cq_theta on a derived value (y = x + c) rotates the rail that holds y. x is dead after
; the add and y = x + c is a bijection in x for fixed c, so rule 6's in-place update applies: the add is ONE core gate,
; addc_i32(x, c), on the x rail, and y is that rail from there on (no template, no fresh rail, no clean-up, no free).
; No copy of the old x is left: a kept x would be a which-path record of y, and the Ry(t2) would act on a dephased y
; (1-bit view, t1 = t2 = pi/2, c = 1: in place, y = X Ry(pi/2)|0> and Ry(pi/2) gives |1> with probability 1; kept, 1/2).
source_filename = "second_rotation.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @second_rotation(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  call void @cqrt_ry_i32(i32 %4, double %2)    ; IR: %5 = cq_theta_si32(%4, %2)  [second Ry on the same rail]
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %5    ; IR: ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @rotate_derived(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  call void @cqrt_addc_i32(i32 %5, i32 %3)    ; IR: %6 = add nsw i32 %5, %3  [rule 6, in-place update: x is dead after the add, so y IS the x rail]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %7 = cq_theta_si32(%6, %2)  [Ry on the same rail, now holding y]
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %6    ; IR: ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define double @rotate_double(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  call void @cqrt_ry_f64(i32 %4, double %2)    ; IR: %5 = cq_theta_f64(%4, %2)  [second Ry]
  %5 = call double @cqrt_measure_f64(i32 %4)    ; IR: %6 = cq_measure_f64(%5)
  ret double %5    ; IR: ret double %6
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare void @cqrt_addc_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare double @cqrt_measure_f64(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
