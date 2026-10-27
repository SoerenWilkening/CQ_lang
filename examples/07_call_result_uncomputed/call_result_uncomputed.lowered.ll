; HAND-WRITTEN. Rules: 18, 8, 12, 5, 2.
; Checked: x (measured, %6 -> %9).
; Clean: the clone's result rail f(x, c) (%7, zeroed by the __cq_q_f_10_unc twin) and the flag f(x, c) == k (%8,
; uncomputed by the compare's _unc), both freed; every clone-internal rail (%3, %4 of the clone and twin).
; Kept: x (%6, the rotated user register).
; Rotations: (Ry, x, th, 1); (P, flag, phi, f(x, c) == k).
; __cq_q_f_10 (mask left to right, §1.4) returns its copied-out result; the compare on it is the
; branch flag and the arm's cq_phi is rz_i1 on that flag. The flag is uncomputed after the phase, then the result rail
; by the clone's _unc twin (recompute, XOR the copy out, uncompute), and both are freed before x is measured.
source_filename = "call_result_uncomputed.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @call_result_uncomputed(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = tail call fastcc i32 @__cq_q_f_10(i32 noundef %6, i32 noundef %2)    ; IR: %7 = call @f(%6, %2), quantum clone of f (arg 0 quantum); the unlifted @f has no caller left and is dropped (§1.4)
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 %3)    ; IR: %8 = icmp eq i32 %7, %3
  call void @cqrt_rz_i1(i32 %8, double %4), !cq.branchphase !6    ; IR: block %9 under br i1 %8: cq_phi(%4)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %7, i32 %3)    ; IR: uncompute %8
  call fastcc void @__cq_q_f_10_unc(i32 %7, i32 %6, i32 %2)    ; IR: uncompute %7 (adjoint of the call)
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %9 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %11 = cq_measure_si32(%6)
  ret i32 %9    ; IR: ret i32 %11
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_not_i1(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc i32 @__cq_q_f_10(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)    ; IR: %3 = mul nsw i32 %0, %0
  %4 = call i32 @cq_template_add_i32_hl(i32 %3, i32 %1)    ; IR: %4 = add nsw i32 %3, %1
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %4  [result rail of the call]
  call void @cqrt_copy_i32(i32 %4, i32 %5)    ; IR: ret i32 %4  [copy the result out]
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %3, i32 %1)    ; IR: uncompute %4
  call void @cq_template_mul_i32_unc(i32 %3, i32 %0, i32 %0)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  ret i32 %5    ; IR: ret i32 %4
}

declare i32 @cq_template_mul_i32(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cq_template_mul_i32_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc void @__cq_q_f_10_unc(i32 %0, i32 noundef %1, i32 noundef %2) unnamed_addr #1 {
  %4 = call i32 @cq_template_mul_i32(i32 %1, i32 %1)    ; IR: recompute %3
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)    ; IR: recompute %4
  call void @cqrt_copy_i32(i32 %5, i32 %0)    ; IR: ret i32 %4  [xor the result out of %out]
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 %2)    ; IR: uncompute %4
  call void @cq_template_mul_i32_unc(i32 %4, i32 %1, i32 %1)    ; IR: uncompute %3
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
!6 = !{}
