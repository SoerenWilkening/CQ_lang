; HAND-WRITTEN. Rules: 18, 5.
; Checked: f(x, c) (measured, %5 -> %6).
; Clean: every chain rail: in each clone the callee's result rail and the clone's own arithmetic rail (%3, %4 in __cq_q_f_10
; and __cq_q_g_10; %3 in __cq_q_h_10), uncomputed by the callee's _unc twin and the template _unc, then freed.
; Kept: x (%4, the rotated register) and the outermost clone's result rail %5 (measured); nothing else.
; Rotations: (Ry, x, th, 1).
; f -> g -> h lifts to a clone chain (__cq_q_f_10, __cq_q_g_10, __cq_q_h_10; masks left to right, §1.4); each clone
; copies its result out and uncomputes its callee's result by the callee's _unc twin. The unlifted f, g, h have no
; classical caller left and are dropped; __cq_q_f_10 is called only by the entry and has no twin (§1.4).
source_filename = "call_chain.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @call_chain(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = tail call fastcc i32 @__cq_q_f_10(i32 noundef %4, i32 noundef %2)    ; IR: %5 = call @f(%4, %2), quantum clone of f
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

declare void @cqrt_copy_i32(i32, i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc i32 @__cq_q_f_10(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = tail call fastcc i32 @__cq_q_g_10(i32 noundef %0, i32 noundef %1)    ; IR: %3 = call @g(%0, %1), quantum clone of g
  %4 = call i32 @cq_template_sub_i32_hl(i32 %3, i32 %1)    ; IR: %4 = sub nsw i32 %3, %1
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %4  [result rail of the call]
  call void @cqrt_copy_i32(i32 %4, i32 %5)    ; IR: copy the result out
  call void @cq_template_sub_i32_hl_unc(i32 %4, i32 %3, i32 %1)    ; IR: uncompute %4
  call fastcc void @__cq_q_g_10_unc(i32 %3, i32 %0, i32 %1)    ; IR: uncompute %3 (adjoint of the call to g)
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  ret i32 %5    ; IR: ret i32 %4
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc i32 @__cq_q_g_10(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = tail call fastcc i32 @__cq_q_h_10(i32 noundef %0, i32 noundef %1)    ; IR: %3 = call @h(%0, %1), quantum clone of h
  %4 = call i32 @cq_template_mul_i32(i32 %3, i32 %0)    ; IR: %4 = mul nsw i32 %3, %0
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %4  [result rail of the call]
  call void @cqrt_copy_i32(i32 %4, i32 %5)    ; IR: copy the result out
  call void @cq_template_mul_i32_unc(i32 %4, i32 %3, i32 %0)    ; IR: uncompute %4
  call fastcc void @__cq_q_h_10_unc(i32 %3, i32 %0, i32 %1)    ; IR: uncompute %3 (adjoint of the call to h)
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  ret i32 %5    ; IR: ret i32 %4
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc i32 @__cq_q_h_10(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = call i32 @cq_template_add_i32_hl(i32 %0, i32 %1)    ; IR: %3 = add nsw i32 %1, %0
  %4 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %3  [result rail of the call]
  call void @cqrt_copy_i32(i32 %3, i32 %4)    ; IR: copy the result out
  call void @cq_template_add_i32_hl_unc(i32 %3, i32 %0, i32 %1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  ret i32 %4    ; IR: ret i32 %3
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc void @__cq_q_h_10_unc(i32 %0, i32 noundef %1, i32 noundef %2) unnamed_addr #1 {
  %4 = call i32 @cq_template_add_i32_hl(i32 %1, i32 %2)    ; IR: recompute %3
  call void @cqrt_copy_i32(i32 %4, i32 %0)    ; IR: xor the result out of %out
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %1, i32 %2)    ; IR: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  ret void
}

declare i32 @cq_template_mul_i32(i32, i32)

declare void @cq_template_mul_i32_unc(i32, i32, i32)

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc void @__cq_q_g_10_unc(i32 %0, i32 noundef %1, i32 noundef %2) unnamed_addr #1 {
  %4 = tail call fastcc i32 @__cq_q_h_10(i32 noundef %1, i32 noundef %2)    ; IR: recompute %3 (clone of h)
  %5 = call i32 @cq_template_mul_i32(i32 %4, i32 %1)    ; IR: recompute %4
  call void @cqrt_copy_i32(i32 %5, i32 %0)    ; IR: xor the result out of %out
  call void @cq_template_mul_i32_unc(i32 %5, i32 %4, i32 %1)    ; IR: uncompute %4
  call fastcc void @__cq_q_h_10_unc(i32 %4, i32 %1, i32 %2)    ; IR: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the %4 rail (|0>)
  ret void
}

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

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
