; HAND-WRITTEN. Rules: 8, 12, 4, 5, 2.
; Checked: x (measured, %7 -> %11).
; Clean: the outer flag f1 = (x > k1) (%8), the inner compare f2 = (x < k2) (%9) and the conjunction flag f1 & f2 (%10),
; uncomputed in LIFO order (and_i1 is its own inverse) and freed.
; Kept: x (%7, the rotated user register).
; Rotations: (Ry, x, th, 1); (P, f1, p1, x > k1); (P, f1 & f2, p2, (x > k1) & (x < k2)).
; Two nested phase arms. The outer condition is a flag rail (rule 8) and its cq_phi(p1) is the kickback rz_i1 on it.
; The inner branch sits inside the outer arm, so its path predicate is the conjunction of the outer flag with the inner
; compare, cqrt_and_i1 into a fresh |0> rail, and cq_phi(p2) is the kickback on that conjunction. Each flag is uncomputed
; right after its last controlled gate: the conjunction, then the inner compare, then the outer flag.
source_filename = "nested_if_phase.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @nested_if_phase(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %2)    ; IR: %8 = icmp sgt i32 %7, %2  [path predicate of block %9]
  call void @cqrt_rz_i1(i32 %8, double %4), !cq.branchphase !6    ; IR: block %9 under br i1 %8: cq_phi(%4)
  %9 = call i32 @cq_template_icmp_slt_i32_hl(i32 %7, i32 %3)    ; IR: %10 = icmp slt i32 %7, %3
  %10 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %11 = %8 & %10
  call void @cqrt_and_i1(i32 %8, i32 %9, i32 %10)    ; IR: br i1 %10 inside block %9: predicate = %8 & %10
  call void @cqrt_rz_i1(i32 %10, double %5), !cq.branchphase !6    ; IR: block %11 under the nested br: cq_phi(%5)
  call void @cqrt_and_i1(i32 %8, i32 %9, i32 %10)    ; IR: uncompute the %11 predicate
  call void @cqrt_free(i32 %10)    ; IR: release the %11 predicate (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %9, i32 %7, i32 %3)    ; IR: uncompute %10
  call void @cqrt_free(i32 %9)    ; IR: release the %10 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %7, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %11 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %13 = cq_measure_si32(%7)
  ret i32 %11    ; IR: ret i32 %13
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1 zeroext)

declare void @cqrt_not_i1(i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

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
