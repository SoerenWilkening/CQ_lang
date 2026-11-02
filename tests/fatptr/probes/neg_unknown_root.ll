; cq-b244: an inttoptr over pointer-argument roots (their place in their objects unknown) at a quantum offset
; that may move below them: fatptr keeps the exact i64 difference (cq-5xm0); the QROM over an object of unknown
; extent is mem-qrom's stop (rule 20's length for a root with no static extent).
; Source: int argroot(unsigned x0, double th, int *a, int *b) { cq_theta(&x, th); p = (x & 1) ? a : b;
;   r = (int *)((unsigned long)p + ((x >> 1) & 7) * 4 - 16); return cq_measure(*r); }
; EXPECT-ERROR: mem-qrom: a fat-pointer QROM over a root whose extent is not static
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @argroot(i32 noundef %0, double noundef %1, ptr noundef %2, ptr noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = select i1 %7, ptr %3, ptr %2
  %9 = ptrtoint ptr %8 to i64
  %10 = shl i32 %5, 1
  %11 = and i32 %10, 28
  %12 = zext nneg i32 %11 to i64
  %13 = add nsw i64 %12, -16
  %14 = add i64 %13, %9
  %15 = inttoptr i64 %14 to ptr
  %16 = load i32, ptr %15, align 4, !tbaa !6
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #3
  ret i32 %17
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
