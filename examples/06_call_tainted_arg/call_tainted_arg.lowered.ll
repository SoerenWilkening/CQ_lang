; HAND-WRITTEN. Rules: 18, 4, 5, 2.
; Checked: y = f(x, c) = x * x + c (measured: the clone's copied-out result rail, %5 returned, %5 -> %6 in the caller).
; Clean: the clone-internal rails s = v * v (%3) and s + c (%4), uncomputed in LIFO order inside the clone and freed.
; Kept: x (%4 in the caller, the rotated user register, never freed).
; Rotations: (Ry, x, th, 1).
; f(v, c) with v quantum is cloned as __cq_q_f_10 (mask left to right over the clone's formals,
; §1.4). The clone computes out of place, copies its result into a fresh rail, uncomputes its body in LIFO order and
; returns the copy; the caller measures the copy, so no _unc twin is needed.
source_filename = "call_tainted_arg.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @call_tainted_arg(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = tail call fastcc i32 @__cq_q_f_10(i32 noundef %4, i32 noundef %2)    ; IR: %5 = call @f(%4, %2), quantum clone of f (arg 0 quantum); the unlifted @f has no caller left and is dropped (§1.4)
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
declare void @cqrt_copy_i32(i32, i32)

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

declare void @cqrt_free(i32)

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
