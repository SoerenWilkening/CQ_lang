; HAND-WRITTEN. Rules: 2, 8, 4, 5.
; Checked: x (measured, %5 -> %7).
; Clean: the flag f = (x == k) (%6), uncomputed by the compare's _unc after the phase and freed.
; Kept: x (%5, the rotated user register, measured at the end).
; Rotations: (Ry, x, th, 1); (P, f, phi, x == k).
; The tainted branch condition x == k is a flag rail minted by the equality template with the classical k as a literal
; (rule 8). The arm's only content is cq_phi(phi), a phase arm: it is the register-free kickback rz_i1(f, phi) on the
; flag, never a gate on x. The flag is uncomputed right after its one controlled gate and freed; x is then measured.
source_filename = "phase_arm_eq.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @phase_arm_eq(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 %2)    ; IR: %6 = icmp eq i32 %5, %2
  call void @cqrt_rz_i1(i32 %6, double %3), !cq.branchphase !6    ; IR: block %7 under br i1 %6: cq_phi(%3)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %5, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %7 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %9 = cq_measure_si32(%5)
  ret i32 %7    ; IR: ret i32 %9
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_not_i1(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

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
!6 = !{}
