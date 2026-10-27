; HAND-WRITTEN. Rules: 18, 4, 5.
; Checked: r1 + r2 + r3 (measured, %12 -> %13).
; Clean: the three clone result rails %8, %9, %10 (zeroed by their _unc twins, then freed), the partial sum %11, and every
; clone-internal rail (%3, %4 of each clone).
; Kept: x (%6) and y (%7), the rotated registers, and the final sum rail %12 (measured); nothing else.
; Rotations: (Ry, x, tx, 1); (Ry, y, ty, 1).
; One clone per taint mask, left to right over mix's formals (§1.4): _10 for mix(x, c), _01 for mix(c, y), _11 for
; mix(x, y); the classical mul in _01 stays classical. Each result rail is uncomputed by its clone's _unc twin after the
; sum consumed it. Order (rule 5, dependency order): the partial sum %11 goes first because it read %8 and %9; the three
; clone results depend only on the registers, not on each other, so their twins commute and run in any order.
source_filename = "callee_two_masks.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @callee_two_masks(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %2)    ; IR: %6 = cq_theta_si32(%0, %2)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %7 = cq_theta_si32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %7 = cq_theta_si32(%1, %3)  [Ry]
  %8 = tail call fastcc i32 @__cq_q_mix_10(i32 noundef %6, i32 noundef %4)    ; IR: %8 = call @mix(%6, %4), clone for mask (quantum, classical)
  %9 = tail call fastcc i32 @__cq_q_mix_01(i32 noundef %4, i32 noundef %7)    ; IR: %9 = call @mix(%4, %7), clone for mask (classical, quantum)
  %10 = tail call fastcc i32 @__cq_q_mix_11(i32 noundef %6, i32 noundef %7)    ; IR: %10 = call @mix(%6, %7), clone for mask (quantum, quantum)
  %11 = call i32 @cq_template_add_i32(i32 %9, i32 %8)    ; IR: %11 = add nsw i32 %9, %8
  %12 = call i32 @cq_template_add_i32(i32 %11, i32 %10)    ; IR: %12 = add nsw i32 %11, %10
  call void @cq_template_add_i32_unc(i32 %11, i32 %9, i32 %8)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call fastcc void @__cq_q_mix_01_unc(i32 %9, i32 %4, i32 %7)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call fastcc void @__cq_q_mix_10_unc(i32 %8, i32 %6, i32 %4)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call fastcc void @__cq_q_mix_11_unc(i32 %10, i32 %6, i32 %7)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  %13 = call i32 @cqrt_measure_i32(i32 %12)    ; IR: %13 = cq_measure_si32(%12)
  ret i32 %13    ; IR: ret i32 %13
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc i32 @__cq_q_mix_10(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = call i32 @cq_template_mul_i32_hl(i32 %0, i32 3)    ; IR: %3 = mul nsw i32 %0, 3
  %4 = call i32 @cq_template_add_i32_hl(i32 %3, i32 %1)    ; IR: %4 = add nsw i32 %3, %1
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %4  [result rail of the call]
  call void @cqrt_copy_i32(i32 %4, i32 %5)    ; IR: copy the result out
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %3, i32 %1)    ; IR: uncompute %4
  call void @cq_template_mul_i32_hl_unc(i32 %3, i32 %0, i32 3)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  ret i32 %5    ; IR: ret i32 %4
}

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc i32 @__cq_q_mix_01(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = mul nsw i32 %0, 3    ; IR: %3 = mul nsw i32 %0, 3  (classical: arg 0 is classical here)
  %4 = call i32 @cq_template_add_i32_hl(i32 %1, i32 %3)    ; IR: %4 = add nsw i32 %3, %1
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %4  [result rail of the call]
  call void @cqrt_copy_i32(i32 %4, i32 %5)    ; IR: copy the result out
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %1, i32 %3)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  ret i32 %5    ; IR: ret i32 %4
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc i32 @__cq_q_mix_11(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = call i32 @cq_template_mul_i32_hl(i32 %0, i32 3)    ; IR: %3 = mul nsw i32 %0, 3
  %4 = call i32 @cq_template_add_i32(i32 %3, i32 %1)    ; IR: %4 = add nsw i32 %3, %1
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %4  [result rail of the call]
  call void @cqrt_copy_i32(i32 %4, i32 %5)    ; IR: copy the result out
  call void @cq_template_add_i32_unc(i32 %4, i32 %3, i32 %1)    ; IR: uncompute %4
  call void @cq_template_mul_i32_hl_unc(i32 %3, i32 %0, i32 3)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  ret i32 %5    ; IR: ret i32 %4
}

declare i32 @cq_template_add_i32(i32, i32)

declare void @cq_template_add_i32_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc void @__cq_q_mix_10_unc(i32 %0, i32 noundef %1, i32 noundef %2) unnamed_addr #1 {
  %4 = call i32 @cq_template_mul_i32_hl(i32 %1, i32 3)    ; IR: recompute %3
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)    ; IR: recompute %4
  call void @cqrt_copy_i32(i32 %5, i32 %0)    ; IR: xor the result out of %out
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 %2)    ; IR: uncompute %4
  call void @cq_template_mul_i32_hl_unc(i32 %4, i32 %1, i32 3)    ; IR: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the %4 rail (|0>)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc void @__cq_q_mix_01_unc(i32 %0, i32 noundef %1, i32 noundef %2) unnamed_addr #1 {
  %4 = mul nsw i32 %1, 3    ; IR: %3 (classical)
  %5 = call i32 @cq_template_add_i32_hl(i32 %2, i32 %4)    ; IR: recompute %4
  call void @cqrt_copy_i32(i32 %5, i32 %0)    ; IR: xor the result out of %out
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %2, i32 %4)    ; IR: uncompute %4
  call void @cqrt_free(i32 %5)    ; IR: release the %4 rail (|0>)
  ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc void @__cq_q_mix_11_unc(i32 %0, i32 noundef %1, i32 noundef %2) unnamed_addr #1 {
  %4 = call i32 @cq_template_mul_i32_hl(i32 %1, i32 3)    ; IR: recompute %3
  %5 = call i32 @cq_template_add_i32(i32 %4, i32 %2)    ; IR: recompute %4
  call void @cqrt_copy_i32(i32 %5, i32 %0)    ; IR: xor the result out of %out
  call void @cq_template_add_i32_unc(i32 %5, i32 %4, i32 %2)    ; IR: uncompute %4
  call void @cq_template_mul_i32_hl_unc(i32 %4, i32 %1, i32 3)    ; IR: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the %4 rail (|0>)
  ret void
}

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
