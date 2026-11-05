; /* tests/spine probe (CR rule 20 Address arithmetic): a tainted index, a classical run-time index, a struct field in one
;  * getelementptr: the untainted part is one classical i64. */
; ModuleID = 'bus_gep_struct.c'
source_filename = "bus_gep_struct.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.S = type { i32, [3 x i32] }

@tab = local_unnamed_addr global [4 x %struct.S] [%struct.S { i32 1, [3 x i32] [i32 2, i32 3, i32 4] }, %struct.S { i32 5, [3 x i32] [i32 6, i32 7, i32 8] }, %struct.S { i32 9, [3 x i32] [i32 10, i32 11, i32 12] }, %struct.S { i32 13, [3 x i32] [i32 14, i32 15, i32 16] }], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @gep_struct(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %5 = and i32 %4, 3
  %6 = zext nneg i32 %5 to i64
  %7 = and i32 %2, 1
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [4 x %struct.S], ptr @tab, i64 0, i64 %6, i32 1, i64 %8
  %10 = load i32, ptr %9, align 4, !tbaa !6
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  ret i32 %11
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
; USERCHECK gep_struct
