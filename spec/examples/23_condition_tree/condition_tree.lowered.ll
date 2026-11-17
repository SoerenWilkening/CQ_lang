; HAND-WRITTEN. Rules: 8, 2, 5.
; Checked: x (measured) in each entry: cond_and %6 -> %10, cond_or %6 -> %10, cond_mixed %6 -> %11.
; Clean: every flag rail: cond_and %7, %8 (the compares) and %9 (their and_i1); cond_or %7, %8 and %9 (their or_i1);
; cond_mixed %8 (the equality compare); each uncomputed after the kickback it controls and freed.
; Kept: x (%6, the rotated register, measured) in each entry; nothing else.
; Rotations: cond_and: (P, flag, phi, (x > k1) & (x < k2)); cond_or: (P, flag, phi, (x < k1) | (x > k2));
; cond_mixed: (P, flag, phi, x == k), fired only when the classical flag != 0.
; Flags (rule 8): a conjunction of compare flags is cqrt_and_i1 into a fresh |0> rail, a disjunction cqrt_or_i1 into a
; fresh |0> rail, both self-inverse; a phase arm is cqrt_rz_i1 on the flag; the classical conjunct of cond_mixed stays a
; classical branch around the kickback, so the quantum predicate is only the equality flag.
source_filename = "condition_tree.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @cond_and(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 %2)    ; IR: %7 = icmp sgt i32 %6, %2
  %8 = call i32 @cq_template_icmp_slt_i32_hl(i32 %6, i32 %3)    ; IR: %8 = icmp slt i32 %6, %3
  %9 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %9 = and i1 %7, %8
  call void @cqrt_and_i1(i32 %7, i32 %8, i32 %9)    ; IR: %9 = and i1 %7, %8
  call void @cqrt_rz_i1(i32 %9, double %4), !cq.branchphase !6    ; IR: block %10 under br i1 %9: cq_phi(%4)
  call void @cqrt_and_i1(i32 %7, i32 %8, i32 %9)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %8, i32 %6, i32 %3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %7, i32 %6, i32 %2)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %10 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %12 = cq_measure_si32(%6)
  ret i32 %10    ; IR: ret i32 %12
}

; Function Attrs: nounwind ssp uwtable
define i32 @cond_or(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_icmp_slt_i32_hl(i32 %6, i32 %2)    ; IR: %7 = icmp slt i32 %6, %2
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 %3)    ; IR: %8 = icmp sgt i32 %6, %3
  %9 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %9 = or i1 %7, %8
  call void @cqrt_or_i1(i32 %7, i32 %8, i32 %9)    ; IR: %9 = or i1 %7, %8: the disjunction flag (t ^= a | b)
  call void @cqrt_rz_i1(i32 %9, double %4), !cq.branchphase !6    ; IR: block %10 under br i1 %9: cq_phi(%4)
  call void @cqrt_or_i1(i32 %7, i32 %8, i32 %9)    ; IR: uncompute %9 (self-inverse)
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %6, i32 %3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %7, i32 %6, i32 %2)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %10 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %12 = cq_measure_si32(%6)
  ret i32 %10    ; IR: ret i32 %12
}

define i32 @cond_mixed(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = icmp ne i32 %3, 0    ; IR: %7 = icmp ne i32 %3, 0  (classical, stays classical)
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 %2)    ; IR: %8 = icmp eq i32 %6, %2
  br i1 %7, label %9, label %10    ; IR: %9 = select i1 %7, i1 %8, i1 false: the classical half of the conjunction is a classical branch

9:
  call void @cqrt_rz_i1(i32 %8, double %4)    ; IR: block %10 under br i1 %9: cq_phi(%4), fired when %7 holds and controlled by %8
  br label %10

10:
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %6, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %11 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %12 = cq_measure_si32(%6)
  ret i32 %11    ; IR: ret i32 %12
}

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_rz_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1 zeroext)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_or_i1(i32, i32, i32)

declare void @cqrt_not_i1(i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

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
