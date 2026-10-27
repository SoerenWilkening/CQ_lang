; HAND-WRITTEN. Rules: 24, 20, 4, 5, 2.
; Checked: y = tmp * 2 (measured, %6 -> %7).
; Clean: the sum rail %5 = x + c (the volatile tmp), uncomputed and freed before the measurement.
; Kept: x (%4, the rotated register) and the result rail %6 (measured); nothing else.
; Rotations: (Ry, x, th, 1).
; The non-escaping volatile slot is a plain value (rule 24: nothing outside the program can observe it), so the volatile
; store/load pair is the SSA value x + c, an _hl add template into a fresh rail. -O1 has already turned `tmp * 2` into
; `shl 1`, which is an _hl shl template into the result rail.
source_filename = "volatile_local.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @volatile_local(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)    ; IR: %6 = add nsw i32 %5, %2  (the volatile store/load pair is this value)
  %6 = call i32 @cq_template_shl_i32_hl(i32 %5, i32 1)    ; IR: %8 = shl nsw i32 %7, 1
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %5)    ; IR: release the %6 rail (|0>)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %7    ; IR: ret i32 %9
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
