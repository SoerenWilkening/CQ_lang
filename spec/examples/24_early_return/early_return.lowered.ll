; HAND-WRITTEN. Rules: 18, 9, 5.
; Checked: clamp_scale(x, lo, hi, s) (measured, %7 -> %8).
; Clean: inside the clone __cq_q_clamp_scale_1000: the two early-return flags %5 = (v < lo), %6 = (v > hi), the product
; %7 = v * s and the two select rails %8, %9, all uncomputed LIFO and freed after the copy-out.
; Kept: x (%6, the rotated register) and the clone's result rail %7 (measured); nothing else.
; Rotations: (Ry, x, th, 1).
; Early returns are the selects -O1 already made of them: two select templates chained (the second early return
; innermost); the output is the last select, copied out by the clone __cq_q_clamp_scale_1000 (mask left to right, §1.4)
; into the fresh rail it returns, so no return needs special handling. The unlifted clamp_scale has no classical caller
; left and is dropped (§1.4).
source_filename = "early_return.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @early_return(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = tail call fastcc i32 @__cq_q_clamp_scale_1000(i32 noundef %6, i32 noundef %2, i32 noundef %3, i32 noundef %4)    ; IR: %7 = call @clamp_scale(%6, ...), quantum clone (arg 0 quantum)
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %8    ; IR: ret i32 %8
}

declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

declare i32 @cq_template_select_i32_lh(i32, i32, i32)

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc i32 @__cq_q_clamp_scale_1000(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) unnamed_addr #1 {
  %5 = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 %1)    ; IR: %5 = icmp slt i32 %0, %1  (first early return)
  %6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %0, i32 %2)    ; IR: %6 = icmp sgt i32 %0, %2  (second early return)
  %7 = call i32 @cq_template_mul_i32_hl(i32 %0, i32 %3)    ; IR: %7 = mul nsw i32 %3, %0
  %8 = call i32 @cq_template_select_i32_lh(i32 %6, i32 %2, i32 %7)    ; IR: %8 = select i1 %6, i32 %2, i32 %7
  %9 = call i32 @cq_template_select_i32_lh(i32 %5, i32 %1, i32 %8)    ; IR: %9 = select i1 %5, i32 %1, i32 %8
  %10 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %9  [result rail of the call]
  call void @cqrt_copy_i32(i32 %9, i32 %10)    ; IR: ret i32 %9  [copy the result out]
  call void @cq_template_select_i32_lh_unc(i32 %9, i32 %5, i32 %1, i32 %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %8, i32 %6, i32 %2, i32 %7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %7, i32 %0, i32 %3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %6, i32 %0, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %5, i32 %0, i32 %1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  ret i32 %10    ; IR: ret i32 %9
}

declare i32 @cqrt_alloc_i32(i32)



declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)


declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
